<?php get_header(); ?>
<!-- shortcode nums: media 5 -->

    <!-- コンテンツ -->
    <main id="gallery-page" class="content w-full flex flex-col items-center overflow-hidden">
        <h1 class="w-full pt-[110px] sm:pt-[140px] px-[24px] sm:px-[140px] text-start text-4xl sm:text-6xl">Gallery</h1>

        <!-- Youtube動画ギャラリー -->
        <div class="youtube w-full max-w-5xl px-[28px] py-[70px] sm:p-[70px]">
            <h1 class="w-full text-center text-5xl">Youtube</h1>
            <!-- モバイル１，640px以上２列表示、最下行で余ったら左右中央揃えになる動画ギャラリースペース -->
            <div class="youtube-container flex flex-wrap justify-center gap-5 mt-12">
                <div class="aspect-video h-full w-full sm:w-[calc(50%-10px)] for-youtube-iframe"><?php the_field('oembed1'); ?></div>
                <div class="aspect-video h-full w-full sm:w-[calc(50%-10px)] for-youtube-iframe"><?php the_field('oembed2'); ?></div>
            </div>

            <!-- 登録ボタン -->
            <div class="mt-16 flex flex-col sm:flex-row items-center justify-center gap-8">
                <!-- youtubeメンバー登録ボタン -->
                <a class="w-[200px] luxury-btn" href="https://www.youtube.com/channel/UCRYAOInuvek3RWgA2aSZQ0g/join">メンバー登録</a>
                <!-- mymusicsheetリンクボタン -->
                <a class="w-[200px] luxury-btn" href="https://m.mymusicsheet.com/ja/haruchanpiano">遥の楽譜</a>
            </div>
        </div>

        <!-- インスタグラム -->
        <div class="Instagram w-full max-w-5xl px-[28px] py-[70px] sm:p-[70px]">
            <h1 class="w-full text-center text-5xl">Instagram</h1>

            <!-- モバイル１，640px以上２列表示、1024px以上で3列表示、最下行で余ったら左右中央揃えになる動画ギャラリースペース -->
            <div class="instagram-container flex flex-wrap justify-center gap-5 mt-12">
                <div><?php the_field('oembed3'); ?></div>
                <div><?php the_field('oembed4'); ?></div>
            </div>
        </div>

        <!-- Tiktok -->
        <div class="tiktok w-full max-w-5xl px-[28px] py-[70px] sm:p-[70px]">
            <h1 class="w-full text-center text-5xl">Tiktok</h1>

            <!-- モバイル１，640px以上２列表示、1024px以上で3列表示、最下行で余ったら左右中央揃えになる動画ギャラリースペース -->
            <div class="tiktok-container flex flex-wrap justify-center gap-5 mt-12">
                <div class="w-[326px]"><?php the_field('oembed5'); ?></div>
            </div>
            <?php get_template_part('template-parts/to-top-button'); ?>
        </div>
    </main>
<?php get_footer(); ?>
