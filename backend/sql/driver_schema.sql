-- Import dans la base cible apres initialisation de users par DEV 1.
-- Alternative aux migrations Sequelize Driver. Importer une seule fois.

CREATE TABLE vehicles (
  id CHAR(36) COLLATE utf8mb4_bin NOT NULL,
  owner_id CHAR(36) COLLATE utf8mb4_bin NOT NULL,
  make VARCHAR(255) NOT NULL,
  model VARCHAR(255) NOT NULL,
  color VARCHAR(255) NOT NULL,
  year SMALLINT UNSIGNED NULL,
  registration_number VARCHAR(16) NOT NULL,
  passenger_capacity INT UNSIGNED NOT NULL,
  photo_key VARCHAR(255) NULL,
  registration_photo_key VARCHAR(255) NULL,
  verification_status ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY vehicles_id_owner_unique (id, owner_id),
  KEY vehicles_owner_idx (owner_id),
  CONSTRAINT vehicles_owner_fk FOREIGN KEY (owner_id)
    REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT vehicles_capacity_check CHECK (passenger_capacity >= 1),
  CONSTRAINT vehicles_year_check CHECK (year IS NULL OR year >= 1900)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE trips (
  id CHAR(36) COLLATE utf8mb4_bin NOT NULL,
  driver_id CHAR(36) COLLATE utf8mb4_bin NOT NULL,
  vehicle_id CHAR(36) COLLATE utf8mb4_bin NOT NULL,
  origin TEXT NOT NULL,
  destination TEXT NOT NULL,
  departure_at DATETIME(3) NOT NULL,
  seats INT UNSIGNED NOT NULL,
  contribution_dh TINYINT UNSIGNED NULL,
  status ENUM('published', 'in_progress', 'completed', 'cancelled') NOT NULL DEFAULT 'published',
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3) NOT NULL,
  PRIMARY KEY (id),
  KEY trips_driver_status_departure_idx (driver_id, status, departure_at),
  KEY trips_vehicle_driver_idx (vehicle_id, driver_id),
  CONSTRAINT trips_driver_fk FOREIGN KEY (driver_id)
    REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT trips_vehicle_owner_fk FOREIGN KEY (vehicle_id, driver_id)
    REFERENCES vehicles (id, owner_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT trips_seats_check CHECK (seats >= 1),
  CONSTRAINT trips_contribution_check CHECK (contribution_dh BETWEEN 0 AND 40)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
