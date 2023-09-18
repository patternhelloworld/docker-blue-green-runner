-- --------------------------------------------------------
-- 호스트:                          127.0.0.1
-- 서버 버전:                        8.0.34 - MySQL Community Server - GPL
-- 서버 OS:                        Linux
-- HeidiSQL 버전:                  12.5.0.6677
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- spring_sample_h_auth 데이터베이스 구조 내보내기
CREATE DATABASE IF NOT EXISTS `spring_sample_h_auth` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `spring_sample_h_auth`;

-- 테이블 spring_sample_h_auth.oauth_access_token 구조 내보내기
CREATE TABLE IF NOT EXISTS `oauth_access_token` (
  `token_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `token` blob,
  `authentication_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `client_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `authentication` blob,
  `refresh_token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`authentication_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 spring_sample_h_auth.oauth_access_token:~1 rows (대략적) 내보내기

-- 테이블 spring_sample_h_auth.oauth_client_details 구조 내보내기
CREATE TABLE IF NOT EXISTS `oauth_client_details` (
  `client_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `client_secret` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `scope` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `authorized_grant_types` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `web_server_redirect_uri` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `authorities` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `access_token_validity` int DEFAULT NULL,
  `refresh_token_validity` int DEFAULT NULL,
  `additional_information` varchar(4096) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `autoapprove` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`client_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 spring_sample_h_auth.oauth_client_details:~1 rows (대략적) 내보내기
INSERT INTO `oauth_client_details` (`client_id`, `client_secret`, `scope`, `authorized_grant_types`, `web_server_redirect_uri`, `authorities`, `access_token_validity`, `refresh_token_validity`, `additional_information`, `autoapprove`) VALUES
	('spring_sample_h_auth', '5b22fcb8b72ceebd611e61126c0b2030', 'read,write', 'password', 'http://localhost:8081/oauth2/callback', NULL, 36000, 50000, NULL, 'true');

-- 테이블 spring_sample_h_auth.oauth_refresh_token 구조 내보내기
CREATE TABLE IF NOT EXISTS `oauth_refresh_token` (
  `token_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `token` blob,
  `authentication` blob
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 spring_sample_h_auth.oauth_refresh_token:~0 rows (대략적) 내보내기

-- 테이블 spring_sample_h_auth.oauth_removed_access_token 구조 내보내기
CREATE TABLE IF NOT EXISTS `oauth_removed_access_token` (
  `access_token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reason` int DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`access_token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 spring_sample_h_auth.oauth_removed_access_token:~0 rows (대략적) 내보내기

-- 테이블 spring_sample_h_auth.organization 구조 내보내기
CREATE TABLE IF NOT EXISTS `organization` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `active` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 spring_sample_h_auth.organization:~1 rows (대략적) 내보내기
INSERT INTO `organization` (`id`, `name`, `active`, `created_at`, `updated_at`) VALUES
	(1, 'Fine', '1', '2023-08-29 13:02:43', '2023-08-29 13:02:43');

-- 테이블 spring_sample_h_auth.role 구조 내보내기
CREATE TABLE IF NOT EXISTS `role` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 spring_sample_h_auth.role:~1 rows (대략적) 내보내기
INSERT INTO `role` (`id`, `name`, `description`, `created_at`, `updated_at`) VALUES
	(1, 'MANAGER', '1', '2023-08-29 13:03:16', '2023-08-29 13:03:24');

-- 테이블 spring_sample_h_auth.user 구조 내보내기
CREATE TABLE IF NOT EXISTS `user` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `organization_id` bigint DEFAULT NULL,
  `fail_cnt` int DEFAULT '0',
  `active` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reset_token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reset_token_time` datetime DEFAULT NULL,
  `password_changed_at` datetime DEFAULT NULL,
  `password_expiration_date` datetime DEFAULT NULL,
  `password_failed_count` int DEFAULT '0',
  `password_ttl` bigint DEFAULT '0',
  `customGroup_id` bigint DEFAULT NULL,
  `customRole_id` bigint DEFAULT NULL,
  `is_using_2FA` bit(1) DEFAULT NULL,
  `totp_secret` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 spring_sample_h_auth.user:~6 rows (대략적) 내보내기
INSERT INTO `user` (`id`, `name`, `email`, `password`, `organization_id`, `fail_cnt`, `active`, `reset_token`, `reset_token_time`, `password_changed_at`, `password_expiration_date`, `password_failed_count`, `password_ttl`, `customGroup_id`, `customRole_id`, `is_using_2FA`, `totp_secret`, `created_at`, `updated_at`) VALUES
	(3, 'tester', 'test@test.com', '$2a$10$4UQrtrslrewmkzSg1f2XOujjvI2kLvFCg55GLeHJwcifVt6p171bC', 1, 0, NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '2023-07-26 14:34:12', '2023-08-29 13:02:47'),
	(4, 'tester2', 'test2@test.com', '$2a$10$4UQrtrslrewmkzSg1f2XOujjvI2kLvFCg55GLeHJwcifVt6p171bC', NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '2023-07-26 14:34:12', '2023-08-10 10:21:34'),
	(5, 'tester3', 'test3@test.com', '$2a$10$4UQrtrslrewmkzSg1f2XOujjvI2kLvFCg55GLeHJwcifVt6p171bC', NULL, 0, NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, NULL, NULL, NULL, '2023-07-26 14:34:12', '2023-08-10 10:21:34'),
	(7, 'tester61', 'tester6@test.com', '$2a$10$1m59zjIdDQC7aihC5LUDMeq8v1T0dWWJup/rXHPpygF4Fzqog2KJe', NULL, NULL, NULL, NULL, NULL, NULL, '2023-09-18 13:34:28', 0, 1209604, NULL, NULL, NULL, NULL, '2023-09-04 13:34:23', '2023-09-11 16:31:15'),
	(8, 'tester7', 'test7@test.com', '$2a$10$1kyzzOvJSu64Q04lxbVp3.3tYmDnFROGcot21j6LvMjI3EuhrUbCq', NULL, NULL, NULL, NULL, NULL, NULL, '2023-09-18 13:39:49', 0, 1209604, NULL, NULL, NULL, NULL, '2023-09-04 13:39:45', '2023-09-04 13:39:45'),
	(11, 'tester813111', 'test8@test.com', '$2a$10$AzRO6gVeAEIeJzLhP29rf.uy3Y1tbrPm0Az0D8ErHzP9kYKYZF7pW', NULL, NULL, NULL, NULL, NULL, NULL, '2023-09-18 15:27:56', 0, 1209604, NULL, NULL, NULL, NULL, '2023-09-04 15:27:52', '2023-09-15 15:22:38');

-- 테이블 spring_sample_h_auth.user_role 구조 내보내기
CREATE TABLE IF NOT EXISTS `user_role` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL,
  `role_id` bigint NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id_role_id` (`user_id`,`role_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 테이블 데이터 spring_sample_h_auth.user_role:~2 rows (대략적) 내보내기
INSERT INTO `user_role` (`id`, `user_id`, `role_id`, `created_at`, `updated_at`) VALUES
	(1, 3, 1, '2023-08-29 13:02:59', '2023-08-29 13:03:28'),
	(2, 1, 1, '2023-09-05 15:53:04', '2023-09-05 15:53:04');

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
