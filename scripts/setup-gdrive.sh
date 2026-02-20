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
    echo "  sudo bash scripts/setup-gdrive.sh"
    echo ""
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Google Drive バックアップ セットアップ"
echo "=========================================="
echo ""

# 1. rcloneインストール確認
echo "[1/4] rcloneインストール確認..."

if command -v rclone &> /dev/null; then
    RCLONE_VERSION=$(rclone version | head -1)
    echo -e "${GREEN}✓ rcloneは既にインストールされています${NC}"
    echo "  $RCLONE_VERSION"
else
    echo -e "${YELLOW}⚠ rcloneが見つかりません。インストールします...${NC}"
    echo ""
    
    # rcloneの公式インストールスクリプトを使用（OS非依存）
    curl https://rclone.org/install.sh | bash
    
    if command -v rclone &> /dev/null; then
        echo ""
        echo -e "${GREEN}✓ rcloneインストール完了${NC}"
    else
        echo -e "${RED}✗ rcloneインストールに失敗しました${NC}"
        exit 1
    fi
fi

echo ""

# 2. expectのインストール確認
echo "[2/4] expectインストール確認..."

if ! command -v expect &> /dev/null; then
    echo -e "${YELLOW}⚠ expectが見つかりません。インストールします...${NC}"
    
    # Amazon Linux 2023: yum
    # if yum install -y expect 2>/dev/null; then
    #     echo -e "${GREEN}✓ expectインストール完了（yum）${NC}"
    # else
    #     echo -e "${RED}✗ expectインストールに失敗しました${NC}"
    #     exit 1
    # fi
    
    # Ubuntu/Debian版:
    if apt-get update > /dev/null 2>&1 && apt-get install -y expect 2>/dev/null; then
        echo -e "${GREEN}✓ expectインストール完了（apt-get）${NC}"
    else
        echo -e "${RED}✗ expectインストールに失敗しました${NC}"
        exit 1
    fi
    
    # 最終確認
    if ! command -v expect &> /dev/null; then
        echo -e "${RED}✗ expectのインストールに失敗しました${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ expectは既にインストールされています${NC}"
fi

echo ""

# 3. リモート名の設定
echo "[3/4] リモート名の設定..."

if [ -f .env ]; then
    REMOTE_NAME=$(grep "^GDRIVE_REMOTE_NAME=" .env | cut -d'=' -f2 | tr -d ' "' || echo "gdrive")
else
    REMOTE_NAME="gdrive"
fi

if [ -z "$REMOTE_NAME" ]; then
    REMOTE_NAME="gdrive"
fi

echo "リモート名: ${REMOTE_NAME}"
echo ""

if rclone listremotes | grep -q "^${REMOTE_NAME}:$"; then
    echo -e "${YELLOW}⚠ リモート '${REMOTE_NAME}' は既に設定されています${NC}"
    echo ""
    read -p "再設定しますか？ (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "既存の設定を削除しています..."
        rclone config delete "${REMOTE_NAME}" 2>/dev/null || true
    else
        echo "既存の設定を使用します"
        SKIP_CONFIG=true
    fi
fi

echo ""

# 4. Google Drive認証
if [ "$SKIP_CONFIG" != "true" ]; then
    echo "[4/4] Google Drive認証..."
    echo ""
    echo "=========================================="
    echo -e "${BLUE}【認証方法の選択】${NC}"
    echo "=========================================="
    echo ""
    echo -e "1) ${GREEN}SSHトンネル方式${NC} (推奨・最も簡単)"
    echo "   → ローカルPCからSSHポートフォワーディング"
    echo ""
    echo -e "2) ${YELLOW}手動設定${NC}"
    echo "   → ステップバイステップで手動入力"
    echo ""
    read -p "選択してください (1/2): " AUTH_METHOD
    echo ""
    
    case "$AUTH_METHOD" in

        1)
            echo "=========================================="
            echo -e "${GREEN}SSHトンネル方式${NC}"
            echo "=========================================="
            echo ""
            echo "【手順】"
            echo ""
            echo -e "1. ${YELLOW}新しいターミナルを開いて${NC}、以下のコマンドを実行："
            echo ""
            echo -e "   ${BLUE}ssh -i [秘密鍵のパス] -L localhost:53682:localhost:53682 [ユーザー名]@[サーバーのパブリックIPv4]${NC}"
            echo ""
            echo "   ※ ログイン後、このターミナルは開いたまま放置"
            echo ""
            echo -e "2. ${YELLOW}このターミナルに戻って${NC}、Enterを押す"
            echo ""
            echo "3. 表示されるURLをブラウザで開く　※WinでURLひらけず失敗する場合、まずWSLネットワーク設定の破損を検討してください。" 
            echo ""
            echo "4. Googleアカウントでログイン → 許可"
            echo ""
            echo "=========================================="
            echo ""
            read -p "SSHトンネルの準備ができたらEnterを押してください..." 
            echo ""
            
            # expectスクリプト（y を選択）
            EXPECT_SCRIPT=$(mktemp)
            cat > "$EXPECT_SCRIPT" << 'EXPECTEOF'
#!/usr/bin/expect -f
set timeout 120
log_user 1

spawn rclone config

expect -re "(e/n/d/r/c/s/q>|n/s/q>)" { send "n\r" }
expect "name>" { send "gdrive\r" }
expect "Storage>" { send "drive\r" }
expect "client_id>" { send "\r" }
expect "client_secret>" { send "\r" }
expect "scope>" { send "1\r" }
expect "service_account_file>" { send "\r" }
expect -re "Edit advanced config.*y/n>" { send "n\r" }

# SSHトンネル方式なので y を選択
expect -re "(Use web browser|Use auto config).*y/n>" { send "y\r" }

# URLを抽出して表示
expect {
    -re "(http://127\\.0\\.0\\.1:53682/auth\[^\\s\\r\\n]+)" {
        set url $expect_out(1,string)
        send_user "\n"
        send_user "========================================\n"
        send_user "以下のURLをブラウザで開いてください:\n"
        send_user "========================================\n"
        send_user "\n"
        send_user "$url\n"
        send_user "\n"
        send_user "========================================\n"
        send_user "認証が完了するまでお待ちください...\n"
        send_user "========================================\n"
        send_user "\n"
    }
    timeout {
        send_user "\nエラー: URLの取得に失敗しました\n"
        exit 1
    }
}

# 認証完了を待つ
expect {
    -re "Got code" {
        send_user "\n"
        send_user "========================================\n"
        send_user "✓ 認証成功！\n"
        send_user "========================================\n"
        send_user "\n"
    }
    timeout {
        send_user "\nタイムアウト\n"
        exit 1
    }
}

# Shared Drive
expect -re "y/n>" { send "n\r" }

# Keep this remote
expect -re "y/e/d>" { send "y\r" }

# Quit
expect -re "(e/n/d/r/c/s/q>|n/s/q>)" { send "q\r" }
expect eof
EXPECTEOF

            chmod +x "$EXPECT_SCRIPT"
            
            if expect "$EXPECT_SCRIPT" 2>&1; then
                echo ""
                echo -e "${GREEN}✓ 認証設定が完了しました${NC}"
            else
                echo ""
                echo -e "${RED}✗ 認証に失敗しました${NC}"
                rm -f "$EXPECT_SCRIPT"
                exit 1
            fi
            
            rm -f "$EXPECT_SCRIPT"
            ;;
            
        2)
            echo "=========================================="
            echo -e "${YELLOW}手動設定${NC}"
            echo "=========================================="
            echo ""
            echo "rclone configを実行します。以下の順に入力してください："
            echo ""
            echo "  n → gdrive → drive → Enter → Enter → 1 → Enter → n → y"
            echo "  → ブラウザで認証"
            echo "  → n (Shared Drive) → y (Keep) → q (Quit)"
            echo ""
            read -p "準備ができたらEnterを押してください..." 
            echo ""
            
            rclone config
            ;;
            
        *)
            echo -e "${RED}✗ 無効な選択です${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    if rclone listremotes | grep -q "^${REMOTE_NAME}:$"; then
        echo -e "${GREEN}✓ Google Drive認証完了${NC}"
    else
        echo -e "${RED}✗ Google Drive認証に失敗しました${NC}"
        exit 1
    fi
else
    echo "[4/4] Google Drive認証..."
    echo -e "${GREEN}✓ 既存の認証を使用${NC}"
fi

echo ""
echo "=========================================="
echo "保存先フォルダの設定"
echo "=========================================="

# .env の存在チェック（必須）
if [ ! -f .env ]; then
    echo -e "${RED}✗ .envファイルが見つかりません${NC}"
    echo ""
    echo ".envファイルを作成してください:"
    echo "  cp .env.example .env"
    echo "  vi .env  # 必要な設定を行う"
    echo ""
    exit 1
fi

echo ""
echo "Google Drive上の保存先フォルダを設定します"
echo ""
echo "例:"
echo "  wordpress-backups/mysite"
echo "  → マイドライブ/wordpress-backups/mysite/ に保存"
echo ""
echo "  [空Enter]"
echo "  → マイドライブ/backups/ に保存（デフォルト）"
echo ""
echo "※ 使用可能な文字: a-z A-Z 0-9 _ - /"
echo ""
read -p "保存先フォルダ: " GDRIVE_FOLDER

# バリデーション
if [ -n "$GDRIVE_FOLDER" ]; then
    # 入力があった場合のみバリデーション実施

    # 許可文字チェック: a-zA-Z0-9_-/ のみ
    if ! [[ "$GDRIVE_FOLDER" =~ ^[a-zA-Z0-9_/-]+$ ]]; then
        echo ""
        echo -e "${RED}✗ 無効な文字が含まれています${NC}"
        echo "使用可能な文字: a-z A-Z 0-9 _ - /"
        echo ""
        exit 1
    fi

    # パストラバーサルチェック
    if [[ "$GDRIVE_FOLDER" =~ \.\. ]]; then
        echo ""
        echo -e "${RED}✗ '..' は使用できません（セキュリティ上の理由）${NC}"
        echo ""
        exit 1
    fi

    # 先頭/末尾のスラッシュを削除（正規化）
    GDRIVE_FOLDER=$(echo "$GDRIVE_FOLDER" | sed 's:^/*::;s:/*$::')

    echo ""
    echo -e "${GREEN}✓ 保存先: マイドライブ/${GDRIVE_FOLDER}/${NC}"
else
    echo ""
    echo -e "${GREEN}✓ デフォルト（backups/）を使用します${NC}"
fi

if grep -q "^GDRIVE_FOLDER=" .env; then
    if [ -z "$GDRIVE_FOLDER" ]; then
        sed -i "s|^GDRIVE_FOLDER=.*|GDRIVE_FOLDER=|" .env
    else
        sed -i "s|^GDRIVE_FOLDER=.*|GDRIVE_FOLDER=\"${GDRIVE_FOLDER}\"|" .env
    fi
else
    if [ -z "$GDRIVE_FOLDER" ]; then
        echo "GDRIVE_FOLDER=" >> .env
    else
        echo "GDRIVE_FOLDER=\"${GDRIVE_FOLDER}\"" >> .env
    fi
fi

if grep -q "^GDRIVE_REMOTE_NAME=" .env; then
    sed -i "s|^GDRIVE_REMOTE_NAME=.*|GDRIVE_REMOTE_NAME=\"${REMOTE_NAME}\"|" .env
else
    echo "GDRIVE_REMOTE_NAME=\"${REMOTE_NAME}\"" >> .env
fi

echo ""
echo -e "${GREEN}✓ .envファイル更新完了${NC}"

echo ""
echo "=========================================="
echo "動作確認"
echo "=========================================="

echo "Google Drive接続テスト..."
if rclone lsd "${REMOTE_NAME}:" &> /dev/null; then
    echo -e "${GREEN}✓ Google Driveに接続できました${NC}"
else
    echo -e "${RED}✗ Google Driveに接続できません${NC}"
    exit 1
fi

echo ""
echo "【設定内容】"
echo "  リモート名: ${REMOTE_NAME}"
if [ -z "$GDRIVE_FOLDER" ]; then
    echo "  保存先: マイドライブ/backups/ (デフォルト)"
else
    echo "  保存先: マイドライブ/${GDRIVE_FOLDER}/"
fi
echo ""

echo "=========================================="
echo "✓ セットアップ完了！"
echo "=========================================="
echo ""
echo "【次のステップ】"
echo "バックアップを実行してください:"
echo "  bash scripts/backup.sh"
echo ""
echo "自動バックアップを設定する場合:"
echo "  bash scripts/backup.sh --setup"
echo ""
echo "【確認コマンド】"
echo "Google Driveの内容を確認:"
if [ -z "$GDRIVE_FOLDER" ]; then
    echo "  rclone ls ${REMOTE_NAME}:backups/"
else
    echo "  rclone ls ${REMOTE_NAME}:${GDRIVE_FOLDER}/"
fi
echo ""

# ================================================
# セキュリティ設定
# ================================================
echo "=========================================="
echo "セキュリティ設定"
echo "=========================================="
echo ""

# rclone.confの保護
RCLONE_CONF="/root/.config/rclone/rclone.conf"
if [ -f "$RCLONE_CONF" ]; then
    chmod 600 "$RCLONE_CONF"
    echo -e "${GREEN}✓ rclone.conf権限設定完了 (600)${NC}"
    echo "  理由: Google Drive認証トークン含むためroot以外アクセス不可"
else
    echo -e "${YELLOW}⚠ rclone.confが見つかりません${NC}"
    echo "  場所: $RCLONE_CONF"
fi

echo ""
echo "=========================================="