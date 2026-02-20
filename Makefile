# ローカル開発 & CI/CD 用コマンド
# 本番ホスト側セットアップはsudo bash init.sh example.com を使用

DEV := -f docker-compose.yml -f docker-compose.dev.yml --profile dev

# ==================== 開発 ====================

dev: init-data
	docker compose $(DEV) up -d

down:
	docker compose $(DEV) down

down-v:
	docker compose $(DEV) down -v

logs:
	docker compose logs -f

build:
	docker compose build --no-cache

# ==================== 初期化 ====================

# data/ backups/ の存在と権限を保証
init-data:
	mkdir -p data backups
	sudo chown www-data:www-data data && sudo chmod 755 data
	sudo chown "$$USER":"$$USER" backups && sudo chmod 750 backups

# パーミッション手動修正（wp-contentがGIDで編集不能のとき）
fix-perms:
	sudo find data/wordpress/wp-content -type d -exec chmod 775 {} +
	sudo find data/wordpress/wp-content -type f ! -perm -111 -exec chmod 664 {} +

# ==================== CI/CD ====================

# data/ → wordpress/ にテーマを同期（push前に実行）
sync:
	docker exec wp-node npm run build
	sudo rsync -av --delete --chown=$$USER:$$USER \
		--exclude='acf-json/' \
		data/wordpress/wp-content/themes/ \
		wordpress/wp-content/themes/