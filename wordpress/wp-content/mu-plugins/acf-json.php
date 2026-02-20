<?php
/**
 * ACF Local JSON Configuration
 * Location: wp-content/mu-plugins/acf-json.php
 */

if (!defined('ABSPATH')) exit;

// JSON保存先を設定（テーマディレクトリ内）
add_filter('acf/settings/save_json', function() {
    return get_stylesheet_directory() . '/acf-json';
});

// JSON読込先を設定（テーマディレクトリ内）
add_filter('acf/settings/load_json', function($paths) {
    unset($paths[0]); // デフォルトパスをクリア
    $paths[] = get_stylesheet_directory() . '/acf-json';
    return $paths;
});