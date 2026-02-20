<?php get_header(); ?>
    
    <!-- コンテンツ -->
    <main id="post-page" class="content flex flex-col min-h-screen items-center overflow-hidden w-full px-[28px] py-[110px] sm:p-[140px]">
        <?php
            // 現在のカテゴリー情報を取得
            $categories = get_the_category();
            $category_name = !empty($categories) 
                ? $category_name = esc_html($categories[0]->name)
                : $category_name = 'Uncategorised'; 
        ?>
        <!-- 見出し -->
        <h1 class="w-full text-start text-3xl sm:text-6xl max-w-5xl"><?php echo $category_name; ?></h1>

        <!-- カテゴリフィルターボタン -->
        <?php get_template_part('template-parts/category-buttons'); ?>
        <div class="w-full max-w-5xl">

            <div class="w-full text-[#555] my-[48px]">
            <?php if (have_posts()) : while (have_posts()) : the_post(); ?>
                <div class="article-container bg-white p-4 w-full">
                    <!-- 記事のheader部分 -->
                    <div class="article-header font-bold"> 
                        <h2 class="text-lg mb-1"><?php the_title(); ?></h2>
                        <div class="flex items-center pb-2 mb-6 border-b border-solid border-black">
                            <!-- 投稿日 -->
                            <div class=""><?php echo get_the_date('Y.m.d'); ?></div>
                            <!-- カテゴリーボタン -->
                            <div class="flex ml-2 overflow-hidden">
                                <?php $categories = get_the_category();
                                if (!empty($categories)) {
                                    foreach($categories as $category) {
                                        echo '<a href="' . esc_url(get_term_link($category)) . '" class="luxury-btn-mini">' . esc_html($category->name) . '</a>';
                                    }
                                } ?>
                            </div>
                        </div>
                    </div>

                    <!-- アイキャッチ画像（設定されている場合） -->
                    <?php if (has_post_thumbnail()) : ?>
                        <div class="article-thumbnail mb-4">
                            <?php the_post_thumbnail('large', [
                                'class' => 'w-full h-auto object-cover',
                                'alt' => 'article-img',
                            ]); ?>
                        </div>
                    <?php endif; ?>

                    <!-- 記事本文 -->
                    <div class="article-content text-sm">
                        <?php the_content(); ?>
                    </div>
                </div>
            <?php endwhile; else : ?>
                <!-- 記事が見つからない場合 -->
                <div class="no-posts bg-white p-4">
                    <h2 class="text-lg mb-4">記事が見つかりません</h2>
                    <p>申し訳ありませんが、お探しの記事は見つかりませんでした。</p>
                </div>
            <?php endif; ?>
        </div>
    </div>
        <?php get_template_part('template-parts/to-top-button'); ?>
    </main>
<?php get_footer(); ?>
