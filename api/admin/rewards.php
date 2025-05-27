<?php
header("Content-Type: application/json");
require_once '../../includes/admin_auth.php';
require_once '../../includes/rewards.php';

try {
    AdminAuth::checkAdmin();
    
    $input = json_decode(file_get_contents('php://input'), true);
    $action = $_GET['action'] ?? '';
    $rewardId = $_GET['id'] ?? null;
    
    $rewardSystem = new RewardSystem();
    
    switch ($action) {
        case 'list':
            $rewards = $rewardSystem->getAvailableRewards();
            echo json_encode(['success' => true, 'data' => $rewards]);
            break;
            
        case 'add':
            if (empty($input['name']) || empty($input['description']) || empty($input['points_cost']) || empty($input['category'])) {
                throw new InvalidArgumentException("Missing required fields");
            }
            
            $rewardId = $rewardSystem->addReward(
                $input['name'],
                $input['description'],
                (int)$input['points_cost'],
                $input['category'],
                $input['inventory'] ?? null
            );
            
            echo json_encode(['success' => true, 'reward_id' => $rewardId]);
            break;
            
        case 'update':
            if (empty($rewardId)) {
                throw new InvalidArgumentException("Reward ID required");
            }
            
            // Similar validation as add, then:
            // $rewardSystem->updateReward($rewardId, $input);
            // echo json_encode(['success' => true]);
            break;
            
        case 'toggle_status':
            if (empty($rewardId)) {
                throw new InvalidArgumentException("Reward ID required");
            }
            
            $isActive = filter_var($input['is_active'], FILTER_VALIDATE_BOOLEAN);
            $rewardSystem->toggleRewardStatus($rewardId, $isActive);
            echo json_encode(['success' => true]);
            break;
            
        default:
            throw new Exception("Invalid action");
    }
    
} catch (InvalidArgumentException $e) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => $e->getMessage(), 'error_code' => 'invalid_input']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage(), 'error_code' => 'server_error']);
}
?>
