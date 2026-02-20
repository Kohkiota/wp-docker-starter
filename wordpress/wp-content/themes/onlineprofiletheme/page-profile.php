<?php get_header(); ?>
<!-- shortcode nums: text 1, img 1 -->

    <!-- コンテンツ -->
    <main id="profile-page" class="content flex flex-col items-center min-h-screen overflow-hidden w-full px-[28px] py-[110px] sm:px-[48px] md:px-[70px] md:py-[140px]">
        <h1 class="w-full text-start text-4xl sm:text-6xl">PROFILE</h1>
        <!-- プロフィール情報 -->
        <div class="profile flex max-w-7xl justify-center w-full text-[#555] mt-[48px] sm:mt-[80px]">
            <!-- プロフィール部分 -->
            <div class="flex flex-col md:flex-row items-start gap-[32px]">
                <!-- プロフィール画像 -->
                <div class="prfimg-container flex items-center w-full min-w-[180px] px-14 mb-0 sm:px-0 sm:my-8">
                    <!-- カスタム画像 -->
                    <?php $img = get_field('img1'); ?>
                    <img src="<?php echo esc_url($img['url']); ?>" alt="<?php echo esc_attr($img['alt']); ?>" class="object-cover">
                </div>
                <!-- プロフィール文章 -->
                <div class="w-full px-[12px] pt-8 sm:pt-0 flex flex-col justify-start">
                    <p class="flex flex-col justify-center text-6xl tracking-[8px] whitespace-nowrap">上田 遥</p>
                    <p class="text-2xl tracking-[2px] mt-6">Haruka Ueda</p>
                    <div class="tracking-wider text-lg mt-10">
                        <!-- カスタム文章 -->
                        <?php the_field('text1'); ?>
                    </div>
                </div>
            </div>
        </div>
        <div class="mt-16">
            <?php get_template_part('template-parts/to-top-button'); ?>
        </div>
    </main>

<?php get_footer(); ?>
