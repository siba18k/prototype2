<?php
header("Content-Type: application/json");
require_once '../../includes/auth.php';

session_start();
Auth::logout();

echo json_encode([
    'success' => true,
    'message' => 'Logged out successfully'
]);
?>
