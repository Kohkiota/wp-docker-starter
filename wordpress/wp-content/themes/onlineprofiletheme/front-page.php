<?php get_header(); ?>
<!-- shortcode nums: text 9, img 11, media 1 -->

    <main id="front-page" class="content w-full flex flex-col items-center overflow-hidden bg-base">
        <!-- スライドショーコンテナ -->
        <div id="slideshow-container">
            <div class="slide active">
                <?php $pc = get_field('img1'); $sp = get_field('img5'); ?>
                <picture>
                    <source media="(max-width: 639px)" srcset="<?php echo esc_url($sp['url']); ?>">
                    <img src="<?php echo esc_url($pc['url']); ?>" alt="<?php echo esc_attr($pc['alt']); ?>">
                </picture>
            </div>

            <div class="slide">
                <?php $pc = get_field('img2'); $sp = get_field('img6'); ?>
                <picture>
                    <source media="(max-width: 639px)" srcset="<?php echo esc_url($sp['url']); ?>">
                    <img src="<?php echo esc_url($pc['url']); ?>" alt="<?php echo esc_attr($pc['alt']); ?>">
                </picture>
            </div>

            <div class="slide">
                <?php $pc = get_field('img3'); $sp = get_field('img7'); ?>
                <picture>
                    <source media="(max-width: 639px)" srcset="<?php echo esc_url($sp['url']); ?>">
                    <img src="<?php echo esc_url($pc['url']); ?>" alt="<?php echo esc_attr($pc['alt']); ?>">
                </picture>
            </div>

            <div class="slide">
                <?php $pc = get_field('img4'); $sp = get_field('img8'); ?>
                <picture>
                    <source media="(max-width: 639px)" srcset="<?php echo esc_url($sp['url']); ?>">
                    <img src="<?php echo esc_url($pc['url']); ?>" alt="<?php echo esc_attr($pc['alt']); ?>">
                </picture>
            </div>
            <!-- スクロールアニメーション -->
            <div id="scroll-anime-wrapper" class="flex flex-col items-center absolute bottom-0 z-10 text-base bg-red">
                <p class="text-lg">scroll</p>
                <div id="scroll-anime">
                    <div id="scroll-anime-base"></div>
                    <div id="scroll-anime-top"></div>
                </div>
            </div>
        </div>
        
        <!-- ニュース -->
        <div class="news flex flex-col px-[28px] py-[48px] sm:p-[140px] w-full max-w-7xl scroll-fade-in">
            <h1 class="text-3xl sm:text-5xl">NEWS</h1>
            <div class="flex sm:justify-between py-8 h-full">
                <div class="hidden sm:flex relative w-[32px] justify-end">
                    <!-- 字 -->
                    <span class="-rotate-90 origin-top-right text-sm tracking-widest absolute top-0 right-6 whitespace-nowrap">All updates...</span>
                    <!-- 線 -->
                    <div class="w-px bg-black h-full inset-0"></div>
                </div>
                <div class="news-list w-full sm:ml-16 max-w-3xl text-[#555] sm:items-end">
                    <?php
                    // ニュースカテゴリー記事用サブクエリ
                    $news_query = new WP_Query([
                    'post_type' => 'post',
                    'post_status' => 'pub lish',
                    'category_name' => 'news',
                    'posts_per_page' => 3,
                    ]);
                    if ($news_query->have_posts()) : while ($news_query->have_posts()) : $news_query->the_post();
                    get_template_part('template-parts/post-thumbnail');
                    endwhile;
                    wp_reset_postdata();
                    endif;
                    ?>
                </div>
            </div>
            <div class="flex flex-col items-end">
                <a id="viewmore-btn" href="<?php echo esc_url( get_permalink( get_option('page_for_posts') ) ); ?>">
                    <p class="text-lg sm:text-xl font-bold text-accent">view more</p>
                    <span class="flex items-center relative justify-end">
                        <span class="block w-[72px] sm:w-[80px] h-[2px] bg-accent"></span>
                        <div id="viewmore-btn-ball" class="block w-2 h-2 rounded-full bg-accent"></div>
                    </span>
                </a>
            </div>
        </div>

        <!-- 動画 -->
        <div class="videos flex flex-col px-[40px] sm:px-[40px] md:px-[80px] lg:px-[140px] py-[48px] sm:py-[70px] w-full max-w-7xl bg-little-gr scroll-fade-in">
            <div class="flex justify-end w-full">
                <h1 class="text-3xl sm:text-5xl">VIDEOS</h1>
            </div>
            <div class="flex sm:justify-between w-full py-8">
                <div class="relative w-full max-w-[720px]">
                    <div class="items-center aspect-video for-youtube-iframe relative z-10"><?php the_field('oembed1'); ?></div>
                    <div class="bg-accent aspect-video absolute inset-0 translate-x-3 translate-y-3 sm:translate-x-8 sm:translate-y-8 bg-gradient-to-b from-[#ffffff] to-[#dac7de]"></div>
                </div>
                <div class="hidden sm:flex w-[170px] flex-shrink-0 ml-12">
                    <div class="flex relative w-[32px] justify-end">
                        <!-- 字 -->
                        <span class="-rotate-90 origin-top-right text-sm tracking-widest absolute top-0 right-6 whitespace-nowrap">Watch more...</span>
                        <!-- 線 -->
                        <div class="w-px bg-black h-full inset-0"></div>
                    </div>
                </div>
            </div>

            <div class="flex flex-col items-end mt-8">
                <a id="viewmore-btn" href="<?php echo esc_url( get_permalink( get_page_by_path('gallery') ) ); ?>">
                    <p class="text-lg sm:text-xl font-bold text-accent">view more</p>
                    <span class="flex items-center relative justify-end">
                        <span class="block w-[72px] sm:w-[80px] h-[2px] bg-accent"></span>
                        <div id="viewmore-btn-ball" class="block w-2 h-2 rounded-full bg-accent"></div>
                    </span>
                </a>
            </div>
        </div>

        <!-- コンサート情報 -->
        <div class="concert flex flex-col px-[28px] py-[48px] sm:p-[140px] w-full max-w-7xl scroll-fade-in">
            <h1 class="text-3xl sm:text-5xl">CONCERT</h1>
            <div class="flex sm:justify-between py-8 h-full">
                <div class="hidden sm:flex relative w-[32px] justify-end">
                    <!-- 字 -->
                    <span class="-rotate-90 origin-top-right text-sm tracking-widest absolute top-0 right-6 whitespace-nowrap">Concert informations...</span>
                    <!-- 線 -->
                    <div class="w-px bg-black h-full inset-0"></div>
                </div>
                <div class="news-list w-full sm:ml-16 max-w-3xl text-[#555] sm:items-end">
                    <?php
                        // コンサート情報カテゴリー記事用サブクエリ
                        $concert_query = new WP_Query([
                            'post_type' => 'post',
                            'post_status' => 'publish',
                            'category_name' => 'concert',
                            'posts_per_page' => 3,
                        ]);
                        if ($concert_query->have_posts()) : while ($concert_query->have_posts()) : $concert_query->the_post();
                            get_template_part('template-parts/post-thumbnail');
                        endwhile;
                            wp_reset_postdata();
                        endif;
                    ?>
                </div>
            </div>
            <div class="flex flex-col items-end">
                <a id="viewmore-btn" href="<?php echo esc_url( get_term_link( get_category_by_slug('concert') ) ); ?>">
                    <p class="text-lg sm:text-xl font-bold text-accent">view more</p>
                    <span class="flex items-center relative justify-end">
                        <span class="block w-[72px] sm:w-[80px] h-[2px] bg-accent"></span>
                        <div id="viewmore-btn-ball" class="block w-2 h-2 rounded-full bg-accent"></div>
                    </span>
                </a>
            </div>
        </div>

        <!-- メンバーシップ -->
        <div class="concert flex flex-col px-[28px] sm:px-[140px] py-[48px] sm:py-[70px] w-full max-w-7xl scroll-fade-in">
            <div class="flex justify-center w-full">
                <h1 class="text-3xl sm:text-5xl">MEMBERSHIP</h1>
            </div>
            <!-- メンバーシップのカードコンテナ -->
            <div class="w-full flex flex-wrap justify-center gap-8 mt-12 p-8 bg-little-gr">

                <!-- カード -->
                <a href="https://www.youtube.com/channel/UCRYAOInuvek3RWgA2aSZQ0g/join">
                    <div class="flex flex-col items-center p-2 w-[280px] aspect-[3/4] bg-base nice-shadow">
                        <div class="w-full aspect-video bg-purple-300">
                            <?php $img = get_field('img9'); ?>
                            <img src="<?php echo esc_url($img['url']); ?>" alt="<?php echo esc_attr($img['alt']); ?>" class="w-full">
                        </div>
                        <div class="p-2">
                            <div class="w-full text-2xl">
                                <?php the_field('text1'); ?>
                            </div>
                            <div class="w-full mt-4 text-xs">
                                <?php the_field('text2'); ?>
                            </div>
                        </div>
                        <div class="w-full flex justify-end mt-2">
                            <?php the_field('text3'); ?>
                        </div>
                    </div>
                </a>
                <!-- カード -->
                <a href="https://m.mymusicsheet.com/ja/haruchanpiano">
                    <div class="flex flex-col items-center p-2 w-[280px] aspect-[3/4] bg-base nice-shadow">
                        <div class="w-full aspect-video bg-purple-300">
                            <?php $img = get_field('img10'); ?>
                            <img src="<?php echo esc_url($img['url']); ?>" alt="<?php echo esc_attr($img['alt']); ?>" class="w-full">
                        </div>
                        <div class="p-2">
                            <div class="w-full text-2xl">
                                <?php the_field('text4'); ?>
                            </div>
                            <div class="w-full mt-4 text-xs">
                                <?php the_field('text5'); ?>
                            </div>
                        </div>
                        <div class="w-full flex justify-end mt-2">
                            <?php the_field('text6'); ?>
                        </div>
                    </div>
                </a>
                <!-- カード -->
                <a href="https://m.mymusicsheet.com/ja/haruchanpiano">
                    <div class="flex flex-col items-center p-2 w-[280px] aspect-[3/4] bg-base nice-shadow">
                        <div class="w-full aspect-video bg-purple-300">
                            <?php $img = get_field('img11'); ?>
                            <img src="<?php echo esc_url($img['url']); ?>" alt="<?php echo esc_attr($img['alt']); ?>" class="w-full">
                        </div>
                        <div class="p-2">
                            <div class="w-full text-2xl">
                                <?php the_field('text7'); ?>
                            </div>
                            <div class="w-full mt-4 text-xs">
                                <?php the_field('text8'); ?>
                            </div>
                        </div>
                        <div class="w-full flex justify-end mt-2">
                            <?php the_field('text9'); ?>
                        </div>
                    </div>
                </a>
            </div>
        </div>
    </main>
    
<?php get_footer(); ?>
