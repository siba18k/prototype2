<?php
require_once 'db_connect.php';

class RewardSystem {
    private $pdo;
    private $rateLimit = [
        'maxAttempts' => 10,
        'timeWindow' => 3600 // 1 hour
    ];
    
    public function __construct() {
        global $pdo;
        $this->pdo = $pdo;
    }

    public function getAvailableRewards($category = null) {
        $sql = "SELECT * FROM rewards WHERE is_active = TRUE";
        $params = [];
        
        if ($category) {
            $sql .= " AND category = ?";
            $params[] = $category;
        }
        
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        
        $rewards = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Add inventory status
        return array_map(function($reward) {
            $reward['inventory_status'] = $this->getInventoryStatus($reward);
            return $reward;
        }, $rewards);
    }

    private function getInventoryStatus($reward) {
        if ($reward['inventory'] === null) return 'unlimited';
        if ($reward['inventory'] > 10) return 'high';
        if ($reward['inventory'] > 3) return 'medium';
        if ($reward['inventory'] > 0) return 'low';
        return 'out_of_stock';
    }

    public function getRewardCategories() {
        $stmt = $this->pdo->query("
            SELECT DISTINCT category 
            FROM rewards 
            WHERE is_active = TRUE
            ORDER BY category
        ");
        return $stmt->fetchAll(PDO::FETCH_COLUMN);
    }

    public function redeemReward($userId, $rewardId) {
        // Rate limiting check
        $this->checkRedemptionRateLimit($userId);
        
        $this->pdo->beginTransaction();
        
        try {
            // Verify reward exists and is active with lock
            $reward = $this->pdo->prepare("
                SELECT * FROM rewards 
                WHERE reward_id = ? 
                AND is_active = TRUE
                AND (inventory IS NULL OR inventory > 0)
                FOR UPDATE
            ");
            $reward->execute([$rewardId]);
            $reward = $reward->fetch();
            
            if (!$reward) {
                throw new Exception("Reward not available");
            }

            // Check user has enough points with lock
            $user = $this->pdo->prepare("
                SELECT user_id, points_balance FROM users 
                WHERE user_id = ? 
                FOR UPDATE
            ");
            $user->execute([$userId]);
            $user = $user->fetch();
            
            if (!$user) {
                throw new Exception("User not found");
            }
            
            if ($user['points_balance'] < $reward['points_cost']) {
                throw new Exception("Insufficient points");
            }

            // Process redemption
            $redemptionCode = bin2hex(random_bytes(8));
            
            // Deduct points
            $this->pdo->prepare("
                UPDATE users 
                SET points_balance = points_balance - ? 
                WHERE user_id = ?
            ")->execute([$reward['points_cost'], $userId]);
            
            // Reduce inventory if applicable
            if ($reward['inventory'] !== null) {
                $this->pdo->prepare("
                    UPDATE rewards 
                    SET inventory = inventory - 1 
                    WHERE reward_id = ?
                ")->execute([$rewardId]);
            }
            
            // Record redemption
            $this->pdo->prepare("
                INSERT INTO user_rewards 
                (user_id, reward_id, redemption_code, ip_address) 
                VALUES (?, ?, ?, ?)
            ")->execute([
                $userId, 
                $rewardId, 
                $redemptionCode,
                $_SERVER['REMOTE_ADDR']
            ]);
            
            // Log the redemption
            $this->logRedemption($userId, $rewardId, $reward['points_cost']);
            
            $this->pdo->commit();
            
            return [
                'success' => true,
                'redemption_code' => $redemptionCode,
                'reward_name' => $reward['name'],
                'remaining_points' => $user['points_balance'] - $reward['points_cost'],
                'inventory_status' => $this->getInventoryStatus($reward)
            ];
            
        } catch (Exception $e) {
            $this->pdo->rollBack();
            error_log("Redemption failed: " . $e->getMessage());
            return [
                'success' => false, 
                'message' => $e->getMessage(),
                'error_code' => 'redemption_error'
            ];
        }
    }

    private function logRedemption($userId, $rewardId, $pointsCost) {
        $this->pdo->prepare("
            INSERT INTO redemption_logs 
            (user_id, reward_id, points_cost, ip_address)
            VALUES (?, ?, ?, ?)
        ")->execute([
            $userId,
            $rewardId,
            $pointsCost,
            $_SERVER['REMOTE_ADDR']
        ]);
    }

    private function checkRedemptionRateLimit($userId) {
        $stmt = $this->pdo->prepare("
            SELECT COUNT(*) as redemptions 
            FROM redemption_logs 
            WHERE user_id = ? AND created_at > DATE_SUB(NOW(), INTERVAL ? SECOND)
        ");
        $stmt->execute([$userId, $this->rateLimit['timeWindow']]);
        $result = $stmt->fetch();
        
        if ($result['redemptions'] >= $this->rateLimit['maxAttempts']) {
            throw new Exception("Too many redemption attempts. Please try again later.");
        }
    }

    public function getUserHistory($userId) {
        $stmt = $this->pdo->prepare("
            SELECT 
                r.name, 
                r.points_cost, 
                ur.redeemed_at, 
                ur.redemption_code,
                r.image_url
            FROM user_rewards ur
            JOIN rewards r ON ur.reward_id = r.reward_id
            WHERE ur.user_id = ?
            ORDER BY ur.redeemed_at DESC
            LIMIT 50
        ");
        $stmt->execute([$userId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
?>
