    <footer class="bg-center bg-cover relative flex flex-col justify-center" style="background-image: url(<?php echo esc_url(get_theme_file_uri('assets/images/footerimg.jpg')); ?>)">
        <!-- ぼかしレイヤー -->
        <div class="absolute inset-0 backdrop-blur-[10px] bg-white/20"></div>
        <div class="z-10">
            <ul class="icon flex justify-center items-center pt-[64px]">
                <li><a href="https://www.tiktok.com/@haruka._.piano?_t=ZS-8xu0UrLmOb1&_r=1" class="flex justify-center items-center h-full w-16 mx-3 drop-shadow-[1px_1px_3px_black]"><img class="block h-10" src="<?php echo esc_url(get_theme_file_uri('assets/images/Tiktok_logo_w.png')); ?>" alt="Tiktok"></a></li>
                <li><a href="https://www.instagram.com/haruka__piano/" class="flex justify-center items-center h-full w-16 mx-3 drop-shadow-[1px_1px_3px_black]"><img class="block h-10" src="<?php echo esc_url(get_theme_file_uri('assets/images/Instagram_logo_white.png')); ?>" alt="Instagram"></a></li>
                <li><a href="https://www.youtube.com/sponsor_channel/UCRYAOInuvek3RWgA2aSZQ0g?app=desktop&noapp=1" class="flex justify-center items-center h-full w-16 mx-3 drop-shadow-[1px_1px_3px_black]"><img class="block h-10" src="<?php echo esc_url(get_theme_file_uri('assets/images/Youtube_logo_white.png')); ?>" alt="Youtube"></a></li>
            </ul>
            <ul class="flex flex-wrap gap-8 justify-center text-center items-center mt-[24px] mx-[80px] py-[24px] text-lg border-b-[1px] border-white">
                <li><a class="footer-nav-link" href="<?php echo esc_url( home_url('/')); ?>">Home</a></li>
                <li><a class="footer-nav-link" href="<?php echo esc_url( get_permalink( get_option('page_for_posts'))); ?>">News</a></li>
                <li><a class="footer-nav-link" href="<?php echo esc_url( get_term_link('concert', 'category')); ?>">Concert</a></li>
                <li><a class="footer-nav-link" href="<?php echo esc_url( get_permalink( get_page_by_path('profile') ) ); ?>">Profile</a></li>
                <li><a class="footer-nav-link" href="<?php echo esc_url( get_permalink( get_page_by_path('lesson') ) ); ?>">Lesson</a></li>
                <li><a class="footer-nav-link" href="<?php echo esc_url( get_permalink( get_page_by_path('gallery') ) ); ?>">Gallery</a></li>
                <li><a class="footer-nav-link" href="<?php echo esc_url( get_permalink( get_page_by_path('contact') ) ); ?>">Contact</a></li>
            </ul>
            <div class="flex flex-col justify-between copyright pt-8 pb-24 h-14 text-white text-xs text-center">
                <div>&copy; 2026 Haruka Ueda. All Right Reserved.</div>
                <div class="mt-1">Site Design & Development by KOMYO Inc. | Photo: Ayane Shindo</div>
            </div>
            <a id="up-btn" class="border-2 border-white w-12 h-12 flex justify-center items-center text-xl font-black bg-black bg-opacity-60 text-white cursor-pointer hover:bg-opacity-80 hover:-translate-y-0.5 hover:shadow-lg">↑</a>
        </div>
    </footer>
    <?php wp_footer(); ?>
</body>
</html>