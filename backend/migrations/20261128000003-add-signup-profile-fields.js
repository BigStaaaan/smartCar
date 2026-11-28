'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('users', 'first_name', {
      type: Sequelize.STRING(100),
      allowNull: true,
    });
    await queryInterface.addColumn('users', 'last_name', {
      type: Sequelize.STRING(100),
      allowNull: true,
    });
    await queryInterface.addColumn('users', 'date_of_birth', {
      type: Sequelize.DATEONLY,
      allowNull: true,
    });
    await queryInterface.addColumn('users', 'sex', {
      type: Sequelize.ENUM('male', 'female'),
      allowNull: true,
    });
    await queryInterface.addColumn('users', 'auth_provider', {
      type: Sequelize.ENUM('email', 'google', 'apple'),
      allowNull: false,
      defaultValue: 'email',
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('users', 'auth_provider');
    await queryInterface.removeColumn('users', 'sex');
    await queryInterface.removeColumn('users', 'date_of_birth');
    await queryInterface.removeColumn('users', 'last_name');
    await queryInterface.removeColumn('users', 'first_name');
  },
};
