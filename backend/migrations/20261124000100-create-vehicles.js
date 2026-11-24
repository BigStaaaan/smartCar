module.exports = {
  async up(queryInterface) {
    return queryInterface.sequelize.query(`
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
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
  },

  async down(queryInterface) {
    return queryInterface.dropTable('vehicles');
  },
};
