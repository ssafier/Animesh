<?php

// Configuration
$inputFile = 'AVpos.txt';
$menuOutputFile = 'menu.txt';
$animOutputFile = 'animations.txt';

if (!file_exists($inputFile)) {
    die("Error: Input file '$inputFile' not found.\n");
}

$lines = file($inputFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

$poses = [];       // For animations.txt
$positions = [];   // For LEAFs
$buttons = [];     // Maps pose to a menu
$menus = [];       // Tracks all unique menus

// Helper function to convert a degree vector <x, y, z> to radians
function degreesToRadiansVector($vecStr) {
    $vecStr = trim($vecStr, " <>");
    $parts = explode(',', $vecStr);
    if (count($parts) === 3) {
        $x = (float)$parts[0] * (M_PI / 180);
        $y = (float)$parts[1] * (M_PI / 180);
        $z = (float)$parts[2] * (M_PI / 180);
        return sprintf("<%.5f, %.5f, %.5f>", $x, $y, $z);
    }
    return "<0.0, 0.0, 0.0>"; // Fallback
}

// 1. Parse the AVsitter file
foreach ($lines as $line) {
    $line = trim($line);
    // Ignore comments
    if (empty($line) || strpos($line, '//') === 0 || strpos($line, '#') === 0) {
        continue;
    }

    $parts = array_map('trim', explode('|', $line));
    $firstPart = $parts[0];

    // POSE Line (e.g., POSE Hug | hug_anim_1 | hug_anim_2)
    if (preg_match('/^POSE\s+(.+)$/i', $firstPart, $matches)) {
        $poseName = trim($matches[1]);
        $anim1 = isset($parts[1]) ? $parts[1] : '';
        $anim2 = isset($parts[2]) ? $parts[2] : '';
        $poses[$poseName] = "pose|$poseName|$anim1" . ($anim2 ? "|$anim2" : "");
    }
    
    // POS Line (e.g., POS Hug | <0,0,1> | <0,0,0> | <0,1,1> | <0,0,90>)
    else if (preg_match('/^POS\s+(.+)$/i', $firstPart, $matches)) {
        $poseName = trim($matches[1]);
        $pos1 = isset($parts[1]) ? $parts[1] : '<0,0,0>';
        $rot1 = isset($parts[2]) ? degreesToRadiansVector($parts[2]) : '<0,0,0>';
        
        $pos2 = isset($parts[3]) ? $parts[3] : '';
        $rot2 = isset($parts[4]) ? degreesToRadiansVector($parts[4]) : '';

        $leafStr = "LEAF|$poseName|$pos1$rot1";
        if ($pos2 && $rot2) {
            $leafStr .= "|$pos2$rot2";
        }
        $positions[$poseName] = $leafStr;
    }
    
    // BUTTON Line (e.g., BUTTON Hug | Cuddles)
    else if (preg_match('/^BUTTON\s+(.+)$/i', $firstPart, $matches)) {
        $poseName = trim($matches[1]);
        $menuName = isset($parts[1]) ? $parts[1] : 'Main';
        $buttons[$menuName][] = $poseName;
        $menus[$menuName] = true;
    }
}

// 2. Generate Animations File
$animOutput = implode("\n", $poses) . "\n";
file_put_contents($animOutputFile, $animOutput);
echo "Generated $animOutputFile with " . count($poses) . " animations.\n";

// 3. Generate Menu File
$menuLines = [];
$rootNodes = [];

// Determine menu hierarchy
// If menus have poses, they are NODEs. 
foreach (array_keys($menus) as $menuName) {
    $nodeStr = "NODE|$menuName|Select an option:|4";
    
    // Add all poses (LEAFs) that belong to this menu
    if (isset($buttons[$menuName])) {
        foreach ($buttons[$menuName] as $poseName) {
            if (isset($positions[$poseName])) {
                $nodeStr .= "|" . $positions[$poseName];
            }
        }
    }
    $nodeStr .= "|TERMINAL|[BACK]";
    $menuLines[] = $nodeStr;
    
    // We add the menu name to root nodes so ROOT can point to them
    $rootNodes[] = "NODE|$menuName"; 
}

// Create the ROOT line
$rootStr = "ROOT|Main|4";
if (!empty($rootNodes)) {
    $rootStr .= "|" . implode("|", $rootNodes);
}
$rootStr .= "|TERMINAL|[QUIT]";

// Prepend ROOT to the top of the menu file
array_unshift($menuLines, $rootStr);

$menuOutput = implode("\n", $menuLines) . "\n";
file_put_contents($menuOutputFile, $menuOutput);
echo "Generated $menuOutputFile with ROOT and " . count($menus) . " menus.\n";

echo "Conversion complete!\n";

?>
