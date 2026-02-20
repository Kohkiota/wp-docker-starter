<?php
/**
 * ACF JSON to Database Import Script
 * Usage: wp eval-file import-acf-json.php --allow-root --path=/var/www/html
 */

if (!function_exists('acf_import_field_group')) {
    fwrite(STDERR, "ERROR: ACF plugin not loaded\n");
    exit(1);
}

// JSONファイルのディレクトリ（テーマ内）
$json_dir = get_stylesheet_directory() . '/acf-json';

if (!is_dir($json_dir)) {
    fwrite(STDERR, "ERROR: ACF JSON directory not found: {$json_dir}\n");
    exit(1);
}

$json_files = glob($json_dir . '/*.json');

if (empty($json_files)) {
    fwrite(STDERR, "WARNING: No JSON files found in {$json_dir}\n");
    exit(0);
}

echo "Found " . count($json_files) . " JSON file(s) in {$json_dir}\n";

foreach ($json_files as $file) {
    echo "Processing: " . basename($file) . "\n";
    
    $json_content = file_get_contents($file);
    if ($json_content === false) {
        fwrite(STDERR, "ERROR: Failed to read file: {$file}\n");
        continue;
    }
    
    $data = json_decode($json_content, true);
    if ($data === null) {
        fwrite(STDERR, "ERROR: Invalid JSON in file: {$file}\n");
        continue;
    }
    
    $groups = isset($data['key']) ? [$data] : $data;
    
    foreach ($groups as $group) {
        unset($group['ID']);
        $result = acf_import_field_group($group);
        
        if ($result) {
            echo "  ✓ Imported: {$group['title']} (key: {$group['key']})\n";
        } else {
            fwrite(STDERR, "  ✗ Failed: {$group['title']}\n");
        }
    }
}

echo "\n✓ ACF JSON import completed!\n";