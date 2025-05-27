<?php
header("Content-Type: application/json");
require_once '../../includes/auth.php';
require_once '../../includes/db_connect.php';

session_start();

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (empty($input['email']) || empty($input['password'])) {
        throw new Exception("Email and password are required");
    }

    if (Auth::login($input['email'], $input['password'])) {
        echo json_encode([
            'success' => true,
            'message' => 'Login successful',
            'user' => [
                'id' => $_SESSION['user_id'],
                'email' => $_SESSION['user_email']
            ]
        ]);
    } else {
        throw new Exception("Invalid email or password");
    }
} catch (Exception $e) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
