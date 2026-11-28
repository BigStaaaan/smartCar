'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('university_verification_requests', 'profile_photo_storage_path', {
      type: Sequelize.STRING(512),
      allowNull: true,
    });
    await queryInterface.addColumn('university_verification_requests', 'university_email_verified', {
      type: Sequelize.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('university_verification_requests', 'university_email_verified');
    await queryInterface.removeColumn('university_verification_requests', 'profile_photo_storage_path');
  },
};
