<dl class="block py-3 pb-6 border-b border-black">
    <!-- 日付、カテゴリ -->
    <dt class="flex items-center font-bold mb-2">
        <!-- 日付 -->
        <?php echo '<div class="text-lg">' . get_the_date('Y.m.d') . '</div>'; ?>
        <!-- カテゴリアイコン -->
        <div class="flex ml-2 overflow-hidden">
            <?php $categories = get_the_category();
            if (!empty($categories)) {
                foreach($categories as $category) {
                    echo '<a href="' . esc_url(get_term_link($category)) . '" class="luxury-btn-mini">' . esc_html($category->name) . '</a>';
                }
            } ?> 
        </div>
    </dt>
    <!-- 記事内容 -->
    <a href="<?php the_permalink(); ?>">
        <dd>
            <div class="line-clamp-1 sm:line-clamp-2 text-lg font-bold mb-[6px]"><?php the_title(); ?></div>
            <div class="line-clamp-2 sm:line-clamp-3 text-sm leading-4"><?php echo wp_trim_words(get_the_content(), 300, '...'); ?></div>
            <!-- <div class="flex justify-end">
                <span class="text-xs text-accent leading-4">...続きはこちら</span>
            </div> -->
        </dd>
    </a>
</dl>