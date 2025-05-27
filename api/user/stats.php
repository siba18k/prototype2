<?php
header("Content-Type: application/json");
require_once '../../includes/auth.php';
require_once '../../includes/db_connect.php';

session_start();
if (!isset($_SESSION['user_id'])) {
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit;
}

try {
    $userId = $_SESSION['user_id'];
    
    // Get total points and items
    $stmt = $pdo->prepare("
        SELECT 
            points_balance as total_points,
            (SELECT COUNT(*) FROM scanned_barcodes WHERE user_id = ?) as total_items
        FROM users 
        WHERE user_id = ?
    ");
    $stmt->execute([$userId, $userId]);
    $stats = $stmt->fetch();
    
    // Calculate CO2 savings (approximate 0.1kg per item)
    $stats['co2_saved'] = round($stats['total_items'] * 0.1, 2);
    
    // Calculate weekly trends
    $stmt = $pdo->prepare("
        SELECT 
            (SELECT COALESCE(SUM(points_awarded), 0) 
             FROM scanned_barcodes 
             WHERE user_id = ? AND scan_time BETWEEN DATE_SUB(NOW(), INTERVAL 7 DAY) AND NOW()) as current_week,
             
            (SELECT COALESCE(SUM(points_awarded), 0) 
             FROM scanned_barcodes 
             WHERE user_id = ? AND scan_time BETWEEN DATE_SUB(NOW(), INTERVAL 14 DAY) AND DATE_SUB(NOW(), INTERVAL 7 DAY)) as previous_week
    ");
    $stmt->execute([$userId, $userId]);
    $trends = $stmt->fetch();
    
    $stats['points_trend'] = $trends['previous_week'] > 0 ? 
        round(($trends['current_week'] - $trends['previous_week']) / $trends['previous_week'] * 100) : 0;
    
    $stmt = $pdo->prepare("
        SELECT 
            (SELECT COUNT(*) 
             FROM scanned_barcodes 
             WHERE user_id = ? AND scan_time BETWEEN DATE_SUB(NOW(), INTERVAL 7 DAY) AND NOW()) as current_week,
             
            (SELECT COUNT(*) 
             FROM scanned_barcodes 
             WHERE user_id = ? AND scan_time BETWEEN DATE_SUB(NOW(), INTERVAL 14 DAY) AND DATE_SUB(NOW(), INTERVAL 7 DAY)) as previous_week
    ");
    $stmt->execute([$userId, $userId]);
    $itemTrends = $stmt->fetch();
    
    $stats['items_trend'] = $itemTrends['previous_week'] > 0 ? 
        round(($itemTrends['current_week'] - $itemTrends['previous_week']) / $itemTrends['previous_week'] * 100) : 0;
    
    echo json_encode(['success' => true, ...$stats]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error']);
}
?>
