-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 08, 2025 at 04:07 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `adbeam`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `check_rate_limit` (IN `p_user_id` INT, IN `p_time_window` INT, IN `p_max_attempts` INT, OUT `p_exceeds_limit` BOOLEAN)   BEGIN
    DECLARE attempt_count INT;
    
    SELECT COUNT(*) INTO attempt_count
    FROM `admin_access_logs`
    WHERE `user_id` = p_user_id
    AND `timestamp` > DATE_SUB(NOW(), INTERVAL p_time_window SECOND);
    
    SET p_exceeds_limit = attempt_count >= p_max_attempts;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `log_admin_access` (IN `p_user_id` INT, IN `p_ip_address` VARCHAR(45), IN `p_success` BOOLEAN, IN `p_action` VARCHAR(50))   BEGIN
    INSERT INTO `admin_access_logs` (
        `user_id`,
        `ip_address`,
        `success`,
        `action`
    ) VALUES (
        p_user_id,
        p_ip_address,
        p_success,
        p_action
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `log_reward_change` (IN `p_reward_id` INT, IN `p_action` VARCHAR(20), IN `p_performed_by` INT, IN `p_ip_address` VARCHAR(45), IN `p_old_values` JSON, IN `p_new_values` JSON)   BEGIN
    INSERT INTO `reward_audit_log` (
        `reward_id`,
        `action`,
        `performed_by`,
        `ip_address`,
        `old_values`,
        `new_values`
    ) VALUES (
        p_reward_id,
        p_action,
        p_performed_by,
        p_ip_address,
        p_old_values,
        p_new_values
    );
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `admin_access_logs`
--

CREATE TABLE `admin_access_logs` (
  `log_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `action` varchar(50) NOT NULL,
  `success` tinyint(1) NOT NULL DEFAULT 0,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `admin_dashboard_stats`
-- (See below for the actual view)
--
CREATE TABLE `admin_dashboard_stats` (
`total_users` bigint(21)
,`active_users` bigint(21)
,`total_points_awarded` decimal(32,0)
,`total_redemptions` bigint(21)
,`weekly_scans` bigint(21)
,`weekly_redemptions` bigint(21)
);

-- --------------------------------------------------------

--
-- Table structure for table `admin_users`
--

CREATE TABLE `admin_users` (
  `admin_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `permissions` enum('basic','full') DEFAULT 'basic'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admin_users`
--

INSERT INTO `admin_users` (`admin_id`, `user_id`, `permissions`) VALUES
(2, 1, 'full');

-- --------------------------------------------------------

--
-- Table structure for table `redemption_logs`
--

CREATE TABLE `redemption_logs` (
  `log_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `reward_id` int(11) NOT NULL,
  `points_cost` int(11) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `rewards`
--

CREATE TABLE `rewards` (
  `reward_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `points_cost` int(11) NOT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `category` varchar(50) DEFAULT 'general',
  `inventory` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `rewards`
--

INSERT INTO `rewards` (`reward_id`, `name`, `description`, `points_cost`, `image_url`, `is_active`, `created_at`, `updated_at`, `category`, `inventory`) VALUES
(1, 'Campus Coffee Voucher', 'Free medium coffee at the student cafe', 50, '/images/coffee.jpg', 1, '2025-05-05 20:37:13', '2025-05-05 20:37:13', 'general', NULL),
(2, 'Bookstore Discount', '15% off any textbook purchase', 100, '/images/bookstore.jpg', 1, '2025-05-05 20:37:13', '2025-05-05 20:37:13', 'general', NULL),
(3, 'Printing Credits', '50 free black & white prints', 30, '/images/printing.jpg', 1, '2025-05-05 20:37:13', '2025-05-05 20:37:13', 'general', NULL),
(4, 'Parking Pass', 'One-day free parking', 150, '/images/parking.jpg', 1, '2025-05-05 20:37:13', '2025-05-05 20:37:13', 'general', NULL),
(5, 'Campus Store $5 Coupon', '$5 discount at the campus bookstore', 100, NULL, 1, '2025-05-05 20:49:33', '2025-05-05 20:49:33', 'discount', 100),
(6, 'Free Coffee', 'Redeem for one free coffee at campus café', 50, NULL, 1, '2025-05-05 20:49:33', '2025-05-05 20:49:33', 'food', 200),
(7, 'Library Late Waiver', 'Waive one library late fee', 75, NULL, 1, '2025-05-05 20:49:33', '2025-05-05 20:49:33', 'service', NULL),
(8, 'Parking Pass Discount', '10% off semester parking pass', 200, NULL, 1, '2025-05-05 20:49:33', '2025-05-05 20:49:33', 'transportation', 50),
(9, 'Event Ticket', 'Ticket to exclusive campus event', 150, NULL, 1, '2025-05-05 20:49:33', '2025-05-05 20:49:33', 'experience', 30);

--
-- Triggers `rewards`
--
DELIMITER $$
CREATE TRIGGER `before_reward_update` BEFORE UPDATE ON `rewards` FOR EACH ROW BEGIN
    INSERT INTO `reward_audit_log` (
        `reward_id`,
        `action`,
        `old_values`,
        `new_values`,
        `ip_address`
    ) VALUES (
        NEW.`reward_id`,
        'update',
        JSON_OBJECT(
            'name', OLD.`name`,
            'description', OLD.`description`,
            'points_cost', OLD.`points_cost`,
            'category', OLD.`category`,
            'inventory', OLD.`inventory`,
            'is_active', OLD.`is_active`
        ),
        JSON_OBJECT(
            'name', NEW.`name`,
            'description', NEW.`description`,
            'points_cost', NEW.`points_cost`,
            'category', NEW.`category`,
            'inventory', NEW.`inventory`,
            'is_active', NEW.`is_active`
        ),
        COALESCE(@current_ip, 'system')
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `reward_audit_log`
--

CREATE TABLE `reward_audit_log` (
  `audit_id` int(11) NOT NULL,
  `reward_id` int(11) NOT NULL,
  `action` varchar(20) NOT NULL,
  `old_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`old_values`)),
  `new_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`new_values`)),
  `performed_by` int(11) DEFAULT NULL,
  `ip_address` varchar(45) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `reward_inventory_status`
-- (See below for the actual view)
--
CREATE TABLE `reward_inventory_status` (
`reward_id` int(11)
,`name` varchar(255)
,`category` varchar(50)
,`points_cost` int(11)
,`inventory` int(11)
,`is_active` tinyint(1)
,`inventory_status` varchar(12)
);

-- --------------------------------------------------------

--
-- Table structure for table `scanned_barcodes`
--

CREATE TABLE `scanned_barcodes` (
  `scan_id` int(11) NOT NULL,
  `barcode` varchar(255) NOT NULL,
  `user_id` int(11) NOT NULL,
  `material_type` enum('plastic','glass','aluminum') NOT NULL,
  `points_awarded` int(11) NOT NULL,
  `scan_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `device_info` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scan_logs`
--

CREATE TABLE `scan_logs` (
  `log_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `points` int(11) NOT NULL,
  `location_verified` tinyint(1) NOT NULL DEFAULT 0,
  `ip_address` varchar(45) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `college_email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `points_balance` int(11) DEFAULT 0,
  `last_login` timestamp NULL DEFAULT NULL,
  `login_count` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `college_email`, `password_hash`, `points_balance`, `last_login`, `login_count`, `created_at`) VALUES
(1, 'admin@college.edu', '$2y$10$YourSecurePasswordHashHere', 0, NULL, 0, '2025-05-05 20:53:39');

--
-- Triggers `users`
--
DELIMITER $$
CREATE TRIGGER `after_user_insert` AFTER INSERT ON `users` FOR EACH ROW BEGIN
    INSERT INTO `user_profiles` (`user_id`) VALUES (NEW.`user_id`);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user_profiles`
--

CREATE TABLE `user_profiles` (
  `profile_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `full_name` varchar(100) DEFAULT NULL,
  `campus_id` varchar(20) DEFAULT NULL,
  `profile_picture` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_profiles`
--

INSERT INTO `user_profiles` (`profile_id`, `user_id`, `full_name`, `campus_id`, `profile_picture`, `created_at`, `updated_at`) VALUES
(1, 1, NULL, NULL, NULL, '2025-05-05 20:53:39', '2025-05-05 20:53:39');

-- --------------------------------------------------------

--
-- Stand-in structure for view `user_redemption_history`
-- (See below for the actual view)
--
CREATE TABLE `user_redemption_history` (
`user_id` int(11)
,`college_email` varchar(255)
,`reward_name` varchar(255)
,`points_cost` int(11)
,`redemption_code` varchar(16)
,`redeemed_at` timestamp
,`ip_address` varchar(45)
);

-- --------------------------------------------------------

--
-- Table structure for table `user_rewards`
--

CREATE TABLE `user_rewards` (
  `redemption_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `reward_id` int(11) NOT NULL,
  `redemption_code` varchar(16) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `device_info` varchar(255) DEFAULT NULL,
  `redeemed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure for view `admin_dashboard_stats`
--
DROP TABLE IF EXISTS `admin_dashboard_stats`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `admin_dashboard_stats`  AS SELECT (select count(0) from `users`) AS `total_users`, (select count(0) from `users` where `users`.`last_login` > current_timestamp() - interval 7 day) AS `active_users`, (select sum(`scanned_barcodes`.`points_awarded`) from `scanned_barcodes`) AS `total_points_awarded`, (select count(0) from `user_rewards`) AS `total_redemptions`, (select count(0) from `scanned_barcodes` where `scanned_barcodes`.`scan_time` > current_timestamp() - interval 7 day) AS `weekly_scans`, (select count(0) from `user_rewards` where `user_rewards`.`redeemed_at` > current_timestamp() - interval 7 day) AS `weekly_redemptions` ;

-- --------------------------------------------------------

--
-- Structure for view `reward_inventory_status`
--
DROP TABLE IF EXISTS `reward_inventory_status`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `reward_inventory_status`  AS SELECT `rewards`.`reward_id` AS `reward_id`, `rewards`.`name` AS `name`, `rewards`.`category` AS `category`, `rewards`.`points_cost` AS `points_cost`, `rewards`.`inventory` AS `inventory`, `rewards`.`is_active` AS `is_active`, CASE WHEN `rewards`.`inventory` is null THEN 'unlimited' WHEN `rewards`.`inventory` > 10 THEN 'high' WHEN `rewards`.`inventory` > 3 THEN 'medium' WHEN `rewards`.`inventory` > 0 THEN 'low' ELSE 'out_of_stock' END AS `inventory_status` FROM `rewards` ;

-- --------------------------------------------------------

--
-- Structure for view `user_redemption_history`
--
DROP TABLE IF EXISTS `user_redemption_history`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `user_redemption_history`  AS SELECT `ur`.`user_id` AS `user_id`, `u`.`college_email` AS `college_email`, `r`.`name` AS `reward_name`, `r`.`points_cost` AS `points_cost`, `ur`.`redemption_code` AS `redemption_code`, `ur`.`redeemed_at` AS `redeemed_at`, `ur`.`ip_address` AS `ip_address` FROM ((`user_rewards` `ur` join `rewards` `r` on(`ur`.`reward_id` = `r`.`reward_id`)) join `users` `u` on(`ur`.`user_id` = `u`.`user_id`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin_access_logs`
--
ALTER TABLE `admin_access_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `timestamp` (`timestamp`);

--
-- Indexes for table `admin_users`
--
ALTER TABLE `admin_users`
  ADD PRIMARY KEY (`admin_id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `redemption_logs`
--
ALTER TABLE `redemption_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `reward_id` (`reward_id`),
  ADD KEY `created_at` (`created_at`);

--
-- Indexes for table `rewards`
--
ALTER TABLE `rewards`
  ADD PRIMARY KEY (`reward_id`);

--
-- Indexes for table `reward_audit_log`
--
ALTER TABLE `reward_audit_log`
  ADD PRIMARY KEY (`audit_id`),
  ADD KEY `reward_id` (`reward_id`),
  ADD KEY `timestamp` (`timestamp`);

--
-- Indexes for table `scanned_barcodes`
--
ALTER TABLE `scanned_barcodes`
  ADD PRIMARY KEY (`scan_id`),
  ADD UNIQUE KEY `barcode` (`barcode`),
  ADD KEY `idx_user_barcode` (`user_id`,`barcode`);

--
-- Indexes for table `scan_logs`
--
ALTER TABLE `scan_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `timestamp` (`timestamp`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `college_email` (`college_email`),
  ADD KEY `idx_email` (`college_email`);

--
-- Indexes for table `user_profiles`
--
ALTER TABLE `user_profiles`
  ADD PRIMARY KEY (`profile_id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `user_rewards`
--
ALTER TABLE `user_rewards`
  ADD PRIMARY KEY (`redemption_id`),
  ADD UNIQUE KEY `redemption_code` (`redemption_code`),
  ADD KEY `reward_id` (`reward_id`),
  ADD KEY `idx_user_reward` (`user_id`,`reward_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin_access_logs`
--
ALTER TABLE `admin_access_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `admin_users`
--
ALTER TABLE `admin_users`
  MODIFY `admin_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `redemption_logs`
--
ALTER TABLE `redemption_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `rewards`
--
ALTER TABLE `rewards`
  MODIFY `reward_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `reward_audit_log`
--
ALTER TABLE `reward_audit_log`
  MODIFY `audit_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scanned_barcodes`
--
ALTER TABLE `scanned_barcodes`
  MODIFY `scan_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scan_logs`
--
ALTER TABLE `scan_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_profiles`
--
ALTER TABLE `user_profiles`
  MODIFY `profile_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_rewards`
--
ALTER TABLE `user_rewards`
  MODIFY `redemption_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `admin_users`
--
ALTER TABLE `admin_users`
  ADD CONSTRAINT `admin_users_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `scanned_barcodes`
--
ALTER TABLE `scanned_barcodes`
  ADD CONSTRAINT `scanned_barcodes_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

--
-- Constraints for table `user_rewards`
--
ALTER TABLE `user_rewards`
  ADD CONSTRAINT `user_rewards_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `user_rewards_ibfk_2` FOREIGN KEY (`reward_id`) REFERENCES `rewards` (`reward_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
