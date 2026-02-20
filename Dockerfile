FROM wordpress:6.8.2-php8.2-fpm

# PDO MySQL拡張をインストール
RUN docker-php-ext-install pdo_mysql \
# 必要なパッケージをインストール
    && apt-get update && apt-get install -y \
        default-mysql-client \
    && rm -rf /var/lib/apt/lists/* \
# WP-CLI インストール
    && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && wp --info --allow-root

# テーマ削除は分ける（COPYの前に実行することを明示）
RUN rm -rf /usr/src/wordpress/wp-content/themes/twenty*

# wordpress/の内容,ACF設定を /usr/src/wordpress/ に配置
COPY wordpress/ docker/import-acf-json.php /usr/src/wordpress/

# パーミッション調整
RUN chown -R www-data:www-data /usr/src/wordpress \
    && find /usr/src/wordpress -type d -exec chmod 755 {} \; \
    && find /usr/src/wordpress -type f -exec chmod 644 {} \;