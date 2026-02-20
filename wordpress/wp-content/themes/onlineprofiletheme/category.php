<?php get_header(); ?>
    <!-- 見出しH2以外、category.phpとまったく同じソースコード -->
    <!-- コンテンツ -->
    <main id="category-page" class="content flex flex-col min-h-screen items-center overflow-hidden w-full px-[28px] py-[110px] sm:p-[140px]">  
        <?php
            // 現在のカテゴリー情報を取得
            $current_category = get_queried_object();
            $category_name = !empty($current_category->name) ? 
            $current_category->name : 'Uncategorised';
        ?>
        <!-- 見出し -->
        <h1 class="w-full text-start text-3xl sm:text-6xl max-w-5xl"><?php echo $category_name; ?></h1>

        <!-- カテゴリフィルターボタン -->
        <?php get_template_part('template-parts/category-buttons'); ?>
        <div class="w-full max-w-5xl">

            <!-- 記事一覧 -->
            <div class="w-full text-[#555]">
                <?php if (have_posts()) : while (have_posts()) : the_post(); 
                    get_template_part('template-parts/post-thumbnail'); 
                    endwhile; ?>
                    <!-- ペジネーション -->
                    <nav class="my-pagination-styles">
                        <?php 
                        echo paginate_links([
                            'prev_text' => '«',
                            'next_text' => '»',
                            'mid_size' => 2,
                        ]); 
                        ?>
                    </nav>
                <?php else : ?>
                    <div class="no-posts p-6 bg-white rounded shadow text-center">
                        <h2 class="text-lg mb-4">記事がありません</h2>
                        <p class="mb-4"><?php echo esc_html( $category_name ); ?>カテゴリーには、まだ記事が投稿されていません。</p>
                    </div>
                <?php endif; ?>
            </div>
        </div>
        <?php get_template_part('template-parts/to-top-button'); ?>
    </main>

<?php get_footer(); ?>