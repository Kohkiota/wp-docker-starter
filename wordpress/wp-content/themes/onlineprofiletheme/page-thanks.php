<?php get_header(); ?>
    
    <!-- コンテンツ -->
    <main id="thanks-page" class="content flex flex-col min-h-screen mt-16 lg:mt-24 py-36">
        <div class="thanks flex-1 mt-20 mb-7 px-7 text-center flex flex-col items-center">
            <title>送信完了</title>
            <h1 class="text-3xl leading-[42px]">お問い合わせありがとうございました♪</h1>
            
            <div class="mt-24">
                <?php get_template_part('template-parts/to-top-button'); ?>
            </div>
        </div>
    </main>

<?php get_footer(); ?>
