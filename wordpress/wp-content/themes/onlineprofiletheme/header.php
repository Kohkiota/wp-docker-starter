<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <?php wp_head(); ?>

</head>
<body class="bg-base flex flex-col min-h-screen">
    <?php wp_body_open(); ?>

    <!-- ロゴから画面遷移 -->
    <div id="loading">
        <div id="shutter-top"></div>
        <div id="shutter-bottom"></div>
        <div id="opening-text" class="text-2xl sm:text-5xl">
            <span>H</span>
            <span>A</span>
            <span>R</span>
            <span>U</span>
            <span>K</span>
            <span>A</span>
            <span>&nbsp;</span>
            <span>U</span>
            <span>E</span>
            <span>D</span>
            <span>A</span>
        </div>
    </div>

    <!-- sm用ヘッダー -->
    <header>
        <a id="header-title-wrapper" class="inline-block" href="<?php echo esc_url( home_url('/')); ?>">
            <h1 id="header-title">
                <p class="title1">HARUKA UEDA</p>
                <p class="title2">OFFICIAL WEBSITE</p>
            </h1>
        </a>
    </header>

    <!-- 開閉トグルボタン -->
    <button id="menu-toggle-btn" class="btn-menu outline-none border-none" aria-label="メニューを開く">
        <span class="btn-menu__line btn-menu__line--1"></span>
        <span class="btn-menu__line btn-menu__line--2"></span>
        <span class="btn-menu__line btn-menu__line--3"></span>
    </button> 

    <!-- スライドメニューパネル -->
    <div id="menu-panel" class="w-full h-full bg-white bg-opacity-90 py-[120px]flex flex-col">
        <ul class="list-none text-center mt-16">
            <a class="no-underline text-2xl" href="<?php echo esc_url( home_url('/')); ?>"><li class="fade-in hover:bg-base py-2 sm:py-4">Home</li></a>
            <a class="no-underline text-2xl" href="<?php echo esc_url( get_permalink( get_option('page_for_posts'))); ?>"><li class="fade-in hover:bg-base py-2 sm:py-4">News</li></a>
            <a class="no-underline text-2xl" href="<?php echo esc_url( get_term_link('concert', 'category')); ?>"><li class="fade-in hover:bg-base py-2 sm:py-4">Concert</li></a>
            <a class="no-underline text-2xl" href="<?php echo esc_url( get_permalink( get_page_by_path('profile') ) ); ?>"><li class="fade-in hover:bg-base py-2 sm:py-4">Profile</li></a>
            <a class="no-underline text-2xl" href="<?php echo esc_url( get_permalink( get_page_by_path('lesson') ) ); ?>"><li class="fade-in hover:bg-base py-2 sm:py-4">Lesson</li></a>
            <a class="no-underline text-2xl" href="<?php echo esc_url( get_permalink( get_page_by_path('gallery') ) ); ?>"><li class="fade-in hover:bg-base py-2 sm:py-4">Gallery</li></a>
            <a class="no-underline text-2xl" href="<?php echo esc_url( get_permalink( get_page_by_path('contact') ) ); ?>"><li class="fade-in hover:bg-base py-2 sm:py-4">Contact</li></a>
        </ul>
        <div class="justify-center mt-8 sm:mt-16 text-2xl">
            <p class="fade-in text-center">Please Follow!</p>
            <ul class="flex py-4 px-8 justify-center">
                <li><a href="https://www.tiktok.com/@haruka._.piano?_t=ZS-8xu0UrLmOb1&_r=1" class="w-24 h-16 py-4 flex justify-center items-center hover:bg-base"><img class="fade-in block h-10" src="<?php echo esc_url(get_theme_file_uri('assets/images/Tiktok_logo_b.png')); ?>" alt="Tiktok"></a></li>
                <li><a href="https://www.instagram.com/haruka__piano/" class="w-24 h-16 py-4 flex justify-center items-center hover:bg-base"><img class="fade-in block h-10" src="<?php echo esc_url(get_theme_file_uri('assets/images/Instagram_logo.png')); ?>" alt="Instagram"></a></li>
                <li><a href="https://www.youtube.com/sponsor_channel/UCRYAOInuvek3RWgA2aSZQ0g?app=desktop&noapp=1" class="w-24 h-16 py-4 flex justify-center items-center hover:bg-base"><img class="fade-in block h-10" src="<?php echo esc_url(get_theme_file_uri('assets/images/Youtube_logo.png')); ?>" alt="Youtube"></a></li>
            </ul>
        </div>

    </div>