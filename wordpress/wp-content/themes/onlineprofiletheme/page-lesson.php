<?php get_header(); ?>
<!-- shortcode nums: text 10, img 4 -->
    <!-- コンテンツ -->
    <main id="lesson-page" class="content flex flex-col items-center w-full text-[#555]">
        <h1 class="w-full text-start text-4xl sm:text-6xl pt-[110px] sm:pt-[140px] px-[28px] sm:px-[140px]">LESSON</h1>

        <!-- レッスンイメージ、ポリシー -->
        <div class="flex flex-cols items-center lesson-policy w-full my-[70px] px-[36px] sm:px-[70px] max-w-7xl">
            <div class="flex flex-col sm:flex-row">
                <!-- レッスンページ画像 -->
                <div class="lessonimg-container w-full p-8 flex justify-center">
                    <?php $img = get_field('img1'); ?>
                    <img src="<?php echo esc_url($img['url']); ?>" alt="<?php echo esc_attr($img['alt']); ?>" class="object-cover">
                </div>
                <!-- レッスンページロゴ画像 -->
                <div class="lessonimg-container2 w-full py-10 flex flex-col justify-center items-center">
                    <a href="https://music-urara.com/" class="flex justify-center items-center">
                        <?php $img = get_field('img2'); ?>
                        <img src="<?php echo esc_url($img['url']); ?>" alt="<?php echo esc_attr($img['alt']); ?>" class="w-36">
                    </a>
                    <p class="pt-4 text-xs">※音楽教室についてはこちら</p>
                </div>
            </div>
        </div>

        <!-- レッスンポリシー -->
        <div class="bg-little-gr px-[28px] py-[70px] sm:p-[110px] max-w-7xl">
            <h1 class="w-full text-center text-5xl">Lesson Policy</h1>
            <div class="lesson-policy-container mt-12">
                <div class="tracking-wider border-2 border-dashed border-main1 p-6 text-sm">
                    <!-- カスタム文章(設定なければデフォルト) -->
                    <?php the_field('text1') ?>
                </div>
            </div>
        </div>

        <!-- レッスン条件 -->
        <div class="lesson-price px-[28px] py-[70px] sm:p-[110px] w-full max-w-7xl">
            <h1 class="w-full text-center text-5xl">Lesson Price</h1>
            <!-- 料金 -->
            <div class="lessonprice-container">
                <div class="mt-8">
                    <p class="pl-4 sm:pl-8 pb-3 mb-4 text-2xl border-b border-main1 border-dashed">レッスン形態</p>
                    <p class="pl-4 sm:pl-8 pb-3">オンラインレッスン、対面(一部条件あり)</p>
                </div>
                <div class="mt-8">
                    <p class="pl-4 sm:pl-8 pb-3 mb-4 text-2xl border-b border-main1 border-dashed">料金</p>
                    <div class="pl-8 space-y-3">
                        <?php 
                        the_field('text2');
                        the_field('text3');
                        the_field('text4');
                        ?>
                    </div>
                    <!-- <p class="pl-4 sm:pl-8 pb-3">ワンレッスン ／ 5000円</p>
                    <p class="pl-4 sm:pl-8 pb-3">体験レッスン ／ 無料</p>
                    <p class="pl-4 sm:pl-8 pb-3">　※現在体験レッスンは高校生以下限定とさせていただいております。</p> -->
                    <div class="mt-8 flex flex-col items-center">
                        <a href="<?php echo esc_url( get_permalink( get_page_by_path('contact') ) ); ?>" class="inline-block luxury-btn">レッスン申し込みはこちら</a>
                    </div>
                </div>
            </div>
        </div>

        <!-- レビュー -->
        <div class="reveiws-container flex flex-col items-center w-full px-[28px] py-[70px] md:p-[110px] max-w-7xl bg-little-gr">
            <h1 class="w-full text-start text-5xl">Reviews</h1>

            <!-- 口コミ -->
            <div class="review-container flex flex-col gap-8 justify-center w-full my-16 sm:px-8">

                <div class="flex flex-col lg:flex-row items-center w-full p-3 sm:p-6 border border-accent tracking-wider nice-shadow">
                    <div class="flex flex-col flex-shrink-0 w-full lg:w-[320px]">
                        <?php $img = get_field('img3'); ?>
                        <img src="<?php echo esc_url($img['url']); ?>" alt="<?php echo esc_attr($img['alt']); ?>" class="w-full">

                        <!-- <p class="pt-4 pb-3 text-xl border-b-2 border-main2">K.S.くん｜小学１年生</p> -->
                        <div id="review1-name" class="pt-8 pb-3 border-b-[3px] border-main2"><?php the_field('text5'); ?></div>
                        <div class="block h-[3px] w-[43%] relative bottom-[3px] bg-accent"></div>
                    </div>
                        
                    <div class="lg:ml-8 mt-8 lg:mt-0 flex flex-col items-start">
                        <div id="review1-title"><?php the_field('text6'); ?></div>
                        <div id="review1-text" class="mt-8"><?php the_field('text7'); ?></div>
                    </div>
                </div>

                <div class="flex flex-col lg:flex-row items-center w-full p-3 sm:p-6 border border-accent tracking-wider nice-shadow">
                    <div class="flex flex-col flex-shrink-0 w-full lg:w-[320px]">
                        <?php $img = get_field('img4'); ?>
                        <img src="<?php echo esc_url($img['url']); ?>" alt="<?php echo esc_attr($img['alt']); ?>" class="w-full">

                        <!-- <p class="pt-4 pb-3 text-xl border-b-2 border-main2">M.N.さん｜大人の生徒様</p> -->
                        <div id="review2-name" class="pt-8 pb-3 border-b-[3px] border-main2"><?php the_field('text8'); ?></div>
                        <div class="block h-[3px] w-[43%] relative bottom-[3px] bg-main1"></div>
                    </div>

                    <div class="lg:ml-8 mt-8 lg:mt-0 flex flex-col items-start">
                        <div id="review2-title"><?php the_field('text9'); ?></div>
                        <div id="review2-text" class="mt-8"><?php the_field('text10'); ?></div>
                    </div>
                </div>
            </div>
        </div>
        <div class="my-16">
            <?php get_template_part('template-parts/to-top-button'); ?>
        </div>
    </main>

<?php get_footer(); ?>
