#!/bin/bash
set -e

echo "=========================================="
echo "WordPress Custom Entrypoint Starting..."
echo "=========================================="

# PHP設定を動的に生成（本番・開発共通）
echo "[0/7] Configuring PHP settings..."
cat > /usr/local/etc/php/conf.d/uploads.ini <<'EOF'
; WordPress ファイルアップロード設定
upload_max_filesize = 20M
post_max_size = 20M
max_execution_time = 300
memory_limit = 256M
EOF
echo "✓ PHP settings configured!"

# 公式entrypointをバックグラウンドで実行（php-fpm起動）
echo "[1/7] Starting official WordPress entrypoint..."
docker-entrypoint.sh php-fpm &
PHP_FPM_PID=$!

# WordPressファイルのコピーを待つ
echo "[2/7] Waiting for WordPress files..."
while [ ! -f /var/www/html/wp-config.php ]; do
    echo "Waiting for wp-config.php creation..."
    sleep 2
done
echo "✓ wp-config.php found!"

# 自動更新を無効化（イメージバージョン固定のため）
echo "  - Disabling auto-updates..."
wp config set AUTOMATIC_UPDATER_DISABLED true --raw --allow-root
wp config set WP_AUTO_UPDATE_CORE false --raw --allow-root
echo "  ✓ Auto-updates disabled!"

# テーマ同期: イメージ → ボリューム（毎回実行）
# CI/CDでイメージが更新された場合、ここで最新テーマがボリュームに反映される
echo "[3/7] Syncing theme from image to volume..."
if [ -n "${THEME_NAME}" ] && [ -d "/usr/src/wordpress/wp-content/themes/${THEME_NAME}" ]; then
    cp -rf "/usr/src/wordpress/wp-content/themes/${THEME_NAME}" /var/www/html/wp-content/themes/
    chown -R www-data:www-data "/var/www/html/wp-content/themes/${THEME_NAME}"
    echo "✓ Theme '${THEME_NAME}' synced!"
else
    echo "⚠ Theme '${THEME_NAME:-未設定}' not found in image, skipping sync"
fi

# MySQL接続待機（PHPで直接接続テスト）
echo "[4/7] Waiting for MySQL connection..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if php -r "new PDO('mysql:host=${WORDPRESS_DB_HOST};dbname=${WORDPRESS_DB_NAME}', '${WORDPRESS_DB_USER}', '${WORDPRESS_DB_PASSWORD}');" 2>/dev/null; then
        echo "✓ MySQL connection established!"
        break
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Retry $RETRY_COUNT/$MAX_RETRIES - Waiting for MySQL..."
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "✗ Failed to connect to MySQL after $MAX_RETRIES attempts"
    exit 1
fi

# 初期化判定（wp core is-installed ベース）
echo "[5/7] Checking WordPress installation status via wp-cli..."

SKIP_INIT=false

if wp core is-installed --allow-root >/dev/null 2>&1; then
    echo "[5/7] WordPress core is already installed (wp core is-installed = 0)"
    echo "[6/7] Skipping initialization..."
    SKIP_INIT=true
else
    echo "[5/7] WordPress is NOT installed (wp core is-installed != 0)"
    echo "[6/7] Running initialization script wp-init.sh..."

    if [ -f /usr/local/bin/wp-init.sh ]; then
        bash /usr/local/bin/wp-init.sh

        if [ $? -eq 0 ]; then
            echo "[6/7] ✓ Initialization completed successfully!"
        else
            echo "[6/7] ✗ Initialization failed!"
            exit 1
        fi
    else
        echo "✗ wp-init.sh not found!"
        exit 1
    fi
fi

echo ""

# /var/www/html & wp-contentの所有者、権限設定（初回のみ）
echo "[7/7] Setting file permissions..."

DOCROOT="/var/www/html"
WP_CONTENT="${DOCROOT}/wp-content"

if [ "$SKIP_INIT" = "false" ]; then
    echo ""
    echo "=========================================="
    echo "Setting permissions (first install)"
    echo "=========================================="
    
    # /var/www/html 全体の所有者を www-data に
    echo "  - Setting ownership to www-data:www-data ..."
    chown -R www-data:www-data "$DOCROOT"
    
    # ディレクトリ: 755
    echo "  - Setting directories to 755 ..."
    find "$DOCROOT" -type d -exec chmod 755 {} +
    
    # ファイル: 644（実行ビット持つものは除外）
    echo "  - Setting files to 644 (preserving execute bit) ..."
    find "$DOCROOT" -type f ! -perm -111 -exec chmod 644 {} +
    
    # wp-config.php のみ 600（セキュリティ強化）
    if [ -f "${DOCROOT}/wp-config.php" ]; then
        chmod 600 "${DOCROOT}/wp-config.php"
        echo "  - wp-config.php set to 600"
    fi
    
    # wp-content だけ書き込み可に（775/664）
    echo "  - Setting wp-content to 775/664 ..."
    find "$WP_CONTENT" -type d -exec chmod 775 {} +
    find "$WP_CONTENT" -type f ! -perm -111 -exec chmod 664 {} +
    
    echo "=========================================="
    echo "✓ Permissions set successfully!"
    echo "=========================================="
else
    echo "✓ WordPress already installed, skipping permission setup..."
fi

echo ""

echo "=========================================="
echo "WordPress is ready!"
echo "=========================================="
echo "Access: ${WP_HOME:-http://localhost:8080}"
echo "Admin: ${WP_ADMIN_USER:-admin}"
echo "=========================================="

# PHP-FPMプロセス維持（フォアグラウンドで待機）
echo "Maintaining php-fpm process..."
wait $PHP_FPM_PID