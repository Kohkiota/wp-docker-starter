<?php
    // home.php, category.phpのみでの使用を想定
    // 変数を初期化
    $current_category_id = is_category() ? get_queried_object_id() : 0 ;
    $cat_btn_class = 'luxury-btn-category-mini';
?>

<!-- カテゴリフィルターボタン -->
<div class="category-filter px-[32px] mt-[40px] mb-[30px] sm:mt-[80px] sm:mb-[40px] flex flex-wrap gap-2 justify-center">
    
    <!-- ALLボタン -->
    <?php 
        $page_for_posts_id = get_option('page_for_posts');
        $all_btn_class = (!is_category()) 
            ? 'luxury-btn-category-mini--active' 
            : '';

        echo '<a href="' . esc_url(get_permalink( $page_for_posts_id )) . '" class="' . $cat_btn_class . ' ' . $all_btn_class . '">';
        echo esc_html(get_the_title( $page_for_posts_id )) . '</a>';
    ?>
    
    <?php
        // 全カテゴリボタン
        $categories = get_categories(array(
            'hide_empty' => false,
            'orderby' => 'name',
            'order' => 'ASC'
        ));
        
        foreach($categories as $category) {
            // アクティブかどうかを判定
            $is_active = (is_category() && $current_category_id === $category->term_id);
            $other_btn_class = $is_active 
                ? 'luxury-btn-category-mini--active' 
                : '';
            
            echo '<a href="' . esc_url(get_term_link($category)) . '" class="' . $cat_btn_class . ' ' . $other_btn_class . '">' . esc_html($category->name) . '</a>';
        }
    ?>
</div>