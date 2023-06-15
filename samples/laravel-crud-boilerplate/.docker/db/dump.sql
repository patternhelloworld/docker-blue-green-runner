-- --------------------------------------------------------
-- 호스트:                          127.0.0.1
-- 서버 버전:                        10.11.3-MariaDB-1:10.11.3+maria~ubu2204 - mariadb.org binary distribution
-- 서버 OS:                        debian-linux-gnu
-- HeidiSQL 버전:                  12.4.0.6659
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- laravel_crud_boilerplate 데이터베이스 구조 내보내기
CREATE DATABASE IF NOT EXISTS `laravel_crud_boilerplate` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;
USE `laravel_crud_boilerplate`;

-- 테이블 laravel_crud_boilerplate.courses 구조 내보내기
CREATE TABLE IF NOT EXISTS `courses` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `tutor_id` int(10) NOT NULL,
  `language` enum('en','cn') NOT NULL,
  `type` enum('Voice','Video','Chat') NOT NULL,
  `price` int(10) DEFAULT NULL,
  `duration` int(10) DEFAULT NULL,
  `duration_measurement` enum('month','day') DEFAULT NULL,
  `lesson_minutes` int(10) NOT NULL,
  `available_from` datetime NOT NULL,
  `available_until` datetime NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `tutor_id` (`tutor_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 laravel_crud_boilerplate.courses:~3 rows (대략적) 내보내기
INSERT INTO `courses` (`id`, `tutor_id`, `language`, `type`, `price`, `duration`, `duration_measurement`, `lesson_minutes`, `available_from`, `available_until`, `created_at`, `updated_at`, `deleted_at`) VALUES
	(1, 1, 'en', 'Voice', 2000000, 10, 'month', 50, '2023-06-08 09:50:51', '2023-06-13 09:51:55', NULL, '2023-06-09 06:47:06', NULL),
	(2, 3, 'cn', 'Video', 1000000, 5, 'month', 30, '2023-06-08 10:16:56', '2023-06-13 10:16:58', NULL, NULL, NULL),
	(3, 5, 'en', 'Chat', 500000, 2, 'month', 15, '2023-06-08 10:18:29', '2023-06-15 10:18:31', NULL, NULL, NULL);

-- 테이블 laravel_crud_boilerplate.enrollments 구조 내보내기
CREATE TABLE IF NOT EXISTS `enrollments` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `student_id` int(10) NOT NULL,
  `course_id` int(10) NOT NULL,
  `purchase_date` datetime NOT NULL,
  `expiration_date` datetime NOT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `student_id_course_id` (`student_id`,`course_id`),
  KEY `student_id` (`student_id`) USING BTREE,
  KEY `course_id` (`course_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 laravel_crud_boilerplate.enrollments:~2 rows (대략적) 내보내기
INSERT INTO `enrollments` (`id`, `student_id`, `course_id`, `purchase_date`, `expiration_date`, `deleted_at`, `created_at`, `updated_at`) VALUES
	(3, 2, 1, '2023-06-09 13:52:08', '2023-06-15 13:52:09', NULL, NULL, '2023-06-09 06:47:06'),
	(4, 4, 1, '2023-06-11 13:52:33', '2023-06-15 13:52:36', NULL, NULL, '2023-06-09 06:47:06');

-- 테이블 laravel_crud_boilerplate.lessons 구조 내보내기
CREATE TABLE IF NOT EXISTS `lessons` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `enrollment_id` int(10) NOT NULL,
  `status` enum('Start','End') NOT NULL DEFAULT 'Start',
  `result` varchar(100) DEFAULT NULL,
  `recording` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `enrollment_id_status` (`enrollment_id`,`status`),
  KEY `enrollment_id` (`enrollment_id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 laravel_crud_boilerplate.lessons:~2 rows (대략적) 내보내기
INSERT INTO `lessons` (`id`, `enrollment_id`, `status`, `result`, `recording`, `created_at`, `updated_at`, `deleted_at`) VALUES
	(8, 3, 'Start', NULL, NULL, '2023-06-09 06:03:04', '2023-06-09 06:47:06', NULL),
	(18, 3, 'End', 'ccc', 'bbb', '2023-06-09 06:27:58', '2023-06-09 06:47:06', NULL);

-- 테이블 laravel_crud_boilerplate.migrations 구조 내보내기
CREATE TABLE IF NOT EXISTS `migrations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(191) NOT NULL,
  `batch` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;

-- 테이블 데이터 laravel_crud_boilerplate.migrations:~9 rows (대략적) 내보내기
INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
	(5, '2014_10_12_000000_create_users_table', 1),
	(6, '2014_10_12_100000_create_password_resets_table', 1),
	(7, '2017_03_24_122715_create_article_table', 1),
	(8, '2019_12_14_000001_create_personal_access_tokens_table', 1),
	(9, '2016_06_01_000001_create_oauth_auth_codes_table', 2),
	(10, '2016_06_01_000002_create_oauth_access_tokens_table', 2),
	(11, '2016_06_01_000003_create_oauth_refresh_tokens_table', 2),
	(12, '2016_06_01_000004_create_oauth_clients_table', 2),
	(13, '2016_06_01_000005_create_oauth_personal_access_clients_table', 2);

-- 테이블 laravel_crud_boilerplate.oauth_access_tokens 구조 내보내기
CREATE TABLE IF NOT EXISTS `oauth_access_tokens` (
  `id` varchar(100) NOT NULL,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `client_id` bigint(20) unsigned NOT NULL,
  `name` varchar(191) DEFAULT NULL,
  `scopes` text DEFAULT NULL,
  `revoked` tinyint(1) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `oauth_access_tokens_user_id_index` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 laravel_crud_boilerplate.oauth_access_tokens:~0 rows (대략적) 내보내기

-- 테이블 laravel_crud_boilerplate.oauth_auth_codes 구조 내보내기
CREATE TABLE IF NOT EXISTS `oauth_auth_codes` (
  `id` varchar(100) NOT NULL,
  `user_id` bigint(20) unsigned NOT NULL,
  `client_id` bigint(20) unsigned NOT NULL,
  `scopes` text DEFAULT NULL,
  `revoked` tinyint(1) NOT NULL,
  `expires_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `oauth_auth_codes_user_id_index` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 laravel_crud_boilerplate.oauth_auth_codes:~0 rows (대략적) 내보내기

-- 테이블 laravel_crud_boilerplate.oauth_clients 구조 내보내기
CREATE TABLE IF NOT EXISTS `oauth_clients` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `name` varchar(191) NOT NULL,
  `secret` varchar(100) DEFAULT NULL,
  `provider` varchar(191) DEFAULT NULL,
  `redirect` text NOT NULL,
  `personal_access_client` tinyint(1) NOT NULL,
  `password_client` tinyint(1) NOT NULL,
  `revoked` tinyint(1) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `oauth_clients_user_id_index` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 laravel_crud_boilerplate.oauth_clients:~2 rows (대략적) 내보내기
INSERT INTO `oauth_clients` (`id`, `user_id`, `name`, `secret`, `provider`, `redirect`, `personal_access_client`, `password_client`, `revoked`, `created_at`, `updated_at`) VALUES
	(1, NULL, 'Laravel React Boilerplate Personal Access Client', 'WlNQCBeS4ekQjCRcNfv9gEwM6RQFxCaQResLJpsZ', NULL, 'http://localhost', 1, 0, 0, '2023-06-07 02:24:42', '2023-06-07 02:24:42'),
	(2, NULL, 'Laravel React Boilerplate Password Grant Client', 'bmKYzw31L1BJc5EqjL1MY1yfVtfET3Ezg4iIzGhD', 'users', 'http://localhost', 0, 1, 0, '2023-06-07 02:24:42', '2023-06-07 02:24:42');

-- 테이블 laravel_crud_boilerplate.oauth_personal_access_clients 구조 내보내기
CREATE TABLE IF NOT EXISTS `oauth_personal_access_clients` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `client_id` bigint(20) unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 laravel_crud_boilerplate.oauth_personal_access_clients:~0 rows (대략적) 내보내기
INSERT INTO `oauth_personal_access_clients` (`id`, `client_id`, `created_at`, `updated_at`) VALUES
	(1, 1, '2023-06-07 02:24:42', '2023-06-07 02:24:42');

-- 테이블 laravel_crud_boilerplate.oauth_refresh_tokens 구조 내보내기
CREATE TABLE IF NOT EXISTS `oauth_refresh_tokens` (
  `id` varchar(100) NOT NULL,
  `access_token_id` varchar(100) NOT NULL,
  `revoked` tinyint(1) NOT NULL,
  `expires_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `oauth_refresh_tokens_access_token_id_index` (`access_token_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 laravel_crud_boilerplate.oauth_refresh_tokens:~0 rows (대략적) 내보내기

-- 테이블 laravel_crud_boilerplate.password_resets 구조 내보내기
CREATE TABLE IF NOT EXISTS `password_resets` (
  `email` varchar(191) NOT NULL,
  `token` varchar(191) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  KEY `password_resets_email_index` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 laravel_crud_boilerplate.password_resets:~0 rows (대략적) 내보내기

-- 테이블 laravel_crud_boilerplate.personal_access_tokens 구조 내보내기
CREATE TABLE IF NOT EXISTS `personal_access_tokens` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(191) NOT NULL,
  `tokenable_id` bigint(20) unsigned NOT NULL,
  `name` varchar(191) NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 laravel_crud_boilerplate.personal_access_tokens:~0 rows (대략적) 내보내기

-- 테이블 laravel_crud_boilerplate.users 구조 내보내기
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(191) NOT NULL,
  `email` varchar(191) NOT NULL,
  `password` varchar(191) NOT NULL,
  `type` enum('Student','Tutor') NOT NULL,
  `phone` varchar(191) DEFAULT NULL,
  `about` varchar(191) DEFAULT NULL,
  `is_admin` tinyint(1) NOT NULL DEFAULT 0,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=52 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 laravel_crud_boilerplate.users:~10 rows (대략적) 내보내기
INSERT INTO `users` (`id`, `name`, `email`, `password`, `type`, `phone`, `about`, `is_admin`, `email_verified_at`, `remember_token`, `created_at`, `updated_at`, `deleted_at`) VALUES
	(1, 'Tester Example', 'tester@example.com', '$2y$10$lfmZO2CPeM.YW/8Dzqoa7OtK/WoZHaSLS1BI6dbJ8oclChQc1NuIm', 'Tutor', '(478) 321-3545', 'Animi iure dolorum consequatur voluptatibus voluptas et fugit asperiores.', 1, NULL, 'zpk8EYE7t3', '2021-07-25 19:08:52', '2021-07-25 19:08:52', NULL),
	(2, 'Aric Reinger', 'klebsack@example.com', '$2y$10$AniXPfhivwfJoU/Gw4PzCu581cgkF4tCB2JiatbXqDbwUr.xuXZP6', 'Student', '+1-958-203-1790', 'Nostrum veritatis dolores distinctio rem impedit dolorum aut.', 0, NULL, 'XK5ZZX8SPi', '2021-07-25 19:08:55', '2021-07-25 19:08:55', NULL),
	(3, 'Green Green', 'leslie18@example.org', '$2y$10$8257lL3bLCefe8vrXcObm.AwfAGBhbOVNIZkvPHUpoUWiSvAr8Jky', 'Tutor', '+19903772004', 'Qui labore et quas excepturi fugiat possimus expedita esse tempora perspiciatis et sit.', 0, NULL, '4XzcGtbs0J', '2021-07-25 19:08:55', '2021-07-25 19:08:55', NULL),
	(4, 'Jerrod Lowe', 'claudia88@example.org', '$2y$10$yOlHkoJZa9r8Gt3CnZPjA.uEUEGTGpS2hQJO9formCETbK0j2h.Xm', 'Student', '1-743-754-5516', 'Et omnis ea eos pariatur architecto voluptatum esse qui ut pariatur adipisci quis velit.', 0, NULL, '6wDoOkxlaN', '2021-07-25 19:08:55', '2021-07-25 19:08:55', NULL),
	(5, 'Dr. Camilla Waelchi PhD', 'maynard19@example.org', '$2y$10$kRh7TVXVPYdCXLWf3txYeOrT.u55tZhpTnJxHKmxdqqWoqdbZQzaC', 'Tutor', '1-850-567-1509', 'Veritatis dicta amet veritatis nisi esse labore autem autem architecto.', 0, NULL, 'Vr0DGYwSHM', '2021-07-25 19:08:55', '2021-07-25 19:08:55', NULL),
	(6, 'Mariam Jones', 'bechtelar.vaughn@example.org', '$2y$10$wSPBJM2rIrVsEJuVao5ITe8AKtWLVHyI9zsYltylizAZEa9/6d306', 'Student', '+1.235.778.2949', 'Quia sed eius ut suscipit est repellat.', 0, NULL, 'zCSVwSRvw0', '2021-07-25 19:08:55', '2021-07-25 19:08:55', NULL),
	(7, 'Dr. Suzanne Kshlerin', 'anahi.bailey@example.com', '$2y$10$zZhsOjOxeZSa0KMbinM//.ZFjA.dpi77XrvckTmmiA.cU4T2IAAFG', 'Tutor', '+16564364181', 'Non et possimus dolorem autem esse ut et aut veritatis.', 0, NULL, 'XAzb8anRpG', '2021-07-25 19:08:55', '2021-07-25 19:08:55', NULL),
	(8, 'Leanna Denesik', 'santos73@example.org', '$2y$10$AsljOiUPgl8eo2Vj3ArrrOaevxH1pZeN6walxj3UDYfRsWRrtLJp.', 'Student', '693.651.2791', 'Consequatur a optio deleniti vero veniam incidunt assumenda veniam quaerat cupiditate accusamus aut nam.', 0, NULL, 'w4k1kaDfW5', '2021-07-25 19:08:55', '2021-07-25 19:08:55', NULL),
	(9, 'Prof. Antonette Wuckert', 'fohara@example.net', '$2y$10$UgmIanrw5WO6Muir294D0uq9gWG0ydbNI4SRQpNDkH7wEQaiiRKV6', 'Tutor', '(561) 389-9024', 'Iure a ut est harum consectetur dolorum necessitatibus quia eaque molestiae aspernatur est quo.', 0, NULL, 'BSdave1B0U', '2021-07-25 19:08:55', '2021-07-25 19:08:55', NULL),
	(10, 'Prof. Demetrius Littel MD', 'rtoy@example.com', '$2y$10$r9lUo5N745nYPpsw4QzoMOtf.A1rT4Y006s9BLcWE.kJi9gvDi.DC', 'Student', '+1-697-597-5158', 'Quia expedita vitae et et et et error.', 0, NULL, 'JiLt8UUddw', '2021-07-25 19:08:55', '2021-07-25 19:08:55', NULL);

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
