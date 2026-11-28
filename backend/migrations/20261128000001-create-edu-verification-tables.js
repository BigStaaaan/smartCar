'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('universities', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      name: {
        type: Sequelize.STRING(255),
        allowNull: false,
        unique: true,
      },
      email_domains: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      is_active: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: true,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
    });

    await queryInterface.createTable('university_verification_requests', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      user_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'users',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      },
      firebase_uid: {
        type: Sequelize.STRING(128),
        allowNull: false,
      },
      account_type: {
        type: Sequelize.ENUM('student', 'staff'),
        allowNull: false,
      },
      university_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'universities',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      },
      university_name: {
        type: Sequelize.STRING(255),
        allowNull: false,
      },
      university_email: {
        type: Sequelize.STRING(255),
        allowNull: false,
      },
      document_storage_path: {
        type: Sequelize.STRING(512),
        allowNull: false,
      },
      status: {
        type: Sequelize.ENUM('pending', 'approved', 'declined'),
        allowNull: false,
        defaultValue: 'pending',
      },
      rejection_reason: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      reviewed_by: {
        type: Sequelize.STRING(128),
        allowNull: true,
      },
      reviewed_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      submitted_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
    });

    await queryInterface.addIndex('university_verification_requests', ['firebase_uid']);
    await queryInterface.addIndex('university_verification_requests', ['user_id']);
    await queryInterface.addIndex('university_verification_requests', ['university_id']);
    await queryInterface.addIndex('university_verification_requests', ['status']);
  },

  async down(queryInterface) {
    await queryInterface.dropTable('university_verification_requests');
    await queryInterface.dropTable('universities');
  },
};
