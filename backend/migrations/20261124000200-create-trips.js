module.exports = {
  async up(queryInterface) {
    return queryInterface.sequelize.query(`
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
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
  },

  async down(queryInterface) {
    return queryInterface.dropTable('trips');
  },
};
