#!/bin/bash
set -e
set -o pipefail  # パイプラインの途中でエラーが起きても検出

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

# root権限チェック
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ このスクリプトはroot権限で実行してください${NC}"
    echo ""
    echo "正しい実行方法:"
    echo "  sudo bash scripts/restore.sh"
    echo ""
    exit 1
fi

# SUDO_USERチェック（sudoで実行されているか確認）
if [ -z "$SUDO_USER" ]; then
    echo -e "${RED}✗ このスクリプトはsudoコマンド経由で実行してください${NC}"
    echo ""
    echo "正しい実行方法:"
    echo "  sudo bash scripts/restore.sh"
    echo ""
    echo "（直接rootユーザーで実行しないでください）"
    exit 1
fi

echo "=========================================="
echo "WordPress Docker環境 復元スクリプト"
echo "=========================================="
echo ""

# バックアップディレクトリの確認
BACKUP_DIR="backups"

if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}✗ バックアップディレクトリが見つかりません: $BACKUP_DIR${NC}"
    exit 1
fi

# ================================================
# 1. バックアップファイル一覧表示・選択
# ================================================
echo "[1/10] バックアップファイルの確認"
echo "=========================================="
echo ""

# 日付でグループ化されたバックアップを検索
DB_BACKUPS=($(ls -t "$BACKUP_DIR"/db-*.sql.gz 2>/dev/null || true))
DATA_BACKUPS=($(ls -t "$BACKUP_DIR"/data-*.tar.gz 2>/dev/null || true))
ENV_BACKUPS=($(ls -t "$BACKUP_DIR"/env-*.txt 2>/dev/null || true))

if [ ${#DB_BACKUPS[@]} -eq 0 ] && [ ${#DATA_BACKUPS[@]} -eq 0 ]; then
    echo -e "${RED}✗ バックアップファイルが見つかりません${NC}"
    echo ""
    echo "バックアップを作成してください:"
    echo "  sudo bash scripts/backup.sh"
    exit 1
fi

# タイムスタンプのユニークなリストを作成
declare -A BACKUP_DATES
for file in "${DB_BACKUPS[@]}" "${DATA_BACKUPS[@]}" "${ENV_BACKUPS[@]}"; do
    # ファイル名から日時を抽出 (例: db-20241107_123456.sql.gz → 20241107_123456)
    TIMESTAMP=$(basename "$file" | sed -E 's/(db|data|env)-([0-9_]+)\..*/\2/')
    BACKUP_DATES["$TIMESTAMP"]=1
done

# 日付順にソート
SORTED_DATES=($(for date in "${!BACKUP_DATES[@]}"; do echo "$date"; done | sort -r))

echo "利用可能なバックアップ:"
echo ""

for i in "${!SORTED_DATES[@]}"; do
    TIMESTAMP="${SORTED_DATES[$i]}"
    
    # 日時を読みやすい形式に変換 (20241107_123456 → 2024-11-07 12:34:56)
    READABLE_DATE=$(echo "$TIMESTAMP" | sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3 \4:\5:\6/')
    
    echo "  $((i+1))) $READABLE_DATE"
    
    # 各ファイルの存在確認
    DB_FILE="$BACKUP_DIR/db-${TIMESTAMP}.sql.gz"
    DATA_FILE="$BACKUP_DIR/data-${TIMESTAMP}.tar.gz"
    ENV_FILE="$BACKUP_DIR/env-${TIMESTAMP}.txt"
    
    [ -f "$DB_FILE" ] && echo "     ✓ Database: $(du -h "$DB_FILE" | cut -f1)"
    [ -f "$DATA_FILE" ] && echo "     ✓ Data: $(du -h "$DATA_FILE" | cut -f1)"
    [ -f "$ENV_FILE" ] && echo "     ✓ .env: $(du -h "$ENV_FILE" | cut -f1)"
    echo ""
done

echo "=========================================="
read -p "復元するバックアップを選択 (1-${#SORTED_DATES[@]}): " CHOICE

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt ${#SORTED_DATES[@]} ]; then
    echo -e "${RED}✗ 無効な選択です${NC}"
    exit 1
fi

SELECTED_TIMESTAMP="${SORTED_DATES[$((CHOICE-1))]}"
SELECTED_DATE=$(echo "$SELECTED_TIMESTAMP" | sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3 \4:\5:\6/')

DB_FILE="$BACKUP_DIR/db-${SELECTED_TIMESTAMP}.sql.gz"
DATA_FILE="$BACKUP_DIR/data-${SELECTED_TIMESTAMP}.tar.gz"
ENV_FILE="$BACKUP_DIR/env-${SELECTED_TIMESTAMP}.txt"

echo ""
echo -e "${GREEN}✓ 選択されたバックアップ: $SELECTED_DATE${NC}"
echo ""

# ================================================
# 2. 復元モード選択
# ================================================
echo "[2/10] 復元モードの選択"
echo "=========================================="
echo ""
echo "復元モードを選択してください:"
echo ""
echo "  1) 完全復元 (推奨)"
echo "     → .env + data/ + MySQL を復元"
echo "     → サイトを完全に元の状態に戻します"
echo ""
echo "  2) 部分復元"
echo "     → .env + data/ のみ復元 (MySQL除外)"
echo "     → ファイルのみ復元、データベースは現状維持"
echo ""
read -p "選択してください (1/2): " RESTORE_CHOICE

case $RESTORE_CHOICE in
    1)
        RESTORE_MYSQL=true
        echo -e "${GREEN}✓ 完全復元モード${NC}"
        ;;
    2)
        RESTORE_MYSQL=false
        echo -e "${YELLOW}⚠ 部分復元モード (MySQL除外)${NC}"
        ;;
    *)
        echo -e "${RED}✗ 無効な選択です${NC}"
        exit 1
        ;;
esac

echo ""

# ================================================
# 3. 確認プロンプト
# ================================================
echo "[3/10] 復元内容の確認"
echo "=========================================="
echo ""
echo -e "${YELLOW}⚠ 警告: 以下のデータは完全に削除されます${NC}"
echo ""
echo "  - 現在の data/ ディレクトリ"
if [ "$RESTORE_MYSQL" = true ]; then
    echo "  - 現在の MySQL データベース"
fi
echo ""
echo "復元されるファイル:"
[ -f "$ENV_FILE" ] && echo "  ✓ .env"
[ -f "$DATA_FILE" ] && echo "  ✓ data/ (wp-content)"
if [ "$RESTORE_MYSQL" = true ] && [ -f "$DB_FILE" ]; then
    echo "  ✓ MySQL database"
fi
echo ""
echo "=========================================="
echo ""
read -p "本当に復元を実行しますか？ (yes/N): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "キャンセルしました"
    exit 0
fi

echo ""

# ================================================
# 4. Docker停止
# ================================================
echo "[4/10] Docker環境を停止中..."
echo ""

if sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose ps --quiet 2>/dev/null | grep -q .; then
    sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose down
    echo -e "${GREEN}✓ Docker停止完了${NC}"
else
    echo -e "${YELLOW}⚠ Dockerは既に停止しています${NC}"
fi

echo ""

# ================================================
# 5. data/ ディレクトリ削除
# ================================================
echo "[5/10] 既存のdata/ディレクトリを削除中..."
echo ""

if [ -d "data" ]; then
    rm -rf data/
    echo -e "${GREEN}✓ data/削除完了${NC}"
else
    echo -e "${YELLOW}⚠ data/は存在しません${NC}"
fi

echo ""

# ================================================
# 6. .env 復元
# ================================================
echo "[6/10] .envファイルを復元中..."
echo ""
if [ -f "$ENV_FILE" ]; then
    cp "$ENV_FILE" .env
    echo -e "${GREEN}✓ .env復元完了${NC}"
else
    echo -e "${RED}✗ .envバックアップが見つかりません: $ENV_FILE${NC}"
    echo "手動で.envを作成してください"
    exit 1
fi
echo ""


# ================================================
# 7. Docker起動
# ================================================
echo "[7/10] Docker環境を起動中..."
echo ""

sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose up -d

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker起動完了${NC}"
else
    echo -e "${RED}✗ Docker起動に失敗しました${NC}"
    exit 1
fi

# WordPressコンテナがexec可能になるまで待機
echo "WordPressコンテナの起動を待機中..."
RETRY_COUNT=0
while [ $RETRY_COUNT -lt 30 ]; do
    if sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T wordpress test -f /var/www/html/wp-config.php 2>/dev/null; then
        echo -e "${GREEN}✓ WordPressコンテナ準備完了${NC}"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Retry $RETRY_COUNT/30 - Waiting for WordPress container..."
    sleep 2
done

if [ $RETRY_COUNT -eq 30 ]; then
    echo -e "${RED}✗ WordPressコンテナの起動に失敗しました${NC}"
    exit 1
fi

echo ""

# ================================================
# 8. WordPress データ復元（コンテナ内に直接書き込み）
# ================================================
echo "[8/10] WordPressデータを復元中..."
echo ""

if [ -f "$DATA_FILE" ]; then

    # tarファイルをコンテナの一時ディレクトリにコピー
    echo "バックアップファイルをコンテナにコピー中..."
    CONTAINER_TEMP="/tmp/restore-backup.tar.gz"
    cat "$DATA_FILE" | sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T wordpress sh -c "cat > ${CONTAINER_TEMP}"

    # コンテナ内で展開（バインド/ネームド問わず /var/www/html に書く）
    echo "コンテナ内でデータを展開中..."
    sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T wordpress sh -c "
        cd /var/www/html && \
        tar -xzf ${CONTAINER_TEMP} && \
        rm -f ${CONTAINER_TEMP}
    "

    # パーミッション設定（custom-entrypoint.shと同じロジック）
    echo "パーミッション設定中..."
    sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T wordpress chown -R www-data:www-data /var/www/html
    sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T wordpress find /var/www/html -type d -exec chmod 755 {} \;
    sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T wordpress find /var/www/html -type f ! -perm -111 -exec chmod 644 {} \;
    sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T wordpress sh -c '[ -f /var/www/html/wp-config.php ] && chmod 600 /var/www/html/wp-config.php || true'
    sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T wordpress find /var/www/html/wp-content -type d -exec chmod 775 {} \;
    sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T wordpress find /var/www/html/wp-content -type f ! -perm -111 -exec chmod 664 {} \;

    echo -e "${GREEN}✓ データ復元完了${NC}"

else
    echo -e "${RED}✗ dataバックアップが見つかりません: $DATA_FILE${NC}"
    exit 1
fi

echo ""

# ================================================
# 9. MySQL接続待機
# ================================================
echo "[9/10] MySQLの起動を待機中..."
echo ""

# .envから環境変数を読み込む（スペースや特殊文字を含む値に対応）
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T mysql mysqladmin ping -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ MySQL接続確立${NC}"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Retry $RETRY_COUNT/$MAX_RETRIES - Waiting for MySQL..."
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}✗ MySQLに接続できませんでした${NC}"
    exit 1
fi

echo ""

# ================================================
# 10. SQL インポート (完全復元の場合のみ)
# ================================================
if [ "$RESTORE_MYSQL" = true ]; then
    echo "[10/10] MySQLデータベースをインポート中..."
    echo ""

    if [ ! -f "$DB_FILE" ]; then
        echo -e "${RED}✗ データベースバックアップが見つかりません: $DB_FILE${NC}"
        exit 1
    fi

    # バックアップファイルの整合性確認
    echo "バックアップファイルの検証中..."
    if ! gunzip -t "$DB_FILE" 2>/dev/null; then
        echo -e "${RED}✗ バックアップファイルが破損しています: $DB_FILE${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ バックアップファイル検証完了${NC}"
    echo ""

    # MySQL接続を再確認
    echo "MySQL接続を再確認中..."
    RECHECK_COUNT=0
    while [ $RECHECK_COUNT -lt 5 ]; do
        if sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T mysql mysqladmin ping -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ MySQL接続確認${NC}"
            break
        fi
        RECHECK_COUNT=$((RECHECK_COUNT + 1))
        echo "MySQL再接続試行 $RECHECK_COUNT/5..."
        sleep 2
    done

    if [ $RECHECK_COUNT -eq 5 ]; then
        echo -e "${RED}✗ MySQLへの再接続に失敗しました${NC}"
        echo "コンテナステータスを確認してください: docker compose ps"
        exit 1
    fi
    echo ""

    # データベースをドロップして再作成
    echo "既存のデータベースをクリア中..."
    if ! sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS ${WORDPRESS_DB_NAME};" 2>&1; then
        echo -e "${RED}✗ データベースのクリアに失敗しました${NC}"
        echo "データベース名: ${WORDPRESS_DB_NAME}"
        exit 1
    fi

    echo "データベースを作成中..."
    if ! sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE ${WORDPRESS_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>&1; then
        echo -e "${RED}✗ データベースの作成に失敗しました${NC}"
        echo "データベース名: ${WORDPRESS_DB_NAME}"
        exit 1
    fi

    echo "データベースをインポート中... (時間がかかる場合があります)"

    # 一時ファイルに解凍してからインポート（パイプラインの問題回避）
    TEMP_SQL=$(mktemp)
    echo "SQLファイルを解凍中..."
    if ! gunzip < "$DB_FILE" > "$TEMP_SQL" 2>&1; then
        echo -e "${RED}✗ SQLファイルの解凍に失敗しました${NC}"
        rm -f "$TEMP_SQL"
        exit 1
    fi

    echo "MySQLにインポート中..."
    if ! sudo -u "$SUDO_USER" HOME="/home/$SUDO_USER" docker compose exec -T mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "${WORDPRESS_DB_NAME}" < "$TEMP_SQL" 2>&1; then
        echo -e "${RED}✗ MySQLインポートに失敗しました${NC}"
        echo "データベースファイル: ${DB_FILE}"
        echo "データベース名: ${WORDPRESS_DB_NAME}"
        echo "一時SQLファイル: ${TEMP_SQL} (デバッグ用に保持)"
        exit 1
    fi

    # 一時ファイル削除
    rm -f "$TEMP_SQL"

    echo -e "${GREEN}✓ MySQLインポート完了${NC}"
else
    echo "[10/10] MySQLインポート: スキップ (部分復元モード)"
fi

echo ""

# ================================================
# 完了
# ================================================
echo "=========================================="
echo "✓ 復元完了！"
echo "=========================================="
echo ""
echo "【復元内容】"
echo "  日時: $SELECTED_DATE"
[ -f "$ENV_FILE" ] && echo "  ✓ .env"
[ -f "$DATA_FILE" ] && echo "  ✓ data/ (wp-content)"
if [ "$RESTORE_MYSQL" = true ] && [ -f "$DB_FILE" ]; then
    echo "  ✓ MySQL database"
fi
echo ""
echo "【アクセス】"
if [ -f .env ]; then
    WP_HOME=$(grep "^WP_HOME=" .env | cut -d'=' -f2)
    echo "  サイト: ${WP_HOME:-http://localhost:8080}"
    echo "  管理画面: ${WP_HOME:-http://localhost:8080}/wp-admin"
fi
echo ""
echo "【確認コマンド】"
echo "  Docker状態: docker compose ps"
echo "  ログ確認: docker compose logs -f"
echo "  MySQL接続: docker compose exec mysql mysql -u root -p"
echo ""
echo "=========================================="