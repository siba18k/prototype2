<?php
header("Content-Type: application/json");
require_once '../../includes/rewards.php';

$rewards = getAvailableRewards();
echo json_encode(['success' => true, 'data' => $rewards]);
?>
