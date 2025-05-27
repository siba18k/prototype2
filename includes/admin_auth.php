<?php
require_once 'auth.php';

class AdminAuth {
    private static $rateLimit = [
        'maxAttempts' => 5,
        'timeWindow' => 300 // 5 minutes
    ];

    public static function checkAdmin() {
        if (!isset($_SESSION['user_id'])) {
            throw new Exception("Not logged in");
        }
        
        // Rate limiting check
        self::checkRateLimit($_SESSION['user_id']);
        
        global $pdo;
        $stmt = $pdo->prepare("SELECT * FROM admin_users WHERE user_id = ?");
        $stmt->execute([$_SESSION['user_id']]);
        
        if (!$stmt->fetch()) {
            self::logFailedAttempt($_SESSION['user_id']);
            throw new Exception("Admin access required");
        }
    }

    private static function checkRateLimit($userId) {
        global $pdo;
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as attempts 
            FROM admin_access_logs 
            WHERE user_id = ? AND timestamp > DATE_SUB(NOW(), INTERVAL ? SECOND)
        ");
        $stmt->execute([$userId, self::$rateLimit['timeWindow']]);
        $result = $stmt->fetch();
        
        if ($result['attempts'] >= self::$rateLimit['maxAttempts']) {
            throw new Exception("Too many requests. Please try again later.");
        }
    }

    private static function logFailedAttempt($userId) {
        global $pdo;
        $pdo->prepare("
            INSERT INTO admin_access_logs (user_id, ip_address, success) 
            VALUES (?, ?, 0)
        ")->execute([$userId, $_SERVER['REMOTE_ADDR']]);
    }
}
?>
