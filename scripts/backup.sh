#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# root権限チェック
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ このスクリプトはroot権限で実行してください${NC}"
    echo ""
    echo "正しい実行方法:"
    echo "  sudo bash scripts/backup.sh"
    echo "  sudo bash scripts/backup.sh --setup"
    echo ""
    exit 1
fi

# 親ディレクトリに移動（scripts/から実行されるため）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

# 初期設定モード
if [ "$1" = "--setup" ]; then
    echo "=========================================="
    echo "WordPress Backup Setup"
    echo "=========================================="
    echo ""

    echo -e "${BLUE}今すぐバックアップを実行しますか？ (y/N):${NC}"
    read -p "> " -n 1 -r RUN_NOW
    echo ""

    echo ""
    echo -e "${BLUE}何日おきに自動バックアップを実行しますか？${NC}"
    echo "  推奨: 7日おき（毎週）"
    echo "  例: 1=毎日, 3=3日おき, 7=毎週, 14=隔週, 30=月1回"
    read -p "> " INTERVAL

    if [ -z "$INTERVAL" ]; then
        INTERVAL=7
        echo -e "${YELLOW}デフォルト値（7日おき）を使用します${NC}"
    fi

    # cron設定を計算
    if [ "$INTERVAL" = "1" ]; then
        CRON_SCHEDULE="0 4 * * *"
        SCHEDULE_DESC="毎日午前4時"
    elif [ "$INTERVAL" = "7" ]; then
        CRON_SCHEDULE="0 4 * * 0"
        SCHEDULE_DESC="毎週日曜午前4時"
    elif [ "$INTERVAL" = "30" ]; then
        CRON_SCHEDULE="0 4 1 * *"
        SCHEDULE_DESC="毎月1日午前4時"
    else
        CRON_SCHEDULE="0 4 */$INTERVAL * *"
        SCHEDULE_DESC="${INTERVAL}日おき午前4時"
    fi

    echo ""
    echo "=========================================="
    echo "設定内容の確認"
    echo "=========================================="
    echo "実行スケジュール: ${SCHEDULE_DESC}"
    echo "スクリプトパス: ${SCRIPT_DIR}/scripts/backup.sh"
    echo "ログ保存先: ${SCRIPT_DIR}/backups/backup.log"
    echo ""
    echo -e "${YELLOW}この設定でcronに登録しますか？ (y/N):${NC}"
    read -p "> " -n 1 -r CONFIRM_CRON
    echo ""

    if [[ $CONFIRM_CRON =~ ^[Yy]$ ]]; then
        TEMP_CRON=$(mktemp)
        crontab -l > "$TEMP_CRON" 2>/dev/null || true
        grep -v "${SCRIPT_DIR}/scripts/backup.sh" "$TEMP_CRON" > "${TEMP_CRON}.new" 2>/dev/null || touch "${TEMP_CRON}.new"
        echo "${CRON_SCHEDULE} ${SCRIPT_DIR}/scripts/backup.sh >> ${SCRIPT_DIR}/backups/backup.log 2>&1" >> "${TEMP_CRON}.new"
        crontab "${TEMP_CRON}.new"
        rm -f "$TEMP_CRON" "${TEMP_CRON}.new"

        echo -e "${GREEN}✓ cron設定が完了しました！${NC}"

        echo ""
        echo "=========================================="
        echo "バックアップ自動実行設定"
        echo "=========================================="

        if crontab -l 2>/dev/null | grep -q "${SCRIPT_DIR}/scripts/backup.sh"; then
            crontab -l | grep "${SCRIPT_DIR}/scripts/backup.sh"
            echo ""
            echo "✓ backup.sh自動実行が設定されました"
        else
            echo "✗ cron設定が見つかりません"
        fi

        echo ""

        # Ubuntu: サービス名は "cron" (AL2023は "crond")
        CRON_SERVICE_NAME="cron"

        if systemctl is-active --quiet $CRON_SERVICE_NAME 2>/dev/null; then
            echo "✓ ${CRON_SERVICE_NAME}サービス: 起動中"
        else
            echo "✗ ${CRON_SERVICE_NAME}サービス: 停止中"
        fi

        echo "=========================================="
        echo ""
    else
        echo -e "${YELLOW}cron設定をスキップしました${NC}"
        echo ""
        echo "手動で設定する場合:"
        echo "  crontab -e"
        echo "  ${CRON_SCHEDULE} ${SCRIPT_DIR}/scripts/backup.sh >> ${SCRIPT_DIR}/backups/backup.log 2>&1"
    fi

    echo ""

    if [[ $RUN_NOW =~ ^[Yy]$ ]]; then
        echo "=========================================="
        echo "バックアップを開始します..."
        echo "=========================================="
        echo ""
    else
        echo "=========================================="
        echo "✓ セットアップ完了！"
        echo "=========================================="
        echo ""
        echo "手動でバックアップを実行: bash scripts/backup.sh"
        echo "次回の自動実行: ${SCHEDULE_DESC}"
        echo ""
        echo "※ 確認コマンド:"
        echo "  cron設定: crontab -l"
        echo "  ログ確認: tail -f backups/backup.log"
        echo ""
        exit 0
    fi
fi

# ================================================
# コンテナ起動状態の確認と起動
# ================================================
echo "=========================================="
echo "WordPress Docker Backup Script"
echo "=========================================="
echo "Started at: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 起動状態を記録
MYSQL_WAS_RUNNING=false
WORDPRESS_WAS_RUNNING=false

echo "Checking container status..."
echo ""

if [ -n "$(docker compose ps mysql --quiet 2>/dev/null)" ]; then
    MYSQL_WAS_RUNNING=true
    echo -e "${GREEN}✓ MySQL: Running${NC}"
else
    echo -e "${YELLOW}⚠ MySQL: Stopped${NC}"
fi

if [ -n "$(docker compose ps wordpress --quiet 2>/dev/null)" ]; then
    WORDPRESS_WAS_RUNNING=true
    echo -e "${GREEN}✓ WordPress: Running${NC}"
else
    echo -e "${YELLOW}⚠ WordPress: Stopped${NC}"
fi

echo ""

# 停止していたコンテナを起動
CONTAINERS_TO_STOP=""

if [ "$MYSQL_WAS_RUNNING" = false ]; then
    echo "Starting MySQL container..."
    docker compose up -d mysql
    CONTAINERS_TO_STOP="mysql $CONTAINERS_TO_STOP"
    sleep 5
fi

if [ "$WORDPRESS_WAS_RUNNING" = false ]; then
    echo "Starting WordPress container..."
    docker compose up -d wordpress
    CONTAINERS_TO_STOP="wordpress $CONTAINERS_TO_STOP"
    sleep 3
fi

if [ -n "$CONTAINERS_TO_STOP" ]; then
    echo -e "${GREEN}✓ Temporary containers started${NC}"
    echo ""
fi

echo "=========================================="
echo ""

if [ ! -f .env ]; then
    echo -e "${RED}✗ .env file not found!${NC}"
    exit 1
fi

# .envファイルを安全に読み込み（スペースや特殊文字を含む値に対応）
set -a
source .env
set +a

BACKUP_DIR="backups"
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

DATE=$(date +%Y%m%d_%H%M%S)

# 1. データベースバックアップ
echo "[1/5] Backing up MySQL database..."

DB_BACKUP_FILE="$BACKUP_DIR/db-${DATE}.sql.gz"

# MySQL接続待機
echo "Waiting for MySQL to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker compose exec -T mysql mysqladmin ping -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ MySQL is ready${NC}"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 1
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}✗ MySQL connection timeout${NC}"
    exit 1
fi

# データベースバックアップ実行
docker compose exec -T mysql mysqldump \
    -u root \
    -p"${MYSQL_ROOT_PASSWORD}" \
    --single-transaction \
    --quick \
    --lock-tables=false \
    "${WORDPRESS_DB_NAME}" | gzip > "$DB_BACKUP_FILE"

DB_SIZE=$(du -h "$DB_BACKUP_FILE" | cut -f1)
echo -e "${GREEN}✓ Database backup completed: $DB_BACKUP_FILE ($DB_SIZE)${NC}"

# 2. WordPressファイル（/var/www/html）バックアップ
echo "[2/5] Backing up WordPress files (/var/www/html)..."

DATA_BACKUP_FILE="$BACKUP_DIR/data-${DATE}.tar.gz"

# コンテナ内の /var/www/html をまるごと tar.gz にしてホストに書き出し
docker compose exec -T wordpress \
    sh -c 'tar czf - -C /var/www/html .' \
    > "$DATA_BACKUP_FILE"

DATA_SIZE=$(du -h "$DATA_BACKUP_FILE" | cut -f1)
echo -e "${GREEN}✓ Data backup completed: $DATA_BACKUP_FILE ($DATA_SIZE)${NC}"

# 3. .env ファイルバックアップ
echo "[3/5] Backing up .env file..."

ENV_BACKUP_FILE="$BACKUP_DIR/env-${DATE}.txt"

if [ -f .env ]; then
    if cp .env "$ENV_BACKUP_FILE" 2>&1; then
        echo -e "${GREEN}✓ .env backup completed: $ENV_BACKUP_FILE${NC}"
    else
        echo -e "${RED}✗ Failed to backup .env file (cp command failed)${NC}"
        echo -e "${YELLOW}⚠ Current directory: $(pwd)${NC}"
        echo -e "${YELLOW}⚠ .env permissions: $(ls -la .env)${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠ .env file not found at $(pwd)/.env, skipping...${NC}"
fi

# 4. 古いバックアップ削除（30日以上前）
echo "[4/5] Cleaning up old backups (older than 30 days)..."

DELETED_COUNT=0

for file in "$BACKUP_DIR"/db-*.sql.gz; do
    if [ -f "$file" ] && [ -n "$(find "$file" -mtime +30 2>/dev/null)" ]; then
        rm "$file"
        DELETED_COUNT=$((DELETED_COUNT + 1))
    fi
done

for file in "$BACKUP_DIR"/data-*.tar.gz; do
    if [ -f "$file" ] && [ -n "$(find "$file" -mtime +30 2>/dev/null)" ]; then
        rm "$file"
        DELETED_COUNT=$((DELETED_COUNT + 1))
    fi
done

for file in "$BACKUP_DIR"/env-*.txt; do
    if [ -f "$file" ] && [ -n "$(find "$file" -mtime +30 2>/dev/null)" ]; then
        rm "$file"
        DELETED_COUNT=$((DELETED_COUNT + 1))
    fi
done

if [ $DELETED_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓ Deleted $DELETED_COUNT old backup(s)${NC}"
else
    echo -e "${GREEN}✓ No old backups to delete${NC}"
fi

# ==========================================
# 5. Adjust backup directory permissions
# ==========================================
echo "[5/5] Adjusting backup directory permissions..."

# backups/ ディレクトリもファイルも全部 root 所有
chown -R root:root "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"           # ディレクトリ
find "$BACKUP_DIR" -maxdepth 1 -type f -exec chmod 600 {} \;  # ファイル

echo -e "${GREEN}✓ Backup permissions set (root:root 700/600)${NC}"

# バックアップサマリー
echo ""
echo "=========================================="
echo "Backup Summary"
echo "=========================================="
echo "Backup files created:"
echo "  - Database: $DB_BACKUP_FILE"
[ -f "$DATA_BACKUP_FILE" ] && echo "  - Data: $DATA_BACKUP_FILE"
[ -f "$ENV_BACKUP_FILE" ] && echo "  - Env: $ENV_BACKUP_FILE"
echo ""
echo "Total backup files: $(ls -1 $BACKUP_DIR 2>/dev/null | wc -l)"
echo "Backup directory size: $(du -sh $BACKUP_DIR 2>/dev/null | cut -f1)"
echo "=========================================="
echo "Completed at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# 6. Google Driveへアップロード（オプション）
REMOTE_NAME="${GDRIVE_REMOTE_NAME:-gdrive}"
GDRIVE_FOLDER="${GDRIVE_FOLDER:-}"

# rcloneとリモート設定の確認
if ! command -v rclone &> /dev/null; then
    echo ""
    echo "=========================================="
    echo "Google Drive Upload: Disabled"
    echo "=========================================="
    echo "rcloneがインストールされていません"
    echo ""
    echo "有効にする方法:"
    echo "  bash scripts/setup-gdrive.sh"
    echo "=========================================="
    exit 0
fi

if ! rclone listremotes | grep -q "${REMOTE_NAME}:"; then
    echo ""
    echo "=========================================="
    echo "Google Drive Upload: Disabled"
    echo "=========================================="
    echo "rcloneリモート '${REMOTE_NAME}' が設定されていません"
    echo ""
    echo "有効にする方法:"
    echo "  bash scripts/setup-gdrive.sh"
    echo "=========================================="
    exit 0
fi

# Google Drive接続テスト
echo ""
echo "Testing Google Drive connection..."

if ! rclone lsd "${REMOTE_NAME}:" &> /dev/null; then
    echo ""
    echo "=========================================="
    echo "Google Drive Upload: Skipped"
    echo "=========================================="
    echo -e "${YELLOW}⚠ Google Driveに接続できません${NC}"
    echo ""
    echo "【原因の可能性】"
    echo "  - 認証トークンが無効"
    echo "  - ネットワークエラー"
    echo "  - 認証が未完了"
    echo ""
    echo "【対処方法】"
    echo "  bash scripts/setup-gdrive.sh  # 再認証"
    echo ""
    echo "※ ローカルバックアップは完了しています"
    echo "=========================================="
    exit 0
fi

echo -e "${GREEN}✓ Google Drive connection OK${NC}"

# 保存先フォルダ設定
if [ -z "$GDRIVE_FOLDER" ]; then
    GDRIVE_FOLDER="backups"
    echo ""
    echo "保存先: マイドライブ/${GDRIVE_FOLDER}/ (デフォルト)"
fi

GDRIVE_REMOTE="${REMOTE_NAME}:${GDRIVE_FOLDER}"

echo "保存先: ${GDRIVE_REMOTE}/"
echo ""

# アップロード処理
UPLOAD_SUCCESS=0

if [ -f "$DB_BACKUP_FILE" ]; then
    echo "Uploading database backup..."
    if rclone copy "$DB_BACKUP_FILE" "$GDRIVE_REMOTE/" --progress; then
        UPLOAD_SUCCESS=$((UPLOAD_SUCCESS + 1))
    fi
fi

if [ -f "$DATA_BACKUP_FILE" ]; then
    echo "Uploading data backup..."
    if rclone copy "$DATA_BACKUP_FILE" "$GDRIVE_REMOTE/" --progress; then
        UPLOAD_SUCCESS=$((UPLOAD_SUCCESS + 1))
    fi
fi

if [ -f "$ENV_BACKUP_FILE" ]; then
    echo "Uploading .env backup..."
    if rclone copy "$ENV_BACKUP_FILE" "$GDRIVE_REMOTE/" --progress; then
        UPLOAD_SUCCESS=$((UPLOAD_SUCCESS + 1))
    fi
fi

if [ $UPLOAD_SUCCESS -gt 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Uploaded $UPLOAD_SUCCESS file(s) to Google Drive${NC}"
    echo -e "${GREEN}  Location: ${GDRIVE_REMOTE}/${NC}"

    echo ""
    echo "Cleaning up old backups on Google Drive..."
    rclone delete "$GDRIVE_REMOTE/" --min-age 30d --progress 2>/dev/null || true

    echo -e "${GREEN}✓ Google Drive cleanup completed${NC}"
else
    echo -e "${RED}✗ Google Drive upload failed${NC}"
fi

# ================================================
# 一時起動したコンテナのクリーンアップ
# ================================================
echo ""
echo "=========================================="
echo "Cleaning up temporary containers..."
echo "=========================================="
echo ""

if [ -n "$CONTAINERS_TO_STOP" ]; then
    echo "Stopping and removing temporary containers: $CONTAINERS_TO_STOP"
    docker compose down $CONTAINERS_TO_STOP
    echo -e "${GREEN}✓ Temporary containers cleaned up${NC}"
else
    echo "No temporary containers to clean up"
fi

echo ""
echo "=========================================="
echo "Backup process completed!"
echo "=========================================="
