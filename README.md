# WordPress Docker 開発・デプロイ基盤 — GitHub Actions CI/CD・全自動初期化・インフラ自動構築

ローカル開発と本番サーバーの両対応。GitHub Actions CI/CD で本番へ自動反映。

```bash
# ローカル開発
make dev                          # 開発環境を起動

# テーマ更新 → 本番反映
make sync                         # ビルド + テーマ同期
git add . && git commit && git push origin main
# → GitHub Actions が自動でビルド・デプロイ

# 本番初回セットアップ（サーバー上で実行）
sudo bash init.sh example.com    # ホスト設定（TLS / GDrive / バックアップ / 権限）
docker compose up -d              # サイト起動
```

`init.sh` はサーバー側の設定をすべて一括で行うスクリプト。`scripts/` 配下を順に実行する。

### ハイライト

- **CI/CD** — GitHub Actions でイメージビルド・Docker Hub プッシュ・本番サーバーデプロイを自動化
- **全自動初期化** — `docker compose up -d` で空のコンテナからサイト完成状態まで人手ゼロで構築
- **インフラ一括構築** — `init.sh` で TLS 取得・Google Drive 認証・バックアップ自動化・権限設定を一発完了

---

## 技術スタック

```
MySQL 8.0 → WordPress 6.8.2 (PHP 8.2 FPM) → Nginx 1.28
開発: Node.js 20 (Tailwind + Sass + BrowserSync)
CI/CD: GitHub Actions → Docker Hub → 本番サーバー(SSH)
```

| コンテナ  | イメージ                              |
| --------- | ------------------------------------- |
| MySQL     | mysql:8.0                             |
| WordPress | wordpress:6.8.2-php8.2-fpm (カスタム) |
| Nginx     | nginx:1.28-bookworm                   |
| Node      | node:20-alpine (dev profile)          |

本番構成:

```
HTTPS:443 → ホストNginx (Let's Encrypt) → :8080 → Docker Nginx → WordPress + MySQL
対応OS: Ubuntu 22.04/24.04 LTS, Amazon Linux 2023
```

---

## CI/CD

### 概要

main への push をトリガーに、GitHub Actions がイメージビルド → Docker Hub プッシュ → 本番サーバーへの SSH デプロイを自動実行する。

```
make sync → git push origin main
    ↓
GitHub Actions:
  1. リポジトリ取得
  2. Docker Hub ログイン
  3. イメージビルド & プッシュ
    ↓
本番サーバーにSSH接続:
  4. git pull
  5. Docker Hub ログイン
  6. docker pull
  7. docker compose up -d
  8. entrypoint がテーマをボリュームに同期
```

### ビルドの流れ

ローカル開発では `data/`（バインドマウント）上で編集するが、`data/` は Git 管理外。push 前に `make sync` を実行すると、Node コンテナで Tailwind / SCSS をビルドした上で `data/` → `wordpress/` に rsync される。GitHub Actions は `wordpress/` ディレクトリをコンテキストとして Docker イメージをビルドし、Docker Hub にプッシュする。

### テーマ同期の仕組み

本番はネームドボリュームを使っているため、イメージを更新しても既存ボリュームには自動反映されない（初回作成時のみコピーされる Docker の仕様）。これを解決するため、`custom-entrypoint.sh` でコンテナ起動のたびにイメージ内のテーマをボリュームに上書きコピーしている。WordPress 公式イメージが `/usr/src/wordpress` → `/var/www/html` にコピーするのと同じパターン。uploads/ はテーマディレクトリの外にあるため影響しない。

この仕組みにより、本番デプロイは `init.sh` → `docker compose up -d` だけで完了し、以降のテーマ更新は CI/CD で自動反映される。

### GitHub Secrets

| Secret名             | 内容                                     |
| -------------------- | ---------------------------------------- |
| `DOCKERHUB_USERNAME` | Docker Hub ユーザー名                    |
| `DOCKERHUB_TOKEN`    | Docker Hub アクセストークン              |
| `IMAGE_TAG`          | docker-compose.yml の image タグ部分     |
| `VPS_HOST`           | 本番サーバーの IPアドレス                |
| `VPS_USER`           | SSH接続ユーザー名                        |
| `VPS_SSH_KEY`        | GitHub Actions 用 SSH 秘密鍵の全文       |
| `VPS_PROJECT_PATH`   | 本番サーバー上のプロジェクトディレクトリ |

### deploy.yml（SSH ステップ）

本番サーバーでの `docker pull` にはDocker Hub 認証が必要。GitHub Actions のランナーでのログインとは別に、SSH 先の本番サーバー上でもログインが必要。

```yaml
script: |
  cd ${{ secrets.VPS_PROJECT_PATH }}
  git pull origin main
  echo ${{ secrets.DOCKERHUB_TOKEN }} | docker login -u ${{ secrets.DOCKERHUB_USERNAME }} --password-stdin
  docker pull ${{ secrets.DOCKERHUB_USERNAME }}/wordpress:${{ secrets.IMAGE_TAG }}
  docker compose up -d
```

### 初回セットアップ

詳細は「本番サーバー初回セットアップ手順書（CI/CD 対応）」を参照。

---

## このリポジトリについて

### WordPress クラシックテーマの制約

本プロジェクトは WordPress のクラシックテーマに準拠している。クラシックテーマは CMS が指定するディレクトリに、指定されたファイル名で配置しないと動作しない仕組みで、コア（`wp-includes/`、`wp-admin/`）・プラグイン（`wp-content/plugins/`）・テーマ（`wp-content/themes/`）の配置パスは全て固定されている。Next.js や Laravel 等のように `apps/` ・ `apis/` でフロントエンド/バックエンドを自由に分ける構成は取れない。

### WordPress 本体と自作コードの境界

リポジトリ内の WordPress 本体のファイル（`wp-includes/`、`wp-admin/` 等）は、Next.js でいう `node_modules/` に相当する**変更不可のフレームワークコード**であり、自分が書いたコードではない。WordPress 同梱のデフォルトテーマ（`themes/twenty*/`）も `.gitignore` で除外している。

自分が設計・実装したコードは以下の場所に集中している。

| 場所                                              | 内容                                                                                |
| ------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `docker/`、`scripts/`、`init.sh`、`Makefile`      | インフラ・自動化                                                                    |
| `wordpress/wp-content/themes/onlineprofiletheme/` | カスタムテーマ（テンプレート・CSS・JS・ACF(Advanced Custom Fields) フィールド定義） |
| `wordpress/wp-content/mu-plugins/`                | 自作の WordPress 拡張                                                               |
| `.github/workflows/deploy.yml`                    | CI/CD                                                                               |

### 独自コードの一覧

WordPress が提供するコア・プラグインを除き、自分が設計・実装したファイルと機能は以下の通り。

**① CI/CD パイプライン & 本番インフラ自動構築**

GitHub Actions による CI/CD（イメージビルド → Docker Hub → SSH デプロイ）と、`init.sh` による本番インフラ一括構築（TLS 自動取得・GDrive 認証・バックアップ自動化）。詳細は「CI/CD」「スクリプト一覧」セクションを参照。

**② `docker compose up -d` 一発で動く WordPress 全自動初期化**

`custom-entrypoint.sh` → `wp-init.sh` → `import-acf-json.php` の 3 ファイル連携で、コアインストールからテーマ有効化・プラグイン設定・固定ページ作成・ACF フィールドインポートまで 9 工程を自動実行。ACF の JSON 定義内ではページ ID をプレースホルダーで記述し、固定ページ作成後に `sed` で実 ID に動的置換することで、環境ごとの ID 差異を吸収する。詳細は「起動フロー」セクションを参照。

**③ 本番/開発環境の切り替え設計**

`docker-compose.yml`（本番: named volume）をベースに `docker-compose.dev.yml`（開発: bind mount + Node.js コンテナ）がマージで上書きする構成。開発環境では Node.js コンテナが Tailwind CSS + SCSS + BrowserSync でホットリロード開発を提供し、Docker Compose の profiles 機能で必要な時だけ起動する。

**④ クライアント向けコンテンツ管理システム（`functions.php`）**

WordPress 管理画面にカスタムメタボックスを追加し、画像・リッチテキスト・埋め込みコードを動的ショートコードで管理。設定数の増減に応じて post_meta を自動クリーンアップする仕組みを自作している。

**⑤ その他**

BrowserSync の canonical redirect 問題を解決する mu-plugin（`disable-bs-canonical.php`）、ACF Local JSON の保存先制御（`acf-json.php`）、テンプレート階層に準拠したページテンプレート群、Tailwind CSS + SCSS のデュアルビルド構成など。

---

## プロジェクト構成

`★` = 自作コード　｜　無印 = WordPress 本体・サードパーティプラグイン・自動生成ファイル

```
project/                                    # 権限
├── .github/
│   └── workflows/
│       └── deploy.yml                    ★ # CI/CD ワークフロー（GitHub Actions）
├── docker-compose.yml                    ★ # 644  本番用（named volume）
├── docker-compose.dev.yml                ★ # 644  開発用差分（bind mount に上書き + Node追加）
├── Dockerfile                            ★ # 644
├── .env.example                          ★ # 600
├── docker/                               ★ # 755  Docker関連スクリプト
│   ├── custom-entrypoint.sh              ★ # 755  起動・初期化制御（テーマ同期含む）
│   ├── wp-init.sh                        ★ # 755  WP-CLI 初期化
│   ├── import-acf-json.php               ★ # 644  ACF JSON → DB インポート
│   └── nginx/
│       ├── default.conf                  ★ # 644  コンテナ内 Nginx（本番用）
│       └── dev.conf                      ★ # 644  コンテナ内 Nginx（開発用・CORS有効）
├── init.sh                               ★ # 700  本番統合セットアップ
├── Makefile                              ★ # 644  開発 & CI/CD 用コマンド
│
├── scripts/                              ★ # 700  管理スクリプト（root権限）
│   ├── host-nginx.sh                     ★ # 700  ホストOS の Nginx + TLS 設定
│   ├── setup-gdrive.sh                   ★ # 700  Google Drive 認証
│   ├── backup.sh                         ★ # 700  バックアップ
│   └── restore.sh                        ★ # 700  復元
│
└── wordpress/                              # 755  Docker イメージビルド用
    └── wp-content/                         # 755
        ├── themes/onlineprofiletheme/    ★ # 755  カスタムテーマ（全て自作）
        │   ├── acf-json/                 ★ # ACF フィールド定義 JSON
        │   ├── template-parts/
        │   │   └── cf7-form.html         ★ # CF7 フォームテンプレート
        │   ├── assets/
        │   │   ├── scss/main.scss        ★ # ← 編集対象（SCSS）
        │   │   ├── css/input.css         ★ # ← 編集対象（Tailwind 入力）
        │   │   ├── css/main.css            # SCSS → 自動生成（Git管理対象）
        │   │   ├── css/output.css          # Tailwind → 自動生成（Git管理対象）
        │   │   └── images/                 # 初期画像素材
        │   ├── package.json              ★ # Tailwind + SCSS ビルド設定
        │   └── tailwind.config.js        ★
        ├── plugins/                        # 755  サードパーティプラグイン（バージョン固定）
        ├── languages/                      # 755
        └── mu-plugins/                   ★ # 755
            ├── acf-json.php              ★ # ACF Local JSON 保存先をテーマの acf-json/ に指定
            └── disable-bs-canonical.php  ★ # BrowserSync 開発用（後述）
```

※ `host-nginx.sh` はホスト OS 上の Nginx（リバースプロキシ + TLS）を設定するスクリプト。`docker/nginx/default.conf` は Docker コンテナ内の Nginx 設定ファイル。別物なので混同注意。

⚠ **ビルド済みCSS（`output.css`、`main.css`）は `.gitignore` に含めないこと。** これらがGit管理外だとイメージに焼かれず、CI/CD で本番に反映されない。

### wordpress/ 配下を Git 管理している理由

WordPress 公式 Docker イメージ（`wordpress:6.8.2-php8.2-fpm`）は、起動時に `docker-entrypoint.sh` がイメージ内の WordPress 全体を `/var/www/html` にコピーする仕様で、特定のディレクトリだけを選択的にコピーする機能がない。テーマやプラグインだけを分離してイメージに含める構成は公式イメージの設計上想定されていないため、`wordpress/` 配下ごとビルドコンテキストに含めている。

また、WordPress はプラグインのマイナーアップデート 1 つでサイトが動作しなくなるケースがあり、多数のクライアント案件を運用する想定ではプラグインのバージョン固定は必須になっている。wordpress.org からプラグインが削除される事例も実際にあるため、`wp plugin install --version=x.x.x` によるスクリプト取得ではなく、検証済みのバージョンをリポジトリに含めてイメージに焼き込むことで、外部依存なしに再現可能なデプロイを保証している。

### docker-compose 構成

本番用 `docker-compose.yml` をベースに、開発用 `docker-compose.dev.yml` が差分を上書きするマージ方式。

| ファイル                 | 役割                                            |
| ------------------------ | ----------------------------------------------- |
| `docker-compose.yml`     | 本番構成（named volume、mysql/wordpress/nginx） |
| `docker-compose.dev.yml` | 開発差分（bind mount に上書き + Node コンテナ） |

### ボリューム設計

WordPress と Nginx は `/var/www/html` 全体を同一ボリュームで共有している。

「本番は named volume で `/var/www/html` 全体を永続化し、テーマだけ bind mount で開発編集する」という構成も検討したが、以下の 2 つの独立した問題により採用しなかった。

**UID/GID の不一致** — named volume と bind mount を同一コンテナ内で混在させると、ファイル所有者が異なる（named volume 側: www-data UID 33 / bind mount 側: ホストユーザー UID 1000）。www-data が bind mount 側に書き込めない、ホストユーザーが named volume 側を編集できない、といった権限エラーが発生する。

**マウントポイントの可視性** — 親子関係でマウントを重ねると（親: named volume、子: bind mount）、Linux の VFS（仮想ファイルシステム）レイヤーでマウントポイントが上書きされ、マウント順序や entrypoint のファイルコピータイミングによって子ディレクトリの内容が親に隠される、またはコピー対象から外れるといった不整合が起きる（参考: docker/compose#7196）。Docker Compose の volumes 定義順でも結果が変わるため、安定した運用が困難だった。

これらを回避するため、開発環境では `/var/www/html` ごと bind mount に切り替えている（`docker-compose.dev.yml`）。本番環境では named volume のみを使用し、マウントの混在を避けている。

ネームドボリュームはイメージ更新を自動反映しない（最初のコンテナ作成時のみコピーされる）。このため `custom-entrypoint.sh` でコンテナ起動のたびにイメージ内のテーマをボリュームにコピーしている。WordPress 公式イメージの `/usr/src/wordpress` → `/var/www/html` コピーと同じパターン。

### Nginx 二段構成

本番環境ではホストNginxとDockerコンテナ内Nginxの二段構成をとっている。

```
クライアント → ホストNginx(:443 TLS終端) → Docker Nginx(:8080) → WordPress(php-fpm)
```

ホストNginx: TLS終端（Let's Encrypt）、HTTP→HTTPSリダイレクト、Basic認証。
Docker Nginx: php-fpm へのリバースプロキシ、静的ファイル配信。

TLS をホスト側に置く理由は3つ。

証明書がコンテナのライフサイクルから独立する。`/etc/letsencrypt/` に保存されるため `docker compose down` やイメージリビルドで消失せず、certbot の自動更新もホスト上で完結する。

証明書の取得・更新に HTTP-01 チャレンジを使っている。DNS-01 は DNS プロバイダごとに API 仕様が異なり、仕様変更やトークン切れの管理コストが案件数に比例して増える。HTTP-01 ならポート 80 で静的ファイルを返すだけで、どのプロバイダでも同一手順で済む。Cloudflare プロキシモード併用時は Cache Rules と WAF 除外で ACME チャレンジを通す。

`host-nginx.sh` と `docker/nginx/*.conf` の責務が明確に分かれる。ホスト側は TLS とアクセス制御、コンテナ側は php-fpm プロキシと静的配信のみ。

---

## 環境切替チェックリスト

環境を切り替える際に変更が必要なファイル:

**`.env`** — `WP_HOME` / `WP_SITEURL`（開発: `http://localhost:8080`、本番: `https://ドメイン`）、パスワード類、`WORDPRESS_TABLE_PREFIX`

**`scripts/host-nginx.sh`** — Cloudflare 使用時のヘッダー切替

---

## ローカル開発

### 起動

```bash
# 1. 環境変数（WP_HOME=http://localhost:8080 に設定）
cp .env.example .env && vi .env

# 2. 起動（data/ の初期化は init-data で自動実行）
make dev

# 3. アクセス
#    通常:          http://localhost:8080
#    ホットリロード:  http://localhost:3000
#    管理画面:       http://localhost:8080/wp-admin

# 4. 停止
make down

# 5. 停止 + ボリューム削除（DBリセット）
make down-v
```

`.env` はローカル開発なら基本 `WP_HOME=http://localhost:8080` にするだけ。パスワード類はデフォルトのままで問題ない。

### Makefile コマンド一覧

| コマンド         | 用途                                                                         |
| ---------------- | ---------------------------------------------------------------------------- |
| `make dev`       | 開発環境起動（`init-data` で data/backups/ を自動作成）                      |
| `make down`      | 停止                                                                         |
| `make down-v`    | 停止 + ボリューム削除                                                        |
| `make logs`      | ログ表示                                                                     |
| `make build`     | イメージビルド（キャッシュなし）。ローカルのイメージを最新にしたい場合に使用 |
| `make init-data` | data/ backups/ の作成と権限設定                                              |
| `make fix-perms` | wp-content のパーミッション修正（775/664）                                   |
| `make sync`      | npm run build + テーマを wordpress/ にrsync（push前に実行）                  |

### バインドマウント権限・編集準備

```bash
# 初回のみ: www-data グループに参加 → ターミナル再起動
sudo usermod -aG www-data "$USER"
```

`make dev` 実行時に `init-data` が自動で data/ と backups/ を作成・権限設定する。手動での `mkdir` や `chown` は不要。

`data/` 配下のパーミッションが壊れた場合（VSCode で直接編集した後など）:

```bash
make fix-perms
```

### ビルド

node コンテナ内で `npm run dev` が自動実行される。手動ビルド:

```bash
docker exec wp-node npm run build
```

`tailwind.config.js` の `content` に注意。`"./**/*.html"` のような広すぎるパターンは node_modules を含みメモリ不足で落ちる。

### BrowserSync canonical redirect 対策

BrowserSync（`localhost:3000`）経由のアクセスでは、WordPress の canonical redirect が HTTP_HOST の不一致（`nginx` vs `localhost:8080`）により `nginx:8080` へリダイレクトしてしまう。`mu-plugins/disable-bs-canonical.php` は、BrowserSync → nginx コンテナ経由のリクエストに限り canonical redirect を無効化する開発専用 mu-plugin。本番環境では条件に合致しないため悪影響なし（放置可）。

---

## 起動フロー（custom-entrypoint.sh / wp-init.sh）

```
MySQL 起動 → healthcheck 成功
  → WordPress 起動 → custom-entrypoint.sh
    → PHP 設定生成
    → 公式 entrypoint 起動（php-fpm）
    → wp-config.php 待機
    → テーマ同期（イメージ → ボリューム、毎回実行）
    → MySQL 接続確認
    → wp core is-installed で初回判定
      → 未インストール: wp-init.sh 実行
      → インストール済み: スキップ
    → パーミッション設定（初回のみ）
    → php-fpm 維持
```

### wp-init.sh の処理内容

1. `wp core install`（日本語化・タイムゾーン・パーマリンク設定）
2. デフォルトコンテンツ削除（Hello World 等）
3. テーマ有効化
4. プラグイン一括有効化
5. Contact Form 7 テンプレート更新（`cf7-form.html` から読み込み）
6. 固定ページ作成（各ページ公開状態で作成、ページ ID 確定）
7. カテゴリ・サンプル投稿作成
8. 表示設定（ホームページ / 投稿ページ割当）
9. ACF フィールドインポート（JSON → DB）+ 初期値設定

---

## Advanced Custom Fields(ACF) 運用

### 関連ファイル

| ファイル                  | 役割                                                     |
| ------------------------- | -------------------------------------------------------- |
| `acf-json/*.json`         | フィールドグループ定義（テーマ内に配置）                 |
| `mu-plugins/acf-json.php` | ACF Local JSON の保存先パスをテーマの `acf-json/` に指定 |
| `import-acf-json.php`     | `wp-init.sh` から呼ばれ、JSON → DB にインポート          |
| `wp-init.sh`              | ページ作成 → ID 置換 → インポート → 初期値設定           |

### 初期化フロー

```
wp-init.sh → 固定ページ作成（ID 確定）
  → acf-json/*.json 内の ___PAGE_ID_XXX___ を実 ID に sed 置換
  → import-acf-json.php 実行（JSON → DB 登録）
  → update_field() で画像・oEmbed・テキスト等の初期値設定
```

### 命名規則

| 対象           | 規則                                | 例                |
| -------------- | ----------------------------------- | ----------------- |
| グループキー   | `group_{ページ名}`                  | `group_home`      |
| フィールドキー | `field_{グループ名}_{フィールド名}` | `field_home_img1` |
| フィールド名   | `{フィールド名}`                    | `img1`            |

### キーと名前の使い分け

| 場面                     | 使うもの           | 例                                     |
| ------------------------ | ------------------ | -------------------------------------- |
| JSON 定義                | フィールド**キー** | `"key": "field_home_img1"`             |
| wp-init.sh（値の設定）   | フィールド**キー** | `update_field('field_home_img1', ...)` |
| テンプレート（値の取得） | フィールド**名**   | `get_field('img1')`                    |

---

## WP テンプレート構成

| ページ         | WP ファイル      | 固定ページスラッグ | 備考                         |
| -------------- | ---------------- | ------------------ | ---------------------------- |
| トップ         | front-page.php   | home               | 表示設定でホームページに割当 |
| プロフィール   | page-profile.php | profile            |                              |
| レッスン       | page-lesson.php  | lesson             |                              |
| ギャラリー     | page-gallery.php | gallery            |                              |
| お問い合わせ   | page-contact.php | contact            |                              |
| 送信完了       | page-thanks.php  | thanks             |                              |
| 404            | 404.php          | —                  |                              |
| フォールバック | index.php        | —                  |                              |
| 投稿一覧       | home.php         | blog               | 表示設定で投稿ページに割当   |
| カテゴリ別     | category.php     | {category-slug}    |                              |

表示設定で「ホームページ = home」「投稿ページ = blog」を割当。テンプレート階層を利用しているため、固定ページのスラッグとファイル名の一致は不要。

### リンク生成

固定ページ: `get_permalink(get_page_by_path('profile'))`、トップ: `home_url('/')`、投稿一覧: `get_permalink(get_option('page_for_posts'))`、カテゴリ: `get_term_link('concert', 'category')`

---

## 案件別カスタマイズ箇所

**Contact Form 7** — `template-parts/cf7-form.html` を編集。`wp-init.sh` で自動読み込み・登録される。テンプレート側の ID タグ編集忘れに注意。

**ACF フィールド** — `acf-json/*.json` を編集。保存先は `mu-plugins/acf-json.php` で指定。

**ACF 初期値** — フィールド定義に対応する初期データ（テキスト・画像・oEmbed URL 等）は `wp-init.sh` 内の `update_field()` で流し込む。案件ごとにフィールド定義と初期値のセットを `wp-init.sh` に記述しておけば、`docker compose up -d` だけでコンテンツ込みの初期状態が再現される。

---

## 本番デプロイ

概要のみ記載。詳細手順は「本番サーバー初回セットアップ手順書（CI/CD 対応）」を参照。

### やること

1. `.env` を本番用に設定（ドメイン・強固なパスワード）
2. サーバー初期設定（Docker インストール、デプロイキー設定、リポジトリ配置）
3. 本番サーバーで Docker Hub にログイン（プライベートリポジトリからの pull に必要）
4. `docker compose up -d` で環境起動（本番用 `docker-compose.yml` のみ使用）
5. `sudo bash init.sh example.com` でホスト側の統合セットアップ（TLS / GDrive / バックアップ自動化 / 権限設定）
6. 手動セキュリティ対策（必須）:
   - SSH 鍵認証の有効化 + パスワード認証の無効化（`/etc/ssh/sshd_config`）
   - fail2ban のインストールと設定（SSH / HTTP の不正アクセス防止）
   - ファイアウォール設定（必要ポートのみ開放: 22, 80, 443）
   - OS 自動セキュリティアップデートの有効化（Ubuntu: unattended-upgrades / Amazon Linux: dnf-automatic）
   - root ログインの無効化
7. GitHub Secrets 登録 & CI/CD 動作確認

---

## スクリプト一覧

### init.sh — 本番統合セットアップ

```bash
sudo bash init.sh example.com
```

`host-nginx.sh` → `setup-gdrive.sh` → `backup.sh --setup` → 権限設定を順に実行。本番デプロイ時に一度だけ使う。

### host-nginx.sh — ホスト Nginx + TLS

```bash
# ドメイン指定: Nginx + Certbot + リバースプロキシ + Basic認証
sudo bash scripts/host-nginx.sh example.com

# ドメインなし: Basic認証ユーザーの追加/削除のみ
sudo bash scripts/host-nginx.sh
```

Ubuntu / Amazon Linux 2023 を自動判定。Let's Encrypt 証明書取得・自動更新設定を含む。

### setup-gdrive.sh — Google Drive 認証

```bash
sudo bash scripts/setup-gdrive.sh
```

rclone を自動インストールし、expect で自動入力。ユーザー操作は URL クリック + 認証コード貼り付けのみ。

### backup.sh — バックアップ

```bash
# 初回: 定期実行設定（対話式で頻度選択 → crontab 登録）
sudo bash scripts/backup.sh --setup

# 2回目以降 / cron用: バックアップのみ実行
sudo bash scripts/backup.sh
```

処理内容: mysqldump（`--single-transaction`）+ wp-content 圧縮 + `.env` 保存 → ローカル `backups/` + Google Drive にアップロード。30日以上前のバックアップは自動削除。

```bash
# 確認
ls -lh backups/
sudo rclone ls gdrive:backups/
sudo crontab -l

# 定期実行の解除
sudo crontab -l | grep -v "backup.sh" | sudo crontab -
```

### restore.sh — バックアップ復元

```bash
sudo bash scripts/restore.sh
```

対話式で実行:

1. バックアップ一覧表示（日時・サイズ）
2. 復元するバックアップを番号で選択
3. 復元モード選択（完全復元: .env + data + MySQL / 部分復元: .env + data のみ）
4. 確認プロンプト → 復元実行（Docker 停止 → data 削除 → 復元 → Docker 起動 → SQL インポート）

**注意**: 完全復元を選ぶと、現在の `.env` がバックアップ時点のものに上書きされます。本番環境で開発用バックアップを復元すると `WP_HOME` などが開発設定に戻るため、復元後に `.env` の内容を必ず確認してください。

---

## トラブルシューティング

| 症状                   | 原因                                 | 対処                                              |
| ---------------------- | ------------------------------------ | ------------------------------------------------- |
| WP が起動しない        | MySQL 未起動 / 接続エラー            | `docker compose logs -f`                          |
| バックアップが動かない | crontab 未設定 / 権限不足            | `sudo crontab -l`                                 |
| GDrive 未アップロード  | rclone 未認証                        | `sudo rclone listremotes`                         |
| ACF フィールド非表示   | パス設定ミス / ページ ID 不一致      | `acf-json.php` のパス確認                         |
| oEmbed が文字列表示    | フィールド名で設定してしまった       | フィールドキーで `update_field`                   |
| 証明書取得失敗         | DNS 未設定 / ポート 80 閉鎖          | DNS・セキュリティグループ確認                     |
| テーマが更新されない   | `output.css` が .gitignore 内        | .gitignore からビルド済みCSSを除外                |
| テーマが更新されない   | entrypoint にテーマ同期がない        | custom-entrypoint.sh の [3/7] を確認              |
| テーマが更新されない   | Cloudflareキャッシュ                 | CF ダッシュボード → Caching → 構成 → 全てをパージ |
| docker pull 失敗       | 本番サーバーで Docker Hub 未ログイン | 本番サーバー上で `docker login` を実行            |
| CI/CD で pull 失敗     | deploy.yml に docker login なし      | SSH ステップに docker login 追加                  |

```bash
# よく使うコマンド
docker compose logs -f wordpress
docker compose restart
docker compose down && docker compose up -d
sudo bash scripts/setup-gdrive.sh   # GDrive 再認証
docker compose exec mysql mysql -u root -p
```

---