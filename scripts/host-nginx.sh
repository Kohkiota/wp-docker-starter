#!/bin/bash
set -e

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# cronサービス名設定
# Amazon Linux 2023:
# CRON_SERVICE="crond"

# Ubuntu/Debian版:
CRON_SERVICE="cron"

# ================================================
# Basic認証管理関数
# ================================================

# Basic認証の現在の状態を確認
check_basic_auth_status() {
    # Amazon Linux 2023: /etc/nginx/conf.d/
    # [ -f /etc/nginx/.htpasswd ] && grep -q "auth_basic" "/etc/nginx/conf.d/${DOMAIN}.conf" 2>/dev/null
    
    # Ubuntu/Debian版: /etc/nginx/sites-available/
    [ -f /etc/nginx/.htpasswd ] && grep -q "auth_basic" "/etc/nginx/sites-available/${DOMAIN}" 2>/dev/null
}

# Basic認証を有効化
enable_basic_auth() {
    local USERNAME=$1
    local PASSWORD=$2
    
    echo ""
    echo "=========================================="
    echo "Basic認証を設定しています..."
    echo "=========================================="
    
    # httpd-tools/apache2-utilsインストール確認（htpasswdコマンド用）
    if ! command -v htpasswd &> /dev/null; then
        echo -e "${YELLOW}⚠ htpasswd not found. Installing...${NC}"
        
        # Amazon Linux 2023: yum
        # yum install -y httpd-tools
        
        # Ubuntu/Debian版:
        apt-get install -y apache2-utils
        
        echo -e "${GREEN}✓ htpasswd installed${NC}"
    fi
    
    # htpasswdファイル作成
    htpasswd -cb /etc/nginx/.htpasswd "$USERNAME" "$PASSWORD"
    echo -e "${GREEN}✓ Password file created${NC}"
    
    # Nginx設定ファイルのパスを設定
    # Amazon Linux 2023: /etc/nginx/conf.d/
    # CONF_FILE="/etc/nginx/conf.d/${DOMAIN}.conf"
    
    # Ubuntu/Debian版: /etc/nginx/sites-available/
    CONF_FILE="/etc/nginx/sites-available/${DOMAIN}"
    
    if [ ! -f "$CONF_FILE" ]; then
        echo -e "${RED}✗ Nginx configuration file not found: $CONF_FILE${NC}"
        return 1
    fi
    
    # すでに auth_basic が存在する場合は削除
    sed -i '/auth_basic/d' "$CONF_FILE"
    sed -i '/auth_basic_user_file/d' "$CONF_FILE"
    
    # HTTP側の location / ブロックに auth_basic を挿入
    sed -i '/^[[:space:]]*location \/ {$/a\        auth_basic "Restricted Access";\n        auth_basic_user_file /etc/nginx/.htpasswd;' "$CONF_FILE"
    
    echo -e "${GREEN}✓ Basic auth configured${NC}"
    
    # Nginx設定テスト＆リロード
    echo ""
    echo "Nginx設定テスト..."
    if nginx -t 2>&1; then
        systemctl reload nginx
        echo -e "${GREEN}✓ Nginx reloaded with Basic auth${NC}"
    else
        echo -e "${RED}✗ Nginx configuration test failed${NC}"
        return 1
    fi
    
    echo ""
    echo "=========================================="
    echo "Basic認証が有効になりました"
    echo "=========================================="
    echo "ユーザー名: ${USERNAME}"
    echo "パスワード: ${PASSWORD}"
    echo ""
    echo "サイトアクセス時に認証が求められます"
    echo "=========================================="
}

# Basic認証を無効化
disable_basic_auth() {
    echo ""
    echo "=========================================="
    echo "Basic認証を解除しています..."
    echo "=========================================="
    
    # Nginx設定ファイルのパスを設定
    # Amazon Linux 2023: /etc/nginx/conf.d/
    # CONF_FILE="/etc/nginx/conf.d/${DOMAIN}.conf"
    
    # Ubuntu/Debian版: /etc/nginx/sites-available/
    CONF_FILE="/etc/nginx/sites-available/${DOMAIN}"
    
    if [ ! -f "$CONF_FILE" ]; then
        echo -e "${RED}✗ Nginx configuration file not found: $CONF_FILE${NC}"
        return 1
    fi
    
    # auth_basic関連の行を削除
    sed -i '/auth_basic/d' "$CONF_FILE"
    sed -i '/auth_basic_user_file/d' "$CONF_FILE"
    
    # htpasswdファイル削除
    rm -f /etc/nginx/.htpasswd
    
    echo -e "${GREEN}✓ Basic auth configuration removed${NC}"
    
    # Nginx設定テスト＆リロード
    echo ""
    echo "Nginx設定テスト..."
    if nginx -t 2>&1; then
        systemctl reload nginx
        echo -e "${GREEN}✓ Nginx reloaded${NC}"
    else
        echo -e "${RED}✗ Nginx configuration test failed${NC}"
        return 1
    fi
    
    echo ""
    echo "=========================================="
    echo "Basic認証が解除されました"
    echo "=========================================="
}

# ================================================
# 引数なし = Basic認証管理モード
# ================================================
if [ -z "$1" ]; then
    echo "=========================================="
    echo "Basic認証管理モード"
    echo "=========================================="
    
    # root権限チェック
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}✗ このスクリプトはroot権限で実行してください${NC}"
        echo "使用方法: sudo bash host-nginx.sh"
        exit 1
    fi
    
    # ドメイン自動検出
    echo ""
    echo "設定済みドメインを検索中..."
    
    # Amazon Linux 2023: /etc/nginx/conf.d/
    # CONF_FILES=($(ls /etc/nginx/conf.d/*.conf 2>/dev/null | grep -v "\.disabled$" || true))
    
    # Ubuntu/Debian版: /etc/nginx/sites-available/
    CONF_FILES=($(ls /etc/nginx/sites-available/* 2>/dev/null | grep -v "default" || true))
    
    if [ ${#CONF_FILES[@]} -eq 0 ]; then
        echo -e "${RED}✗ Nginx設定ファイルが見つかりません${NC}"
        echo "先に通常のセットアップを実行してください: sudo bash host-nginx.sh example.com"
        exit 1
    fi
    
    # 1つだけの場合は自動選択
    if [ ${#CONF_FILES[@]} -eq 1 ]; then
        SELECTED_CONF="${CONF_FILES[0]}"
        DOMAIN=$(basename "$SELECTED_CONF" .conf)
        echo -e "${GREEN}✓ ドメイン検出: ${DOMAIN}${NC}"
    else
        # 複数ある場合は選択
        echo ""
        echo "複数のドメインが見つかりました:"
        for i in "${!CONF_FILES[@]}"; do
            DOMAIN_NAME=$(basename "${CONF_FILES[$i]}" .conf)
            echo "  $((i+1))) ${DOMAIN_NAME}"
        done
        echo ""
        read -p "選択してください (1-${#CONF_FILES[@]}): " DOMAIN_CHOICE
        
        if ! [[ "$DOMAIN_CHOICE" =~ ^[0-9]+$ ]] || [ "$DOMAIN_CHOICE" -lt 1 ] || [ "$DOMAIN_CHOICE" -gt ${#CONF_FILES[@]} ]; then
            echo -e "${RED}✗ 無効な選択です${NC}"
            exit 1
        fi
        
        SELECTED_CONF="${CONF_FILES[$((DOMAIN_CHOICE-1))]}"
        DOMAIN=$(basename "$SELECTED_CONF" .conf)
    fi
    
    echo ""
    
    # 現在の状態確認
    echo ""
    echo "現在のBasic認証状態:"
    if check_basic_auth_status; then
        echo -e "${GREEN}✓ ON（有効）${NC}"
        if [ -f /etc/nginx/.htpasswd ]; then
            echo "登録ユーザー:"
            cut -d: -f1 /etc/nginx/.htpasswd | sed 's/^/  - /'
        fi
    else
        echo -e "${YELLOW}✗ OFF（無効）${NC}"
    fi
    
    echo ""
    echo "=========================================="
    echo "Basic認証の設定"
    echo "=========================================="
    echo "1) ON  - Basic認証を有効にする"
    echo "2) OFF - Basic認証を無効にする"
    echo "3) Exit"
    echo ""
    read -p "選択してください (1/2/3): " CHOICE
    
    case $CHOICE in
        1)
            echo ""
            read -p "ユーザー名を入力: " USERNAME
            read -sp "パスワードを入力: " PASSWORD
            echo ""
            
            if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
                echo -e "${RED}✗ ユーザー名とパスワードは必須です${NC}"
                exit 1
            fi
            
            enable_basic_auth "$USERNAME" "$PASSWORD"
            ;;
        2)
            disable_basic_auth
            ;;
        3)
            echo "終了します"
            exit 0
            ;;
        *)
            echo -e "${RED}✗ 無効な選択です${NC}"
            exit 1
            ;;
    esac
    
    exit 0
fi

# ================================================
# 通常実行モード（ドメイン引数あり）
# ================================================

# root権限チェック
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ このスクリプトはroot権限で実行してください${NC}"
    echo "使用方法: sudo bash host-nginx.sh example.com"
    exit 1
fi

# ドメイン引数取得
DOMAIN=$1
EMAIL="admin@${DOMAIN}"

echo "=========================================="
echo "ホスト側Nginx + TLS設定スクリプト"
echo "Ubuntu / Amazon Linux 2023 対応版"
echo "=========================================="
echo "ドメイン: $DOMAIN"
echo "メール: $EMAIL"
echo ""

# ================================================
# 1. Nginxインストール確認
# ================================================
echo "[1/6] Checking Nginx installation..."

if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}⚠ Nginx not found. Installing...${NC}"

    # Amazon Linux 2023: yum/dnfを使用
    # yum update -y
    # yum install -y nginx

    # Ubuntu/Debian版:
    apt-get update
    apt-get install -y nginx

    echo -e "${GREEN}✓ Nginx installed${NC}"
else
    echo -e "${GREEN}✓ Nginx already installed${NC}"
fi

# ================================================
# 2. Certbot（Let's Encrypt）インストール確認
# ================================================
echo "[2/6] Checking Certbot installation..."

if ! command -v certbot &> /dev/null; then
    echo -e "${YELLOW}⚠ Certbot not found. Installing...${NC}"

    # Amazon Linux 2023: certbotをインストール
    # yum update -y
    # yum install -y certbot

    # Ubuntu/Debian版:
    apt-get update
    apt-get install -y certbot

    echo -e "${GREEN}✓ Certbot installed${NC}"
else
    echo -e "${GREEN}✓ Certbot already installed${NC}"
fi

# ================================================
# 3. Nginx設定ファイル作成
# ================================================
echo "[3/6] Creating Nginx configuration..."

# Amazon Linux 2023: /etc/nginx/conf.d/ を使用
# NGINX_CONF="/etc/nginx/conf.d/${DOMAIN}.conf"

# Ubuntu/Debian版では以下を使用:
NGINX_CONF="/etc/nginx/sites-available/${DOMAIN}"
NGINX_ENABLED="/etc/nginx/sites-enabled/${DOMAIN}"

cat > "$NGINX_CONF" << 'EOF'
# WordPress Docker リバースプロキシ設定
# ドメイン: DOMAIN_PLACEHOLDER

server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER www.DOMAIN_PLACEHOLDER;

    # Let's Encrypt (HTTP-01)
    location ^~ /.well-known/acme-challenge/ {
        root /var/www/html;
        default_type "text/plain";
        try_files $uri =404;
        access_log off;
    }


    # HTTP -> HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS_START
# server {
#     listen 443 ssl http2;
#     listen [::]:443 ssl http2;
#     server_name DOMAIN_PLACEHOLDER www.DOMAIN_PLACEHOLDER;
# 
#     ssl_certificate     /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/DOMAIN_PLACEHOLDER/privkey.pem;
# 
#     include /etc/letsencrypt/options-ssl-nginx.conf;
#     ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
# 
#     location / {
#         proxy_pass http://127.0.0.1:8080;
#         proxy_set_header Host $host;
#
#         # # ★ Cloudflare使用時はこちら ★
#         # # [CLOUDFLARE]
#         proxy_set_header X-Real-IP $http_cf_connecting_ip;
#         proxy_set_header X-Forwarded-For $http_cf_connecting_ip;
#         # # [CLOUDFLARE]
#
#         # # ★ Cloudflare未使用時はこちら ★
#         # # [NO-CLOUDFLARE]
#         # proxy_set_header X-Real-IP $remote_addr;
#         # proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
#         # # [NO-CLOUDFLARE]
#
#         proxy_set_header X-Forwarded-Proto https;
#         proxy_set_header X-Forwarded-Host $host;
#         proxy_set_header X-Forwarded-Port $server_port;
#         proxy_read_timeout 300s;
#         proxy_connect_timeout 300s;
#         client_max_body_size 300M;
#     }
# }
# HTTPS_END
EOF

# ドメイン名を置換
sed -i "s/DOMAIN_PLACEHOLDER/${DOMAIN}/g" "$NGINX_CONF"

echo -e "${GREEN}✓ Nginx configuration created: $NGINX_CONF${NC}"

# Amazon Linux 2023版: シンボリックリンク不要（コメントアウト）

# Ubuntu/Debian版: シンボリックリンク作成が必要
if [ ! -L "$NGINX_ENABLED" ]; then
    ln -s "$NGINX_CONF" "$NGINX_ENABLED"
    echo -e "${GREEN}✓ Nginx configuration enabled${NC}"
fi

# Amazon Linux 2023: デフォルト設定を無効化（default.confをリネーム）
# if [ -f /etc/nginx/conf.d/default.conf ]; then
#     mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.disabled
#     echo -e "${GREEN}✓ Default configuration disabled${NC}"
# fi

# Ubuntu/Debian版: sites-enabled/defaultを削除
if [ -L /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
    echo -e "${GREEN}✓ Default configuration disabled${NC}"
fi

# Nginx設定テスト
echo ""
echo "=========================================="
echo "Nginx設定テスト"
echo "=========================================="
if nginx -t; then
    echo -e "${GREEN}✓ Nginx configuration test passed${NC}"
else
    echo -e "${RED}✗ Nginx configuration test failed${NC}"
    exit 1
fi
echo "=========================================="

# Nginx起動状態を確認して適切に処理
if systemctl is-active --quiet nginx; then
    # 起動中の場合はreload
    systemctl reload nginx
    echo -e "${GREEN}✓ Nginx reloaded${NC}"
else
    # 起動していない場合はstart
    systemctl start nginx
    systemctl enable nginx
    echo -e "${GREEN}✓ Nginx started and enabled${NC}"
fi

# ================================================
# 4. Let's Encrypt証明書取得
# ================================================
echo "[4/6] Obtaining Let's Encrypt certificate..."

CERT_PATH="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
CERT_ACQUIRED=false

# 証明書が既に存在するかチェック
if [ -f "$CERT_PATH" ]; then
    echo -e "${GREEN}✓ Certificate already exists: $CERT_PATH${NC}"
    
    # 証明書の情報を表示（テスト証明書かどうか確認用）
    echo ""
    echo "証明書の発行者:"
    openssl x509 -in "$CERT_PATH" -noout -issuer 2>/dev/null | sed 's/issuer=/  /'
    echo ""
    
    read -p "既存の証明書を使用しますか？ (Y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "新しい証明書を取得します..."
        SKIP_CERT=false
    else
        echo "既存の証明書を使用します..."
        SKIP_CERT=true
        CERT_ACQUIRED=true
    fi
else
    SKIP_CERT=false
fi

if [ "$SKIP_CERT" = false ]; then
    echo -e "${YELLOW}⚠ 証明書取得前の確認:${NC}"
    echo "  - ドメイン ${DOMAIN} がこのサーバーに向いていますか？"
    echo "  - ポート80, 443が開放されていますか？"
    echo "  - Docker環境が起動していますか？ (localhost:8080)"
    echo ""
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}⚠ スキップしました。後で手動実行してください:${NC}"
        echo "  sudo certbot certonly --webroot -w /var/www/html -d ${DOMAIN} -d www.${DOMAIN} --email ${EMAIL} --agree-tos --no-eff-email"
        exit 0
    fi

    # 証明書タイプ選択
    echo ""
    echo "=========================================="
    echo "証明書タイプの選択"
    echo "=========================================="
    echo "1) テスト証明書（Staging）"
    echo "   → 動作確認用、無制限に取得可能"
    echo "   → ブラウザで警告が出る"
    echo ""
    echo "2) 本番証明書（Production）"
    echo "   → 本番用、週5回まで"
    echo "   → ブラウザで警告なし"
    echo ""
    read -p "選択してください (1/2): " CERT_TYPE
    
    case $CERT_TYPE in
        1)
            USE_STAGING="--staging"
            echo -e "${YELLOW}⚠ テスト証明書を取得します${NC}"
            ;;
        2)
            USE_STAGING=""
            echo -e "${GREEN}✓ 本番証明書を取得します${NC}"
            ;;
        *)
            USE_STAGING="--staging"
            echo -e "${YELLOW}⚠ デフォルト: テスト証明書を取得します${NC}"
            ;;
    esac

    # Certbot実行
    CERTBOT_OPTS="$USE_STAGING"
    if [ -f "$CERT_PATH" ]; then
        # 既存証明書がある場合は強制更新も追加
        CERTBOT_OPTS="$USE_STAGING --force-renewal"
    fi

    certbot certonly --webroot \
        -w /var/www/html \
        -d "${DOMAIN}" \
        -d "www.${DOMAIN}" \
        --email "${EMAIL}" \
        --agree-tos \
        --no-eff-email \
        $CERTBOT_OPTS

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ TLS certificate obtained successfully!${NC}"
        CERT_ACQUIRED=true
    else
        echo -e "${RED}✗ Failed to obtain TLS certificate${NC}"
        echo "手動実行してください: sudo certbot certonly --webroot -w /var/www/html -d ${DOMAIN} -d www.${DOMAIN}"
        exit 1
    fi
fi

# 証明書がある場合（新規取得・既存どちらでも）HTTPS設定を有効化
if [ "$CERT_ACQUIRED" = true ]; then
    echo ""
    echo "Downloading SSL configuration files..."
    
    # SSL設定ファイルがなければダウンロード
    if [ ! -f /etc/letsencrypt/options-ssl-nginx.conf ]; then
        curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf \
          -o /etc/letsencrypt/options-ssl-nginx.conf
    fi
    
    if [ ! -f /etc/letsencrypt/ssl-dhparams.pem ]; then
        curl -s https://ssl-config.mozilla.org/ffdhe2048.txt \
          -o /etc/letsencrypt/ssl-dhparams.pem
    fi
    
    echo -e "${GREEN}✓ SSL configuration files ready${NC}"
    echo ""
    echo "Enabling HTTPS configuration..."
    
    # マーカーが存在する場合のみsed処理を実行
    if grep -q "HTTPS_START" "$NGINX_CONF"; then
        sed -i '/# HTTPS_START/,/# HTTPS_END/ s/^# //' "$NGINX_CONF"
        sed -i '/HTTPS_START/d; /HTTPS_END/d' "$NGINX_CONF"
        echo -e "${GREEN}✓ HTTPS block uncommented${NC}"
    else
        echo -e "${YELLOW}⚠ HTTPS block already enabled or not found${NC}"
    fi
    
    if nginx -t 2>&1; then
        systemctl reload nginx
        echo -e "${GREEN}✓ Nginx reloaded with HTTPS${NC}"
    else
        echo -e "${RED}✗ Nginx test failed${NC}"
        exit 1
    fi
fi

# ================================================
# 5. 自動更新設定
# ================================================
echo "[5/6] Setting up automatic certificate renewal..."

# cronie（cron本体）のインストール確認
if ! command -v crontab &> /dev/null; then
    echo -e "${YELLOW}⚠ cron not found. Installing...${NC}"

    # Amazon Linux 2023: cronie
    # yum install -y cronie

    # Ubuntu/Debian版: cron
    apt-get update
    apt-get install -y cron

    echo -e "${GREEN}✓ cron installed${NC}"
else
    echo -e "${GREEN}✓ cron already installed${NC}"
fi

# cronサービスの起動確認
# Amazon Linux 2023: crond
# if ! systemctl is-active --quiet $CRON_SERVICE; then
#     echo -e "${YELLOW}⚠ $CRON_SERVICE service is not running. Starting...${NC}"
#     systemctl start $CRON_SERVICE
#     systemctl enable $CRON_SERVICE
#     echo -e "${GREEN}✓ $CRON_SERVICE service started and enabled${NC}"
# else
#     echo -e "${GREEN}✓ $CRON_SERVICE service is already running${NC}"
# fi

# Ubuntu/Debian版: cron
if ! systemctl is-active --quiet $CRON_SERVICE; then
    echo -e "${YELLOW}⚠ $CRON_SERVICE service is not running. Starting...${NC}"
    systemctl start $CRON_SERVICE
    systemctl enable $CRON_SERVICE
    echo -e "${GREEN}✓ $CRON_SERVICE service started and enabled${NC}"
else
    echo -e "${GREEN}✓ $CRON_SERVICE service is already running${NC}"
fi

# /etc/cron.d/ ディレクトリが存在しない場合は作成
if [ ! -d /etc/cron.d ]; then
    echo -e "${YELLOW}⚠ /etc/cron.d/ directory not found. Creating...${NC}"
    mkdir -p /etc/cron.d
    chmod 755 /etc/cron.d
    echo -e "${GREEN}✓ /etc/cron.d/ directory created${NC}"
fi

# certbot自動更新のcron設定
if [ -f /etc/cron.d/certbot ]; then
    echo -e "${GREEN}✓ Certbot renewal cron already exists${NC}"
else
    echo -e "${YELLOW}⚠ Setting up certbot renewal cron...${NC}"

    # 毎日0時と12時にcertbot renewを実行
    cat > /etc/cron.d/certbot << 'CRONEOF'
# Certbot automatic renewal
# Runs twice daily to check and renew certificates
0 0,12 * * * root /usr/bin/certbot renew --quiet
CRONEOF

    chmod 644 /etc/cron.d/certbot
    echo -e "${GREEN}✓ Certbot renewal cron created${NC}"

    # cronサービスをリロード
    # Amazon Linux 2023: crond
    # systemctl reload $CRON_SERVICE 2>/dev/null || systemctl restart $CRON_SERVICE
    
    # Ubuntu/Debian版: cron
    systemctl reload $CRON_SERVICE 2>/dev/null || systemctl restart $CRON_SERVICE
    
    echo -e "${GREEN}✓ $CRON_SERVICE service reloaded${NC}"
fi

# cron設定の確認
echo ""
echo "=========================================="
echo "Certbot自動更新設定"
echo "=========================================="

if [ -f /etc/cron.d/certbot ]; then
    cat /etc/cron.d/certbot
    echo ""
    echo "✓ certbot自動更新が設定されました"
else
    echo "✗ cron設定ファイルが見つかりません"
fi

echo ""
if systemctl is-active --quiet $CRON_SERVICE; then
    echo "✓ ${CRON_SERVICE}サービス: 起動中"
else
    echo "✗ ${CRON_SERVICE}サービス: 停止中"
fi

echo "=========================================="

# ================================================
# 6. Basic認証設定（オプション）
# ================================================
echo ""
echo "[6/6] Basic認証の設定（オプション）"
echo ""
echo "=========================================="
echo "Basic認証の設定"
echo "=========================================="
echo "サイト全体にBasic認証をかけますか？"
echo "（開発中やクライアント確認時に便利です）"
echo ""
read -p "Basic認証を有効にしますか？ (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "ユーザー名を入力: " BASIC_USERNAME
    read -sp "パスワードを入力: " BASIC_PASSWORD
    echo ""
    
    if [ -z "$BASIC_USERNAME" ] || [ -z "$BASIC_PASSWORD" ]; then
        echo -e "${YELLOW}⚠ ユーザー名またはパスワードが空のためスキップしました${NC}"
    else
        enable_basic_auth "$BASIC_USERNAME" "$BASIC_PASSWORD"
    fi
else
    echo -e "${YELLOW}Basic認証はスキップされました${NC}"
    echo ""
    echo "後で設定する場合:"
    echo "  sudo bash host-nginx.sh"
fi

# ================================================
# 完了
# ================================================
echo ""
echo "=========================================="
echo "✓ セットアップ完了！"
echo "=========================================="
echo ""
echo "【構成】"
echo "  インターネット (HTTPS:443)"
echo "    ↓"
echo "  ホストNginx (Let's Encrypt TLS)"
echo "    ↓ HTTP → HTTPS リダイレクト"
echo "    ↓ proxy_pass http://localhost:8080"
echo "  DockerコンテナNginx (ポート8080)"
echo "    ↓"
echo "  WordPress + MySQL"
echo ""
echo "【アクセスURL】"
echo "  サイト: https://${DOMAIN}"
echo "  管理画面: https://${DOMAIN}/wp-admin"
echo ""
echo "【証明書】"
echo "  場所: /etc/letsencrypt/live/${DOMAIN}/"
echo "  自動更新: 毎日0時と12時に実行"
echo ""

# Basic認証の状態を表示
if check_basic_auth_status; then
    echo "【Basic認証】"
    echo "  状態: 有効"
    echo "  管理: sudo bash host-nginx.sh"
    echo ""
fi

echo "【便利なコマンド】"
echo "  Nginx設定確認: sudo nginx -t"
echo "  Nginx再起動: sudo systemctl reload nginx"
echo "  証明書更新テスト: sudo certbot renew --dry-run"
echo "  cronサービス確認: systemctl status $CRON_SERVICE"
echo "  Basic認証管理: sudo bash host-nginx.sh"
echo "=========================================="