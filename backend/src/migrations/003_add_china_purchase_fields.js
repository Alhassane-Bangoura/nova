const db = require('../config/database');

const runMigration = () => {
    console.log("⏳ Ajout des champs pour les achats Chine...");
    db.serialize(() => {
        db.run('ALTER TABLE inventory_batches ADD COLUMN order_date DATETIME;', (err) => {
            if (err && !err.message.includes('duplicate column name')) console.error(err.message);
        });
        db.run('ALTER TABLE inventory_batches ADD COLUMN reception_date DATETIME;', (err) => {
            if (err && !err.message.includes('duplicate column name')) console.error(err.message);
        });
        console.log("✅ Champs ajoutés avec succès.");
    });
};
runMigration();
