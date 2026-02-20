#!/bin/bash
set -e

# テーマ名設定（.env で必須指定）
if [ -z "${THEME_NAME:-}" ]; then
  echo "[wp-init] ERROR: THEME_NAME is not set. Please define THEME_NAME in .env." >&2
  exit 1
fi

echo "=========================================="
echo "WordPress Initialization Script"
echo "Theme: $THEME_NAME"
echo "=========================================="

# WordPress インストール
echo "[1/15] Installing WordPress..."
wp core install \
    --url="${WP_HOME}" \
    --title="Haruka Ueda Official Website" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email --allow-root --path=/var/www/html 2>/dev/null || echo "WordPress already installed"

echo "✓ WordPress installed!"

# WordPress日本語化
echo "[2/15] Installing Japanese language..."
wp core language install ja --allow-root --path=/var/www/html 2>/dev/null || true
wp site switch-language ja --allow-root --path=/var/www/html 2>/dev/null || true

# 一般設定
echo "[3/15] Configuring general settings..."
wp option update timezone_string 'Asia/Tokyo' --allow-root --path=/var/www/html
wp option update date_format 'Y.m.d' --allow-root --path=/var/www/html
wp option update time_format 'H:i' --allow-root --path=/var/www/html

# パーマリンク設定
echo "[4/15] Setting permalinks..."
wp rewrite structure '/%postname%/' --allow-root --path=/var/www/html 2>/dev/null || true
wp rewrite flush --allow-root --path=/var/www/html

# デフォルトコンテンツの削除
echo "[5/15] Deleting default content..."

# デフォルト投稿削除（Hello worldなど）
wp post delete $(wp post list --post_type=post --format=ids --allow-root --path=/var/www/html) --force --allow-root --path=/var/www/html 2>/dev/null || true

# デフォルト固定ページ削除（Sample Pageなど）
wp post delete $(wp post list --post_type=page --format=ids --allow-root --path=/var/www/html) --force --allow-root --path=/var/www/html 2>/dev/null || true

# デフォルトプラグイン削除（Akismet, Hello Dolly）
wp plugin delete akismet hello --allow-root --path=/var/www/html 2>/dev/null || true

echo "✓ Default content deleted!"

# テーマ有効化
echo "[6/15] Activating theme..."
wp theme activate $THEME_NAME --allow-root --path=/var/www/html 2>/dev/null || echo "Theme $THEME_NAME not found"

# プラグイン有効化
echo "[7/15] Activating plugins..."
PLUGINS=(
    "advanced-custom-fields"
    "tinymce-advanced"
    "classic-editor"
    "contact-form-7"
    "contact-form-cfdb7"
    "wp-multibyte-patch"
)

for plugin in "${PLUGINS[@]}"; do
    wp plugin activate "$plugin" --allow-root --path=/var/www/html 2>/dev/null || echo "Plugin $plugin not found"
done

echo "✓ Plugins activated!"

# Contact Form 7のフォームテンプレート更新
echo "[7.5/15] Updating Contact Form 7 template..."

CF7_TITLE=${CF7_TITLE}
FORM_HTML_FILE="/var/www/html/wp-content/themes/$THEME_NAME/template-parts/cf7-form.html"

if [ ! -f "$FORM_HTML_FILE" ]; then
  echo "⚠ Form HTML file not found: $FORM_HTML_FILE"
  exit 0
fi

# タイトル一致のフォームIDを探す（検索→完全一致で確定）
FORM_ID=""
CANDIDATE_IDS=$(wp post list \
  --post_type=wpcf7_contact_form \
  --search="$CF7_TITLE" \
  --field=ID \
  --allow-root --path=/var/www/html 2>/dev/null)

if [ -n "$CANDIDATE_IDS" ]; then
  for id in $CANDIDATE_IDS; do
    t=$(wp post get "$id" --field=post_title --allow-root --path=/var/www/html 2>/dev/null)
    if [ "$t" = "$CF7_TITLE" ]; then
      FORM_ID="$id"
      break
    fi
  done
fi

if [ -z "$FORM_ID" ]; then
  echo "⚠ Contact Form '$CF7_TITLE' not found"
  exit 0
fi

wp post meta update "$FORM_ID" _form "$(<"$FORM_HTML_FILE")" --allow-root --path=/var/www/html
echo "✓ Contact Form template updated (Title: $CF7_TITLE, ID: $FORM_ID)"


# 固定ページ作成（公開状態）
echo "[8/15] Creating pages..."
wp post create --post_type=page \
    --post_title='All' \
    --post_name='blog' \
    --post_status=publish --allow-root --path=/var/www/html 2>/dev/null || true

PAGE_ID=$(wp post create --post_type=page \
    --post_title='Contact' \
    --post_name='contact' \
    --post_status=publish --porcelain --allow-root --path=/var/www/html)
wp post meta update $PAGE_ID text1 "$(cat <<'EOF'
<p>当教室が運営するウェブサイトをご利用いただくお客様のプライバシー保護に取り組んでおります。当教室がサービスを提供するにあたり、お客様個人に関する情報（以下、「個人情報」といいます）を収集する必要がございますが、当教室ではその情報のプライバシーを保護し、秘密を保持するため様々な対策を実施しています。当教室は個人情報を売買・交換・その他の方法による不正使用を一切行いません。このウェブサイトをご利用になり、個人情報をご提供いただくことで、このプライバシーポリシーに記載されている個人情報の取り扱いについて同意いただいたものとみなされます。</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text2 "$(cat <<'EOF'
<p>お客様からご提供いただいた個人情報は、以下の目的で使用いたします。</p>
<ul class="list-disc list-inside">
    <li>当教室がお客様にご提供するサービスでの利用のため</li>
    <li>お客様に適したサービスや新商品などの情報を正確にお伝えするため</li>
    <li>必要に応じてお客様への連絡を行うため</li>
</ul>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text3 "$(cat <<'EOF'
<p>以下の場合には、お客様の事前承諾なく当教室はお客様の個人情報を開示することがあります。</p>
<ul class="list-disc list-inside">
    <li>警察や裁判所、その他政府機関から召喚状、令状、命令等により要求された場合</li>
    <li>人の生命、身体または財産の保護のため必要があり、お客様の同意を得ることが困難な場合</li>
</ul>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text4 "$(cat <<'EOF'
<p>お客様の個人情報は、当教室が適正な管理を実施するとともに、漏洩、滅失、毀損の防止のため最大限の注意を払っております。なお、当教室ではお客様により良いサービスをご提供するため、個人情報を適正に取り扱っていると認められる外部の委託業者に、個人情報取り扱いの一部を委託しております。委託業者は、委託業務を実施するために必要な範囲で個人情報を使用します。この場合、当教室は委託業者との間で個人情報の取り扱いについて適正な契約を締結し、適正な管理を求めております。</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text5 "$(cat <<'EOF'
<p>個人情報保護の重要性について、適時または定期的に適正な教育を実施しております。また、当教室が個人情報を管理する際は、管理責任者を設置し適正な管理を実施するとともに、外部への流出防止に取り組みます。さらに、外部からの不正アクセスや改ざん等の危険に対しては、適正かつ合理的な範囲の安全対策を講じ、お客様の個人情報保護に取り組みます。個人情報に関するデータベース等のアクセスについては、アクセス権限を有する者を限定し、社内においても不正な使用がなされないよう厳重に管理します。</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text6 "$(cat <<'EOF'
<p>リンク先での個人情報の使用については、当教室のプライバシーに関する考え方ではなく、リンク先サイト独自のプライバシーに関する考え方に基づいて実施されます。</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text7 "$(cat <<'EOF'
<p>当教室では、お客様にご提供するサービス向上のため、上記各項目の内容を適宜見直し、改善してまいります。本書を変更する際は、この変更についてウェブサイトに掲載いたします。最新のプライバシー・ステートメントをサイトに掲載することで、常にプライバシー情報の収集や使用方法をご確認いただけます。定期的にご確認いただきますようお願いいたします。また、当初情報が収集された時点で述べた内容と異なる方法で個人情報を使用する場合も、ウェブサイトに掲載してご連絡いたします。ウェブサイトが当初と異なる方法で個人情報を使用してよいかどうかについての選択権は、お客様にございます。</p>
EOF
)" --allow-root --path=/var/www/html

PAGE_ID=$(wp post create --post_type=page \
    --post_title='Gallery' \
    --post_name='gallery' \
    --post_status=publish --porcelain --allow-root --path=/var/www/html)
OEMBED1="https://www.youtube.com/watch?v=bh_4Q6tnHe4"
OEMBED2="https://www.youtube.com/watch?v=Zi7jQck7R_M"
OEMBED3="https://www.instagram.com/p/DJghOmGSl6c/?utm_source=ig_web_copy_link&igsh=ajhvZXQ0cmdpcHV6"
OEMBED4="https://www.instagram.com/p/DLe7SMPyVko/?utm_source=ig_web_copy_link&igsh=YW1icW11Njg0MWJ1"
OEMBED5="https://www.tiktok.com/@haruka._.piano/video/7313141640095403266?is_from_webapp=1&sender_device=pc&web_id=7527509523603670544"

wp eval "update_field('field_gallery_oembed1', '$OEMBED1', $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_gallery_oembed2', '$OEMBED2', $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_gallery_oembed3', '$OEMBED3', $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_gallery_oembed4', '$OEMBED4', $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_gallery_oembed5', '$OEMBED5', $PAGE_ID);" --allow-root --path=/var/www/html

PAGE_ID=$(wp post create --post_type=page \
    --post_title='Home' \
    --post_name='home' \
    --post_status=publish --porcelain --allow-root --path=/var/www/html)
wp post meta update $PAGE_ID text1 "$(cat <<'EOF'
<p>Youtube membership</br>「上田遥/Haruka」</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text2 "$(cat <<'EOF'
<p>メンバ限定の動画公開</p>
<p>メンバー限定のコミュニティ投稿</p>
<p>そのほかコミュニティについての内容</p>
<p>そのほかコミュニティについての内容</p>
<p>そのほかコミュニティについての内容</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text3 "$(cat <<'EOF'
<p>￥999/月</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text4 "$(cat <<'EOF'
<p>Youtube membership</br>「上田遥/Haruka」</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text5 "$(cat <<'EOF'
<p>メンバ限定の動画公開</p>
<p>メンバー限定のコミュニティ投稿</p>
<p>そのほかコミュニティについての内容</p>
<p>そのほかコミュニティについての内容</p>
<p>そのほかコミュニティについての内容</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text6 "$(cat <<'EOF'
<p>￥999/月</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text7 "$(cat <<'EOF'
<p>Youtube membership</br>「上田遥/Haruka」</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text8 "$(cat <<'EOF'
<p>メンバ限定の動画公開</p>
<p>メンバー限定のコミュニティ投稿</p>
<p>そのほかコミュニティについての内容</p>
<p>そのほかコミュニティについての内容</p>
<p>そのほかコミュニティについての内容</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text9 "$(cat <<'EOF'
<p>￥999/月</p>
EOF
)" --allow-root --path=/var/www/html

IMG1=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/slide1.jpg --porcelain --allow-root --path=/var/www/html)
IMG2=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/slide2.jpg --porcelain --allow-root --path=/var/www/html)
IMG3=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/slide3.jpg --porcelain --allow-root --path=/var/www/html)
IMG4=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/slide4.jpg --porcelain --allow-root --path=/var/www/html)
IMG5=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/slide-m1.png --porcelain --allow-root --path=/var/www/html)
IMG6=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/slide-m2.png --porcelain --allow-root --path=/var/www/html)
IMG7=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/slide-m3.png --porcelain --allow-root --path=/var/www/html)
IMG8=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/slide-m4.png --porcelain --allow-root --path=/var/www/html)
IMG9=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/membership1.png --porcelain --allow-root --path=/var/www/html)
IMG10=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/membership2.png --porcelain --allow-root --path=/var/www/html)
IMG11=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/membership2.png --porcelain --allow-root --path=/var/www/html)

wp eval "update_field('field_home_img1', $IMG1, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_home_img2', $IMG2, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_home_img3', $IMG3, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_home_img4', $IMG4, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_home_img5', $IMG5, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_home_img6', $IMG6, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_home_img7', $IMG7, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_home_img8', $IMG8, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_home_img9', $IMG9, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_home_img10', $IMG10, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_home_img11', $IMG11, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_home_oembed1', 'https://www.youtube.com/watch?v=aaIFexuTmP8', $PAGE_ID);" --allow-root --path=/var/www/html

PAGE_ID=$(wp post create --post_type=page \
    --post_title='Lesson' \
    --post_name='lesson' \
    --post_status=publish --porcelain --allow-root --path=/var/www/html)
wp post meta update $PAGE_ID text1 "$(cat <<'EOF'
<p>　お子さまから大人まで、一人ひとりの個性やペースを大切にしながら、「できた！」という喜びや、音で自分を表現する楽しさを味わってもらえるレッスンを心がけています。<br>　基礎を丁寧に身につけながら、好きな曲や憧れの曲にも積極的に挑戦。時にはゲームや工夫を取り入れながら、音楽との距離がぐっと縮まるような時間を一緒に作っていきます。<br><br>　レッスンを通して、技術だけでなく、自信や感性、人とのつながりも育んでいけたら──そんな思いで、いつも笑顔でお迎えしています。</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text2 "$(cat <<'EOF'
<p>ワンレッスン ／ 5000円</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text3 "$(cat <<'EOF'
<p>体験レッスン ／ 無料</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text4 "$(cat <<'EOF'
<p>　※現在体験レッスンは高校生以下限定とさせていただいております。</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text5 "$(cat <<'EOF'
<p>K.S.くん｜小学１年生</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text6 "$(cat <<'EOF'
<p>先生の明るいご指導で、自信がつきました！！</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text7 "$(cat <<'EOF'
<p>　こちらの教室に通い始めてから、子どもが「間違えること」を怖がらなくなりました。以前は注意されるとすぐに弾くのをやめてしまっていたのですが、遥先生はいつも明るく、間違えても笑って励ましてくれたり、前向きな声かけをしてくださるので、何事にも挑戦できるようになったと感じています。</p>
<p>　発表会でも自信を持ってステージに立つことができ、本人の弾きたい曲にチャレンジできたことも大きな達成感になったようです。</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text8 "$(cat <<'EOF'
<p>M.N.さん｜大人の生徒様</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text9 "$(cat <<'EOF'
<p>憧れの先生に、基礎から丁寧に指導してもらえます</p>
EOF
)" --allow-root --path=/var/www/html
wp post meta update $PAGE_ID text10 "$(cat <<'EOF'
<p>　子どもの頃に習っていたピアノを、はるか先生のYouTubeでの演奏に心を動かされて、もう一度始めたいと思い、再開しました。</p>
<p>　レッスンでは、基礎を大切にしながらも、弾きたい曲に向けて自分に合った最短ルートを一緒に考えてくださいます。単に弾けるようにするだけでなく、「どんな音を出すか」を丁寧に教えてくださり、自分では気づけなかった癖や長所を的確に見抜いてくれるのがすごいです！</p>
<p></p>
<p>　曲の構成や表現を一緒に分析・相談しながら仕上げていく過程もとても楽しく、知らなかった知識がどんどん増えて、ほかの曲にも応用できるのが嬉しいです。</p>
<p>　発表会など目標に向かって頑張る機会があることも、大人になった今、とても新鮮で充実しています。</p>
EOF
)" --allow-root --path=/var/www/html

IMG1=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/img7.jpg --porcelain --allow-root --path=/var/www/html)
IMG2=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/urara.png --porcelain --allow-root --path=/var/www/html)
IMG3=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/review1.jpg --porcelain --allow-root --path=/var/www/html)
IMG4=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/review2.jpg --porcelain --allow-root --path=/var/www/html)

wp eval "update_field('field_lesson_img1', $IMG1, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_lesson_img2', $IMG2, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_lesson_img3', $IMG3, $PAGE_ID);" --allow-root --path=/var/www/html
wp eval "update_field('field_lesson_img4', $IMG4, $PAGE_ID);" --allow-root --path=/var/www/html

PAGE_ID=$(wp post create --post_type=page \
    --post_title='Profile' \
    --post_name='profile' \
    --post_status=publish --porcelain --allow-root --path=/var/www/html)

wp post meta update $PAGE_ID text1 "$(cat <<'EOF'
<div>　埼玉県川越市出身。6歳からピアノを始め、大宮光陵高校音楽科を経て東京音楽大学ピアノ科を卒業。</div>
<div>　現在は、ソロやデュオでのコンサート開催や企業イベントでの演奏を中心に、演奏活動を幅広く行っているほか、自身のピアノ教室で子どもから大人までのレッスンも行っている。</div>
<div> </div>
<div>　自身のYouTubeチャンネル｢上田遥/Haruka｣ピアノちゃんねるでは、チャンネル登録者数約5万人。クラシックを中心に、ジブリやJ-POP、K-POPなどジャンルを超えて幅広く演奏し「心に届く音」を大切にしながら、音楽の魅力を発信している。そのほかのSNSも含めた総フォロワー数は50万人以上。</div>
EOF
)" --allow-root --path=/var/www/html

IMG1=$(wp media import /var/www/html/wp-content/themes/onlineprofiletheme/assets/images/img6.jpg --porcelain --allow-root --path=/var/www/html)

wp eval "update_field('field_profile_img1', $IMG1, $PAGE_ID);" --allow-root --path=/var/www/html

wp post create --post_type=page \
    --post_title='Thanks' \
    --post_name='thanks' \
    --post_status=publish --allow-root --path=/var/www/html 2>/dev/null || true

echo "✓ Pages created!"

# ACF JSON内のページIDプレースホルダーを実際のIDで置換
echo "[8.5/15] Updating ACF JSON with actual page IDs..."

# ページリスト定義（案件ごとに変更）
PAGES="contact gallery home lesson profile"

# ループでID取得と置換
for page in $PAGES; do
    PAGE_ID=$(wp post list --post_type=page --name=$page --field=ID --allow-root --path=/var/www/html 2>/dev/null || echo "0")
    PAGE_UPPER=$(echo "$page" | tr '[:lower:]' '[:upper:]')
    sed -i "s/___PAGE_ID_${PAGE_UPPER}___/$PAGE_ID/g" /var/www/html/wp-content/themes/$THEME_NAME/acf-json/group_$page.json
    echo "  → $page: ID=$PAGE_ID"
done

# JSONを再度DBにインポート（ページIDが正しく設定された状態で）
wp eval-file /var/www/html/import-acf-json.php --allow-root --path=/var/www/html 2>&1 || echo "ACF re-import failed"

echo "✓ ACF JSON updated with page IDs!"

# カテゴリ作成
echo "[9/15] Creating categories..."
if ! wp term list category --field=name --allow-root --path=/var/www/html | grep -q "^News$"; then
    wp term create category 'News' --allow-root --path=/var/www/html
fi
if ! wp term list category --field=name --allow-root --path=/var/www/html | grep -q "^Concert$"; then
    wp term create category 'Concert' --allow-root --path=/var/www/html
fi

echo "✓ Categories created!"

# カテゴリIDを取得
NEWS_CAT_ID=$(wp term list category --field=term_id --name='News' --allow-root --path=/var/www/html 2>/dev/null || echo "")
CONCERT_CAT_ID=$(wp term list category --field=term_id --name='Concert' --allow-root --path=/var/www/html 2>/dev/null || echo "")
UNCAT_ID=$(wp term list category --field=term_id --name='Uncategorized' --allow-root --path=/var/www/html 2>/dev/null || echo "1")

# サンプル投稿作成（Newsカテゴリ：3件）
echo "[10/15] Creating News posts..."
if [ ! -z "$NEWS_CAT_ID" ]; then
    for i in {1..3}; do
        wp post create \
            --post_title="News Sample ${i}" \
            --post_content="これはNewsカテゴリのサンプル投稿${i}です。" \
            --post_category=$NEWS_CAT_ID \
            --post_status=publish \
            --allow-root \
            --path=/var/www/html 2>/dev/null || true
    done
fi

# サンプル投稿作成（Concertカテゴリ：3件）
echo "[11/15] Creating Concert posts..."
if [ ! -z "$CONCERT_CAT_ID" ]; then
    for i in {1..3}; do
        wp post create \
            --post_title="Concert Sample ${i}" \
            --post_content="これはConcertカテゴリのサンプル投稿${i}です。" \
            --post_category=$CONCERT_CAT_ID \
            --post_status=publish \
            --allow-root \
            --path=/var/www/html 2>/dev/null || true
    done
fi

# サンプル投稿作成（未分類：3件）
echo "[12/15] Creating Uncategorized posts..."
if [ ! -z "$UNCAT_ID" ]; then
    for i in {1..3}; do
        wp post create \
            --post_title="Uncategorized Sample ${i}" \
            --post_content="これは未分類のサンプル投稿${i}です。" \
            --post_category=$UNCAT_ID \
            --post_status=publish \
            --allow-root \
            --path=/var/www/html 2>/dev/null || true
    done
fi

echo "✓ Sample posts created!"

# 表示設定
echo "[13/15] Configuring display settings..."

# ホームページIDを取得
HOME_PAGE_ID=$(wp post list --post_type=page --name=home --field=ID --allow-root --path=/var/www/html 2>/dev/null || echo "")
BLOG_PAGE_ID=$(wp post list --post_type=page --name=blog --field=ID --allow-root --path=/var/www/html 2>/dev/null || echo "")

if [ ! -z "$HOME_PAGE_ID" ] && [ ! -z "$BLOG_PAGE_ID" ]; then
    wp option update show_on_front 'page' --allow-root --path=/var/www/html
    wp option update page_on_front $HOME_PAGE_ID --allow-root --path=/var/www/html
    wp option update page_for_posts $BLOG_PAGE_ID --allow-root --path=/var/www/html
    echo "✓ Homepage set to 'home', blog page set to 'All'"
fi

# フィード設定
wp option update rss_use_excerpt 1 --allow-root --path=/var/www/html
# 検索エンジンブロック設定
wp option update blog_public 0 --allow-root --path=/var/www/html

echo "✓ Display settings configured!"

# ディスカッション設定
echo "[14/15] Configuring discussion settings..."
wp option update default_pingback_flag 0 --allow-root --path=/var/www/html
wp option update default_ping_status 'closed' --allow-root --path=/var/www/html
wp option update default_comment_status 'closed' --allow-root --path=/var/www/html

echo "✓ Discussion settings configured!"

# ユーザー設定（管理バーを無効化）
echo "[15/15] Configuring user settings..."
ADMIN_USER_ID=$(wp user get "${WP_ADMIN_USER}" --field=ID --allow-root --path=/var/www/html 2>/dev/null || echo "")
if [ ! -z "$ADMIN_USER_ID" ]; then
    wp user meta update $ADMIN_USER_ID show_admin_bar_front false --allow-root --path=/var/www/html
    echo "✓ Admin toolbar disabled for ${WP_ADMIN_USER}"
fi

echo "=========================================="
echo "✓ WordPress initialization completed!"
echo "=========================================="