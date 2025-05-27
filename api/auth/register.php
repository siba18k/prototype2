<?php
header("Content-Type: application/json");
require_once '../../includes/auth.php';
require_once '../../includes/db_connect.php';

session_start();

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validation
    if (empty($input['email']) || empty($input['password'])) {
        throw new Exception("Email and password are required");
    }

    if (empty($input['full_name'])) {
        throw new Exception("Full name is required");
    }

    if (empty($input['university'])) {
        throw new Exception("University selection is required");
    }

    // South African university email validation
    $saUniversityDomains = [
        '@myuct.ac.za', '@uct.ac.za', // UCT
        '@student.wits.ac.za', '@wits.ac.za', // WITS
        '@student.uj.ac.za', '@uj.ac.za', // UJ
        '@sun.ac.za', '@student.sun.ac.za', // Stellenbosch
        '@tuks.co.za', '@up.ac.za', // UP
        '@ukzn.ac.za', '@student.ukzn.ac.za', // UKZN
        '@ru.ac.za', '@campus.ru.ac.za', // Rhodes
        '@nwu.ac.za', '@student.nwu.ac.za', // NWU
        '@ufs.ac.za', '@student.ufs.ac.za', // UFS
        '@uwc.ac.za', '@student.uwc.ac.za', // UWC
        '@cput.ac.za', '@student.cput.ac.za', // CPUT
        '@dut.ac.za', '@student.dut.ac.za', // DUT
        '@tut.ac.za', '@student.tut.ac.za', // TUT
        '@vut.ac.za', '@student.vut.ac.za', // VUT
        '@cut.ac.za', '@student.cut.ac.za', // CUT
        '@mut.ac.za', '@student.mut.ac.za', // MUT
        '@wsu.ac.za', '@student.wsu.ac.za', // WSU
        '@ufh.ac.za', '@student.ufh.ac.za', // UFH
        '@ul.ac.za', '@student.ul.ac.za', // UL
        '@univen.ac.za', '@student.univen.ac.za', // UNIVEN
        '@uzulu.ac.za', '@student.uzulu.ac.za', // UZULU
        '@spu.ac.za', '@student.spu.ac.za', // SPU
        '@ump.ac.za', '@student.ump.ac.za' // UMP
    ];

    $isValidSAEmail = false;
    foreach ($saUniversityDomains as $domain) {
        if (str_ends_with(strtolower($input['email']), strtolower($domain))) {
            $isValidSAEmail = true;
            break;
        }
    }

    if (!$isValidSAEmail) {
        throw new Exception("Only South African university emails are allowed");
    }

    if (strlen($input['password']) < 8) {
        throw new Exception("Password must be at least 8 characters");
    }

    $userId = Auth::register(
        $input['email'],
        $input['password'],
        $input['full_name'],
        $input['university'] ?? null,
        $input['university_code'] ?? null,
        $input['student_number'] ?? null
    );

    echo json_encode([
        'success' => true,
        'message' => 'Registration successful',
        'user_id' => $userId
    ]);
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
