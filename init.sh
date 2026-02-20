#!/bin/bash
set -e

# ================================================
# WordPress Docker環境 統合セットアップスクリプト
# ================================================
#
# 【使用方法】
#   sudo bash init.sh example.com
#
# 【処理内容】
#   このスクリプトは以下の3つの処理を順に実行します：
#
#   1. Nginx + Let's Encrypt設定 (host-nginx.sh)
#      - Nginxインストール（Amazon Linux 2023 / Ubuntu / Debian対応）
#      - Certbot（Let's Encrypt）インストール
#      - リバースプロキシ設定（localhost:8080へ転送）
#      - TLS証明書自動取得
#      - 証明書自動更新設定（crond / systemd timer）
#      ※ AL2023以外: yum → apt-get に読み替え
#
#   2. Google Drive認証 (setup-gdrive.sh)
#      - rcloneインストール（サーバー側）
#      - expectで全自動入力（n, gdrive, drive, 1, n, n...）
#      - URLを表示 → ユーザーがクリック
#      - ブラウザで認証 → コードをコピー
#      - ユーザーがコードを貼り付け
#      - .envファイルに設定保存
#      ※ユーザーの操作: URLクリック + コード貼り付けのみ
#
#   3. バックアップ自動化設定 (backup.sh --setup)
#      - 対話形式でバックアップ間隔を設定（1/3/7/14/30日おき）
#      - crontab自動登録
#      - 即座にバックアップ実行（オプション）
#
# 【バックアップ仕様】
#   ローカル保存: backups/
#     - db-YYYYMMDD_HHMMSS.sql.gz (mysqldump)
#     - data-YYYYMMDD_HHMMSS.tar.gz (wp-content)
#     - env-YYYYMMDD_HHMMSS.txt (.env)
#   Google Drive保存: 同時アップロード（rclone）
#   保持期間: 30日（自動削除）
#   無停止バックアップ: --single-transaction で稼働中も安全
#
# 【前提条件】
#   - Docker環境が起動済み（localhost:8080でアクセス可能）
#   - ドメインのDNSがこのサーバーに向いている
#   - ポート80, 443が開放されている
#   - root権限で実行
#
# 【本番環境構成】
#   インターネット (HTTPS:443)
#     ↓
#   ホストNginx (Let's Encrypt TLS)
#     ↓ HTTP → HTTPS リダイレクト
#     ↓ proxy_pass http://localhost:8080
#   DockerコンテナNginx (ポート8080)
#     ↓
#   WordPress + MySQL
#
# 【確認コマンド】
#   Nginx設定: sudo nginx -t
#   TLS証明書: sudo certbot certificates
#   証明書更新テスト: sudo certbot renew --dry-run
#   cron設定: crontab -l
#   cronサービス: systemctl status cron       # Ubuntu
#   crondサービス: systemctl status crond     # AL2023
#   バックアップ実行: bash scripts/backup.sh
#   バックアップログ: tail -f backups/backup.log
#   Google Drive確認: rclone ls gdrive:backups/
#
# 【トラブルシューティング】
#   Nginxログ: tail -f /var/log/nginx/error.log
#   Dockerログ: docker compose logs -f
#   MySQL接続: docker compose exec mysql mysqladmin ping
#   証明書エラー: sudo certbot certificates
#   cron未実行: systemctl status cron         # Ubuntu
#   crond未実行: systemctl status crond       # AL2023
#   Google Drive接続: rclone lsd gdrive:
#   Google Drive再認証: bash scripts/setup-gdrive.sh
#
# 【個別実行】
#   各スクリプトは個別実行も可能：
#
#   1. host-nginx.sh (Nginx + TLS設定)
#      sudo bash scripts/host-nginx.sh example.com  # TLS + Basic認証設定
#      sudo bash scripts/host-nginx.sh              # Basic認証管理のみ
#
#   2. setup-gdrive.sh (Google Drive認証)
#      sudo bash scripts/setup-gdrive.sh 実行
#      → 全自動で設定が進む
#      → URLが表示される → クリック
#      → Googleアカウントで認証
#      → 表示されるコードをコピー → 貼り付け
#      → 完了
#      ※すべて自動入力、ユーザーはURLクリックとコード貼り付けだけ
#
#   3. backup.sh (バックアップ)
#      sudo bash scripts/backup.sh --setup  # 定期実行含む設定（対話的設定）
#      sudo bash scripts/backup.sh          # バックアップのみ実行（cron用）
# 
#   4. restore.sh (バックアップ復元)
#      sudo bash scripts/restore.sh
#      → バックアップ一覧から選択
#      → 復元モード選択（完全復元 / 部分復元）
#      → 確認後、Docker停止 → data削除 → 復元 → 起動 → SQLインポート
#      ※完全復元: .env + data + MySQL / 部分復元: .env + data のみ
#
# 【定期実行の解除】
#   crontab -e  # エディタで該当行を削除
#   または
#   crontab -l | grep -v "backup.sh" | crontab -
#
# ================================================

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# root権限チェック
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ このスクリプトはroot権限で実行してください${NC}"
    echo "使用方法: sudo bash init.sh example.com"
    exit 1
fi
OWNER="$SUDO_USER" 

# ドメイン引数チェック
if [ -z "$1" ]; then
    echo -e "${RED}✗ ドメイン名を指定してください${NC}"
    echo "使用方法: sudo bash init.sh example.com"
    exit 1
fi

DOMAIN=$1

echo "=========================================="
echo "WordPress Docker環境 統合セットアップ"
echo "=========================================="
echo "ドメイン: $DOMAIN"
echo ""
echo "このスクリプトは以下を順に実行します:"
echo "  1. Nginx + Let's Encrypt設定"
echo "  2. Google Drive認証"
echo "  3. バックアップ自動化設定"
echo ""
read -p "続行しますか？ (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "キャンセルしました"
    exit 0
fi

echo ""

# ================================================
# 0. スクリプトファイルに実行権限を付与
# ================================================
echo "[0/3] スクリプトファイルに実行権限を付与..."

chmod +x scripts/host-nginx.sh
chmod +x scripts/setup-gdrive.sh
chmod +x scripts/backup.sh
chmod +x scripts/restore.sh

echo -e "${GREEN}✓ 実行権限付与完了${NC}"
echo ""

# ================================================
# 1. Nginx + Let's Encrypt設定
# ================================================
echo "=========================================="
echo "[1/3] Nginx + Let's Encrypt設定"
echo "=========================================="
echo ""

if [ -f "$SCRIPT_DIR/scripts/host-nginx.sh" ]; then
    bash "$SCRIPT_DIR/scripts/host-nginx.sh" "$DOMAIN"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Nginx + Let's Encrypt設定完了${NC}"
    else
        echo ""
        echo -e "${RED}✗ Nginx + Let's Encrypt設定に失敗しました${NC}"
        echo "手動で実行してください: sudo bash scripts/host-nginx.sh $DOMAIN"
        exit 1
    fi
else
    echo -e "${RED}✗ scripts/host-nginx.sh が見つかりません${NC}"
    exit 1
fi

echo ""
sleep 2

# ================================================
# 2. Google Drive認証
# ================================================
echo "=========================================="
echo "[2/3] Google Drive認証"
echo "=========================================="
echo ""

# 実行ユーザーを取得（sudoの場合は元のユーザー）
if [ -n "$SUDO_USER" ]; then
    REAL_USER=$SUDO_USER
else
    REAL_USER=$(whoami)
fi

if [ -f "$SCRIPT_DIR/scripts/setup-gdrive.sh" ]; then
    bash "$SCRIPT_DIR/scripts/setup-gdrive.sh"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Google Drive認証完了${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠ Google Drive認証に失敗またはスキップしました${NC}"
        echo "後で手動実行できます: bash scripts/setup-gdrive.sh"
    fi
else
    echo -e "${RED}✗ scripts/setup-gdrive.sh が見つかりません${NC}"
fi

echo ""
sleep 2

# ================================================
# 3. バックアップ自動化設定
# ================================================
echo "=========================================="
echo "[3/3] バックアップ自動化設定"
echo "=========================================="
echo ""

if [ -f "$SCRIPT_DIR/scripts/backup.sh" ]; then
    bash "$SCRIPT_DIR/scripts/backup.sh" --setup
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ バックアップ自動化設定完了${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠ バックアップ設定に失敗またはスキップしました${NC}"
        echo "後で手動実行できます: bash scripts/backup.sh --setup"
    fi
else
    echo -e "${RED}✗ scripts/backup.sh が見つかりません${NC}"
fi

echo ""

# ================================================
# 4. セキュリティ設定（権限一括設定）
# ================================================
echo "=========================================="
echo "[4/4] セキュリティ設定"
echo "=========================================="
echo ""

# ディレクトリ権限設定
echo "ディレクトリ権限設定..."

# scripts/ → 700（root専用、Docker非使用）
if [ -d "$SCRIPT_DIR/scripts" ]; then
    chmod 700 "$SCRIPT_DIR/scripts"
    echo "  ✓ scripts/ → 700"
fi

# docker/ → 755（Docker :ro マウント、標準権限）
if [ -d "$SCRIPT_DIR/docker" ]; then
    chmod 755 "$SCRIPT_DIR/docker"
    echo "  ✓ docker/ → 755"
fi

# docker/nginx/ → 755
if [ -d "$SCRIPT_DIR/docker/nginx" ]; then
    chmod 755 "$SCRIPT_DIR/docker/nginx"
    echo "  ✓ docker/nginx/ → 755"
fi

# backups/ → owner=一般ユーザー（必ず）、750
if [ ! -d "$SCRIPT_DIR/backups" ]; then
    mkdir -p "$SCRIPT_DIR/backups"
    echo "  ✓ backups/ ディレクトリ作成"
fi
chown "$OWNER":"$OWNER" "$SCRIPT_DIR/backups"
chmod 750 "$SCRIPT_DIR/backups"
echo "  ✓ backups/ → owner=${OWNER}, 750"

echo ""

# 機密ファイル権限設定
echo "機密ファイル権限設定..."

# .env → 600
if [ -f "$SCRIPT_DIR/.env" ]; then
    chmod 600 "$SCRIPT_DIR/.env"
    echo "  ✓ .env → 600 (DB認証情報・全パスワード保護)"
else
    echo "  ⚠ .env not found (後で作成後に chmod 600 .env)"
fi

# scripts/*.sh → 700（ワイルドカード展開）
if [ -d "$SCRIPT_DIR/scripts" ]; then
    SCRIPT_COUNT=0
    for script in $SCRIPT_DIR/scripts/*.sh; do
        if [ -f "$script" ]; then
            chmod 700 "$script"
            SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
        fi
    done
    if [ $SCRIPT_COUNT -gt 0 ]; then
        echo "  ✓ scripts/*.sh → 700 ($SCRIPT_COUNT files, root専用)"
    fi
fi

echo ""

# 設定ファイル権限設定
echo "設定ファイル権限設定..."

# nginx/*.conf → 644
if [ -d "$SCRIPT_DIR/docker/nginx" ]; then
    for conf in $SCRIPT_DIR/docker/nginx/*.conf; do
        if [ -f "$conf" ]; then
            chmod 644 "$conf"
        fi
    done
    echo "  ✓ docker/nginx/*.conf → 644"
fi

# docker-compose.yml → 644
if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
    chmod 644 "$SCRIPT_DIR/docker-compose.yml"
    echo "  ✓ docker-compose.yml → 644"
fi

# docker-compose.dev.yml → 644
if [ -f "$SCRIPT_DIR/docker-compose.dev.yml" ]; then
    chmod 644 "$SCRIPT_DIR/docker-compose.dev.yml"
    echo "  ✓ docker-compose.dev.yml → 644"
fi

# Dockerfile → 644
if [ -f "$SCRIPT_DIR/Dockerfile" ]; then
    chmod 644 "$SCRIPT_DIR/Dockerfile"
    echo "  ✓ Dockerfile → 644"
fi

# .dockerignore → 644
if [ -f "$SCRIPT_DIR/.dockerignore" ]; then
    chmod 644 "$SCRIPT_DIR/.dockerignore"
    echo "  ✓ .dockerignore → 644"
fi

# .gitignore → 644
if [ -f "$SCRIPT_DIR/.gitignore" ]; then
    chmod 644 "$SCRIPT_DIR/.gitignore"
    echo "  ✓ .gitignore → 644"
fi

echo ""

# 実行スクリプト権限設定
echo "実行スクリプト権限設定..."

# init.sh → 700（root専用実行）
if [ -f "$SCRIPT_DIR/init.sh" ]; then
    chmod 700 "$SCRIPT_DIR/init.sh"
    echo "  ✓ init.sh → 700 (root専用)"
fi

# custom-entrypoint.sh → 755（Docker実行、標準権限）
if [ -f "$SCRIPT_DIR/docker/custom-entrypoint.sh" ]; then
    chmod 755 "$SCRIPT_DIR/docker/custom-entrypoint.sh"
    echo "  ✓ docker/custom-entrypoint.sh → 755"
fi

# wp-init.sh → 755（Docker実行、標準権限）
if [ -f "$SCRIPT_DIR/docker/wp-init.sh" ]; then
    chmod 755 "$SCRIPT_DIR/docker/wp-init.sh"
    echo "  ✓ docker/wp-init.sh → 755"
fi

# import-acf-json.php → 644
if [ -f "$SCRIPT_DIR/docker/import-acf-json.php" ]; then
    chmod 644 "$SCRIPT_DIR/docker/import-acf-json.php"
    echo "  ✓ docker/import-acf-json.php → 644"
fi

echo ""
echo "=========================================="
echo "✓ セキュリティ設定完了"
echo "=========================================="
echo ""
echo "【設定内容】"
echo "  機密: .env(600), scripts/(700), scripts/*.sh(700)"
echo "  Docker: docker/(755), nginx/(755), docker/custom-entrypoint.sh(755), docker/wp-init.sh(755)"
echo "  設定: *.yml(644), *.conf(644), Dockerfile(644)"
echo "  実行: init.sh(700)"
echo "  ※ backups/(700)はbackup.sh実行時に自動設定"
echo ""
echo "=========================================="
echo ""

# ================================================
# 完了
# ================================================
echo "=========================================="
echo "✓ 統合セットアップ完了！"
echo "=========================================="
echo ""
echo "【構成】"
echo "  インターネット (HTTPS:443)"
echo "    ↓"
echo "  ホストNginx (Let's Encrypt TLS)"
echo "    ↓ proxy_pass http://localhost:8080"
echo "  DockerコンテナNginx (ポート8080)"
echo "    ↓"
echo "  WordPress + MySQL"
echo ""
echo "【アクセスURL】"
echo "  サイト: https://${DOMAIN}"
echo "  管理画面: https://${DOMAIN}/wp-admin"
echo ""
echo "【バックアップ】"
echo "  保存先: Google Drive + ローカル（backups/）"
echo "  自動実行: crontabで設定済み"
echo ""
echo "【確認コマンド】"
echo "  Nginx設定: sudo nginx -t"
echo "  TLS証明書: sudo certbot certificates"
echo "  cron設定: crontab -l"
echo "  バックアップ: bash scripts/backup.sh"
echo ""
echo "【トラブルシューティング】"
echo "  Nginxログ: tail -f /var/log/nginx/error.log"
echo "  Dockerログ: docker compose logs -f"
echo "  バックアップログ: tail -f backups/backup.log"
echo ""
echo "=========================================="