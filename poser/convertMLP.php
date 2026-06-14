<?php

// Configuration - Ensure these match your MLP filenames
$menuItemsFile = 'menuitems.txt';  // Rename your .MENUITEMS notecard to this
$positionsFile = 'positions.txt';  // Rename your .POSITIONS notecard to this
$menuOutputFile = 'menu.txt';
$animOutputFile = 'animations.txt';

if (!file_exists($menuItemsFile) || !file_exists($positionsFile)) {
    die("Error: Both '$menuItemsFile' and '$positionsFile' must exist in the same folder.\n");
}

$menuLines = file($menuItemsFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
$posLines = file($positionsFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

$positions = [];   // Maps PoseName -> LEAF string
$poses = [];       // Maps PoseName -> pose string for animations.txt
$menus = [];       // Tracks hierarchy

// ---------------------------------------------------------
// 1. Parse the .POSITIONS file
// MLP format: {PoseName} {<pos1>} {<rot1>} {<pos2>} {<rot2>}
// ---------------------------------------------------------
foreach ($posLines as $line) {
    $line = trim($line);
    if (empty($line) || strpos($line, '//') === 0) continue;

    // Extract everything inside curly braces {}
    if (preg_match_all('/\{(.*?)\}/', $line, $matches)) {
        $data = $matches[1];
        if (count($data) >= 3) {
            $poseName = trim($data[0]);
            
            // Remove spaces from vectors to match your syntax: <0,0,1><0,0,0>
            $pos1 = str_replace(' ', '', $data[1]);
            $rot1 = str_replace(' ', '', $data[2]);
            
            $leaf = "LEAF|$poseName|$pos1$rot1";
            
            // If it's a couple's pose with 2 avatars
            if (count($data) >= 5) {
                $pos2 = str_replace(' ', '', $data[3]);
                $rot2 = str_replace(' ', '', $data[4]);
                $leaf .= "|$pos2$rot2";
            }
            
            $positions[$poseName] = $leaf;
        }
    }
}

// ---------------------------------------------------------
// 2. Parse the .MENUITEMS file
// MLP format relies on grouping by MENU headers
// ---------------------------------------------------------
$currentMenu = 'Main';
$menus[$currentMenu] = [];

foreach ($menuLines as $line) {
    $line = trim($line);
    if (empty($line) || strpos($line, '//') === 0) continue;

    // Change current menu block
    if (preg_match('/^MENU\s+(.+)$/i', $line, $m)) {
        $currentMenu = trim($m[1]);
        if (!isset($menus[$currentMenu])) {
            $menus[$currentMenu] = [];
        }
    } 
    // Parse POSE line (e.g., POSE Hug hug_anim_1 hug_anim_2)
    elseif (preg_match('/^POSE\s+(.+)$/i', $line, $m)) {
        // Split by whitespace
        $parts = preg_split('/\s+/', trim($m[1]));
        $poseName = array_shift($parts); // First word is the pose name
        
        // The remaining parts are the inventory animations
        $anim1 = isset($parts[0]) ? $parts[0] : '';
        $anim2 = isset($parts[1]) ? $parts[1] : '';
        
        $poses[$poseName] = "pose|$poseName|$anim1" . ($anim2 ? "|$anim2" : "");
        
        // Add to current menu hierarchy
        $menus[$currentMenu][] = $poseName;
    } 
    // Go back to root
    elseif (preg_match('/^BACK/i', $line)) {
        $currentMenu = 'Main';
    }
}

// ---------------------------------------------------------
// 3. Generate Animations File
// ---------------------------------------------------------
$animOutput = implode("\n", $poses) . "\n";
file_put_contents($animOutputFile, $animOutput);
echo "Generated $animOutputFile with " . count($poses) . " animations.\n";

// ---------------------------------------------------------
// 4. Generate Menu File
// ---------------------------------------------------------
$outMenuLines = [];
$rootNodes = [];
$mainPoses = "";

// Build submenus (NODEs)
foreach ($menus as $menuName => $poseList) {
    if (empty($poseList) || $menuName === 'Main') continue; 
    
    // Add this menu as a node to the root
    $rootNodes[] = "NODE|$menuName";
    
    // Build the NODE string
    $nodeStr = "NODE|$menuName|Select an option:|4";
    foreach ($poseList as $poseName) {
        if (isset($positions[$poseName])) {
            $nodeStr .= "|" . $positions[$poseName];
        }
    }
    $nodeStr .= "|TERMINAL|[BACK]";
    $outMenuLines[] = $nodeStr;
}

// Build ROOT string
$rootStr = "ROOT|Main|4";
if (!empty($rootNodes)) {
    $rootStr .= "|" . implode("|", $rootNodes);
}

// Attach any poses that were directly in the Main menu
if (isset($menus['Main'])) {
    foreach ($menus['Main'] as $poseName) {
        if (isset($positions[$poseName])) {
            $rootStr .= "|" . $positions[$poseName];
        }
    }
}
$rootStr .= "|TERMINAL|[QUIT]";

// Prepend ROOT to the top
array_unshift($outMenuLines, $rootStr);

$menuOutput = implode("\n", $outMenuLines) . "\n";
file_put_contents($menuOutputFile, $menuOutput);
echo "Generated $menuOutputFile with ROOT and " . (count($menus) - 1) . " submenus.\n";

echo "Conversion complete!\n";

?>
    
