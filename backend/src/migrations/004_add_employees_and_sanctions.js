const db = require('../config/database');

const runMigration = () => {
    console.log("⏳ Démarrage de la migration (Employés & Sanctions)...");

    db.serialize(() => {
        db.run(`
            CREATE TABLE IF NOT EXISTS employees (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                role TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        `);

        // Ajout des colonnes à la table sanctions
        db.run(`ALTER TABLE sanctions ADD COLUMN employee_id INTEGER REFERENCES employees(id);`, (err) => {
            if (err && !err.message.includes("duplicate column name")) {
                console.error("Erreur ajout employee_id:", err.message);
            }
        });

        db.run(`ALTER TABLE sanctions ADD COLUMN status TEXT DEFAULT 'En attente';`, (err) => {
            if (err && !err.message.includes("duplicate column name")) {
                console.error("Erreur ajout status:", err.message);
            }
        });

        console.log("✅ Migration 004 (Employés & Sanctions) terminée.");
    });
};

runMigration();
