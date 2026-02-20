<?php get_header(); ?>
<!-- shortcode nums: text 7 -->
    <!-- コンテンツ -->
    <main id="contact-page" class="content w-full flex flex-col items-center overflow-hidden py-[110px] px-[24px] md:p-[140px]">
        <h1 class="w-full text-start text-4xl sm:text-6xl max-w-5xl">CONTACT</h1>
        <!-- コンタクトフォーム -->
        <div class="contactform px-8 w-full max-w-5xl">
            <div class="annotation w-full my-16 flex flex-col items-center">
                <div class="flex flex-col items-center text-center">
                    <a href="https://music-urara.com/flow/" class="luxury-btn">♪うらら音楽教室♪</a>
                </div>
                <div class="text-center mt-8">
                    <p class="text-xl whitespace-nowrap">👆👆高校生以下はこちら！👆👆</p>
                    <p class="text-xs mt-4 px-4">※ご好評につき、無料体験レッスンは現在</p>
                    <p class="text-xs mt-1 px-2 text-center"><span class="font-bold underline">高校生以下のみ</span>となっております。</p>
                </div>
            </div>

            <!-- フォーム埋込部分 -->
            <?php echo apply_shortcodes('[contact-form-7 title="Contact form 1" html_id="cf7-form" html_class="form w-full flex flex-col items-center"]') ?>
            
            <!-- プライバシーポリシー -->
            <div class="privacy p-4 flex flex-col items-center w-full">
                <div class="privacy-box h-60 sm:h-40 w-full max-w-md p-6 text-xs bg-white border border-accent overflow-y-scroll resize-y">
                    <div class="mb-4 relative">
                        <span class="block h-7 w-[4px] bg-accent absolute"></span>
                        <div class="ml-2 text-lg font-bold">プライバシーポリシーについて</div>
                    </div>
                    <?php echo the_field('text1'); ?>
                    <div class="my-4 relative">
                        <span class="block h-7 w-[4px] bg-accent absolute"></span>
                        <div class="ml-2 text-lg font-bold">個人情報収集の目的</div>
                    </div>
                    <?php echo the_field('text2'); ?>
                    <div class="my-4 relative">
                        <span class="block h-7 w-[4px] bg-accent absolute"></span>
                        <div class="ml-2 text-lg font-bold">個人情報の開示について</div>
                    </div>
                    <?php echo the_field('text3'); ?>
                    <div class="my-4 relative">
                        <span class="block h-7 w-[4px] bg-accent absolute"></span>
                        <div class="ml-2 text-lg font-bold">個人情報の管理体制</div>
                    </div>
                    <?php echo the_field('text4'); ?>
                    <div class="my-4 relative">
                        <span class="block h-7 w-[4px] bg-accent absolute"></span>
                        <div class="ml-2 text-lg font-bold">従業員の監督体制</div>
                    </div>
                    <?php echo the_field('text5'); ?>                        
                    <div class="my-4 relative">
                        <span class="block h-7 w-[4px] bg-accent absolute"></span>
                        <div class="ml-2 text-lg font-bold">リンク先について</div>
                    </div>
                    <?php echo the_field('text6'); ?>
                    <div class="my-4 relative">
                        <span class="block h-7 w-[4px] bg-accent absolute"></span>
                        <div class="ml-2 text-lg font-bold">プライバシーポリシーの改訂について</div>
                    </div>
                    <?php echo the_field('text7'); ?>
                </div>
            </div>
        </div>
        <div class="my-16">
            <?php get_template_part('template-parts/to-top-button'); ?>
        </div>
    </main>
<?php get_footer(); ?>
