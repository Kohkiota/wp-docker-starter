<?php
/**
 * Disable canonical redirect when accessed via nginx container (BrowserSync 用)
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

add_filter( 'redirect_canonical', function( $redirect_url, $requested_url ) {

    if ( isset( $_SERVER['HTTP_HOST'] ) ) {
        $host = $_SERVER['HTTP_HOST'];

        // 可能性のあるパターン全部潰す
        if ( $host === 'nginx' || $host === 'nginx:80' || $host === 'nginx:8080' ) {
            return false; // リダイレクトしない
        }
    }

    return $redirect_url;
}, 10, 2 );
