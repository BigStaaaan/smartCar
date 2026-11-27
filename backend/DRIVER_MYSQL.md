# Installer la base Driver avec XAMPP

## 1. Préparer MariaDB

Démarrer **MySQL** dans le panneau XAMPP. Les commandes ci-dessous utilisent l'instance locale sur le port 3306 et le compte local XAMPP par défaut. Adapter la connexion si votre installation utilise un autre port ou un mot de passe. Depuis la racine du dépôt, dans PowerShell :

```powershell
cd backend
npm.cmd ci
$mysql = 'C:/xampp/mysql/bin/mysql.exe'
& $mysql --protocol=tcp --host=127.0.0.1 --port=3306 --user=root --execute "CREATE DATABASE IF NOT EXISTS smartcar CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
if ($LASTEXITCODE -ne 0) { throw 'MariaDB inaccessible ou création de smartcar refusée' }
$env:MYSQL_URL = 'mysql://root:@127.0.0.1:3306/smartcar'
```

## 2. Initialiser le schéma commun une seule fois

Pour une base neuve, utiliser **l'une** des méthodes de DEV 1. La commande suivante utilise le fichier SQL, qui crée uniquement les tables communes absentes. Si `users` et `verification_audits` existent déjà, passer à l'étape suivante. Si elles ont été créées via la migration Sequelize de DEV 1, passer également à l'étape suivante.

```powershell
& $mysql --protocol=tcp --host=127.0.0.1 --port=3306 --user=root --database=smartcar --execute "source migrations/001_initial_schema.sql"
if ($LASTEXITCODE -ne 0) { throw 'Initialisation du schéma commun échouée' }
```

## 3. Installer les tables Driver

Choisir **une seule méthode** pour la même base : importer le script SQL ou appliquer les migrations Sequelize Driver. Les deux définissent les mêmes tables.

### Option A — Importer dans phpMyAdmin

1. Sélectionner la base cible déjà initialisée par DEV 1. Vérifier que `users.id` est une clé primaire `CHAR(36)` en `utf8mb4_bin` et que `users` utilise InnoDB.
2. Vérifier que `vehicles` et `trips` sont absentes. Si une table existe déjà, comparer sa définition à la migration avant de poursuivre.
3. Ouvrir **Importer**, choisir [driver_schema.sql](sql/driver_schema.sql), garder le format **SQL** et l’encodage **UTF-8**, puis lancer l’import. Le script crée `vehicles`, puis `trips`, dans la base sélectionnée.
4. Vérifier que les deux tables apparaissent. En cas d’erreur, vérifier quelle table a été créée avant de relancer. MariaDB peut conserver la première création si la seconde échoue.

L’import ne renseigne pas `SequelizeMeta`.

### Option B — Appliquer les migrations Sequelize Driver manquantes

Toujours depuis `backend/`, exécuter ce bloc. Il vérifie la clé `users.id`, applique `vehicles` puis `trips` et ignore les tables Driver déjà créées par ces mêmes migrations. Si votre base possède des tables Driver provenant d'un autre schéma, comparer d'abord leur définition avec les migrations. En cas d'erreur, arrêter la procédure et conserver les tables existantes.

```powershell
@'
const sequelize = require('./src/config/database');

(async () => {
  try {
    const [keys] = await sequelize.query(
      "SELECT c.COLUMN_TYPE, c.COLLATION_NAME, c.COLUMN_KEY, t.ENGINE " +
      "FROM information_schema.COLUMNS c JOIN information_schema.TABLES t " +
      "ON c.TABLE_SCHEMA=t.TABLE_SCHEMA AND c.TABLE_NAME=t.TABLE_NAME " +
      "WHERE c.TABLE_SCHEMA=DATABASE() AND c.TABLE_NAME='users' AND c.COLUMN_NAME='id'",
      { logging: false },
    );
    const key = keys[0];
    if (key?.COLUMN_TYPE !== 'char(36)' || key.COLLATION_NAME !== 'utf8mb4_bin' ||
        key.COLUMN_KEY !== 'PRI' || key.ENGINE !== 'InnoDB') {
      throw new Error('Vérifier le schéma commun et la définition de users.id.');
    }

    const queryInterface = sequelize.getQueryInterface();
    const existing = new Set(await queryInterface.showAllTables());
    if (existing.has('trips') && !existing.has('vehicles')) {
      throw new Error('Schéma Driver incohérent.');
    }
    const migrations = [
      ['vehicles', './migrations/20261124000100-create-vehicles'],
      ['trips', './migrations/20261124000200-create-trips'],
    ];
    for (const [table, file] of migrations) {
      if (existing.has(table)) {
        console.log(table + ' : déjà présente, migration ignorée');
        continue;
      }
      await require(file).up(queryInterface);
      console.log(table + ' : migration appliquée');
    }
  } finally {
    await sequelize.close();
  }
})().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
'@ | node
if ($LASTEXITCODE -ne 0) { throw 'Installation du schéma Driver interrompue' }
```

Ce bloc vérifie les tables existantes à chaque lancement. Il ne renseigne pas `SequelizeMeta`. Si l'équipe adopte ensuite Sequelize CLI, les migrations déjà appliquées doivent être enregistrées dans son historique avant de lancer une migration automatique sur cette même base.

## 4. Lancer et vérifier

```powershell
& $mysql --protocol=tcp --host=127.0.0.1 --port=3306 --user=root --database=smartcar --execute "SHOW TABLES; SHOW CREATE TABLE trips"
npm.cmd test
npm.cmd start
```

Les API Driver utilisent l'identifiant du profil SmartCar associé au compte Firebase connecté. Les photos restent privées sous `backend/uploads/driver-vehicles/`. Si vous transférez la base dans un autre environnement local, transférez aussi ce dossier privé pour conserver les photos associées aux clés enregistrées en base.
