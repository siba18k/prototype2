<?php
header("Content-Type: application/json");
require_once '../../includes/barcode.php';
require_once '../../includes/auth.php';

session_start();
if (!isset($_SESSION['user_id'])) {
    echo json_encode(['success' => false, 'message' => 'Not logged in']);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
$scanner = new BarcodeScanner();

try {
    // Validate input
    if (empty($input['barcode'])) {
        throw new InvalidArgumentException("Barcode cannot be empty");
    }

    if (!in_array($input['material'], ['glass', 'aluminum', 'plastic'])) {
        throw new InvalidArgumentException("Invalid material type");
    }

    // Process scan
    $result = $scanner->scanBarcode(
        $_SESSION['user_id'],
        $input['barcode'],
        $input['material'],
        $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR']
    );

    // If successful, get additional user stats
    if ($result['success']) {
        global $pdo;
        
        // Get total items recycled
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as total_items,
                   SUM(points_awarded) as total_points_earned
            FROM scanned_barcodes 
            WHERE user_id = ?
        ");
        $stmt->execute([$_SESSION['user_id']]);
        $stats = $stmt->fetch();
        
        // Calculate CO2 saved (approximate)
        $co2Saved = round($stats['total_items'] * 0.15, 2); // 0.15kg per item average
        
        $result['total_items'] = $stats['total_items'];
        $result['total_points_earned'] = $stats['total_points_earned'];
        $result['co2_saved'] = $co2Saved;
        
        // Log additional barcode format if available
        if (!empty($input['format'])) {
            $pdo->prepare("
                UPDATE scanned_barcodes 
                SET device_info = ?
                WHERE barcode = ? AND user_id = ?
                ORDER BY scan_time DESC LIMIT 1
            ")->execute([
                json_encode(['format' => $input['format']]), 
                $input['barcode'], 
                $_SESSION['user_id']
            ]);
        }
    }

    echo json_encode($result);

} catch (InvalidArgumentException $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'error_code' => 'invalid_input'
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Scan processing failed',
        'error_code' => 'server_error'
    ]);
}
?>
