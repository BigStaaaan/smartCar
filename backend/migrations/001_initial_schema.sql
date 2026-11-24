-- SmartCar MySQL Database Schema (existing tables only)
-- Generated from Sequelize models in:
--   - src/services/authentication/authentication.service.js (users)
--   - src/modules/university-verification/verification.service.js (verification_audits)

CREATE TABLE IF NOT EXISTS `users` (
  `id` CHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `firebase_uid` VARCHAR(255) NOT NULL,
  `full_name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `account_type` ENUM('STUDENT', 'STAFF') NOT NULL,
  `university` VARCHAR(255) NOT NULL,
  `email_verified` TINYINT(1) NOT NULL DEFAULT 0,
  `university_verified` TINYINT(1) NOT NULL DEFAULT 0,
  `student_card_url` VARCHAR(255) NULL,
  `verification_status` ENUM(
    'NOT_SUBMITTED',
    'PENDING',
    'APPROVED',
    'REJECTED',
    'REQUIRES_RESUBMISSION'
  ) NOT NULL DEFAULT 'NOT_SUBMITTED',
  `student_id` VARCHAR(255) NULL,
  `faculty` VARCHAR(255) NULL,
  `department` VARCHAR(255) NULL,
  `submitted_at` DATETIME NULL,
  `reviewed_at` DATETIME NULL,
  `rejection_reason` TEXT NULL,
  `role` ENUM('PASSENGER', 'DRIVER') NOT NULL DEFAULT 'PASSENGER',
  `active_mode` ENUM('PASSENGER', 'DRIVER') NOT NULL DEFAULT 'PASSENGER',
  `driver_profile` JSON NULL,
  `status` ENUM('PENDING', 'ACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'PENDING',
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_firebase_uid_unique` (`firebase_uid`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `verification_audits` (
  `id` CHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `firebase_uid` VARCHAR(255) NOT NULL,
  `action` ENUM('SUBMITTED', 'APPROVED', 'REJECTED', 'RESUBMISSION') NOT NULL,
  `actor_uid` VARCHAR(255) NULL,
  `reason` TEXT NULL,
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  KEY `verification_audits_firebase_uid_idx` (`firebase_uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
