const db = require('../config/database');

const runMigration = () => {
    console.log("⏳ Démarrage de la migration : 002_add_audit_logs...");

    db.serialize(() => {
        db.run('DROP TABLE IF EXISTS audit_logs');
        db.run(`
            CREATE TABLE IF NOT EXISTS audit_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                action_type TEXT NOT NULL,
                entity_name TEXT NOT NULL,
                entity_id INTEGER,
                description TEXT NOT NULL,
                employee_name TEXT DEFAULT 'Moussa',
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        `, (err) => {
            if (err) {
                console.error("❌ Erreur lors de la création de la table audit_logs :", err.message);
            } else {
                console.log("✅ Table audit_logs créée avec succès.");
            }
        });
    });
};

runMigration();
