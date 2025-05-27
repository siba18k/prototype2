<?php
header("Content-Type: application/json");
require_once '../../includes/auth.php';
require_once '../../includes/db_connect.php';

session_start();

$response = [
    'authenticated' => false,
    'user' => null
];

if (Auth::isLoggedIn()) {
    $stmt = $pdo->prepare("
        SELECT u.user_id, u.college_email, up.full_name 
        FROM users u
        LEFT JOIN user_profiles up ON u.user_id = up.user_id
        WHERE u.user_id = ?
    ");
    $stmt->execute([$_SESSION['user_id']]);
    $user = $stmt->fetch();

    if ($user) {
        $response['authenticated'] = true;
        $response['user'] = $user;
    }
}

echo json_encode($response);
?>
