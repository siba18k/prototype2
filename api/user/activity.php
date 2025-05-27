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
    
    $stmt = $pdo->prepare("
        SELECT barcode, material_type, points_awarded, scan_time
        FROM scanned_barcodes
        WHERE user_id = ?
        ORDER BY scan_time DESC
        LIMIT 10
    ");
    $stmt->execute([$userId]);
    
    $activity = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode(['success' => true, 'activity' => $activity]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error']);
}
?>
