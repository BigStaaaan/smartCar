'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('users', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      firebase_uid: {
        type: Sequelize.STRING,
        allowNull: false,
        unique: true,
      },
      full_name: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      email: {
        type: Sequelize.STRING,
        allowNull: false,
        unique: true,
      },
      account_type: {
        type: Sequelize.ENUM('STUDENT', 'STAFF'),
        allowNull: false,
      },
      university: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      email_verified: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
      university_verified: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
      student_card_url: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      verification_status: {
        type: Sequelize.ENUM(
          'NOT_SUBMITTED',
          'PENDING',
          'APPROVED',
          'REJECTED',
          'REQUIRES_RESUBMISSION',
        ),
        allowNull: false,
        defaultValue: 'NOT_SUBMITTED',
      },
      student_id: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      faculty: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      department: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      submitted_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      reviewed_at: {
        type: Sequelize.DATE,
        allowNull: true,
      },
      rejection_reason: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      role: {
        type: Sequelize.ENUM('PASSENGER', 'DRIVER'),
        allowNull: false,
        defaultValue: 'PASSENGER',
      },
      active_mode: {
        type: Sequelize.ENUM('PASSENGER', 'DRIVER'),
        allowNull: false,
        defaultValue: 'PASSENGER',
      },
      driver_profile: {
        type: Sequelize.JSON,
        allowNull: true,
      },
      status: {
        type: Sequelize.ENUM('PENDING', 'ACTIVE', 'SUSPENDED'),
        allowNull: false,
        defaultValue: 'PENDING',
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });

    await queryInterface.createTable('verification_audits', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      firebase_uid: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      action: {
        type: Sequelize.ENUM('SUBMITTED', 'APPROVED', 'REJECTED', 'RESUBMISSION'),
        allowNull: false,
      },
      actor_uid: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      reason: {
        type: Sequelize.TEXT,
        allowNull: true,
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
      },
    });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('verification_audits');
    await queryInterface.dropTable('users');
  },
};
