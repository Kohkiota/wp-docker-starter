<?php get_header(); ?>
    
    <!-- コンテンツ -->
    <main id="404-page" class="content flex flex-col flex-grow justify-center items-center px-[28px] sm:p-[140px]">
        <div class="thanks text-center flex flex-col items-center">
            <title>送信完了</title>
            <h1 class="text-3xl leading-[42px]">お探しのページが見つかりません</h1>
            <p>申し訳ございません。お探しのページは削除されたか、URLが変更された可能性があります。</p>
        </div>
        <?php get_template_part('template-parts/to-top-button'); ?>
    </main>

<?php get_footer(); ?>
