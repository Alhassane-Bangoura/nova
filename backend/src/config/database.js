const sqlite3 = require("sqlite3").verbose();
const path = require("path");
const fs = require("fs");

const dbDir = path.resolve(__dirname, "../../database");
if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
}

// On utilise enterprise.db comme demandé
const dbPath = path.join(dbDir, "enterprise.db");

const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error("❌ [FATAL] Erreur connexion SQLite :", err.message);
        process.exit(1); 
    } else {
        console.log("✅ Base de données ERP (enterprise.db) connectée.");
        
        // 🛡️ ACTIVATION OBLIGATOIRE DES CLES ETRANGERES POUR UN ERP
        db.run("PRAGMA foreign_keys = ON;", (err) => {
            if (err) console.error("❌ Échec de l'activation des Foreign Keys:", err.message);
            else console.log("🛡️ Intégrité Référentielle (Foreign Keys) activée.");
        });
        
        // ⚡ ACTIVATION DU MODE WAL (Write-Ahead Logging)
        // Permet de lire et écrire en même temps sans verrouiller la base. Crucial pour les performances.
        db.run("PRAGMA journal_mode = WAL;", () => {
             console.log("⚡ Mode WAL activé (Performances Maximales).");
        });
        
        // Timeout pour éviter les SQLITE_BUSY si plusieurs requêtes d'écriture concurrentes
        db.run("PRAGMA busy_timeout = 5000;");

        // ⚡ CACHE: augmenter la taille du cache pour accélérer les lectures répétées
        db.run("PRAGMA cache_size = -64000;"); // 64 MB cache

        // ⚡ SYNCHRONOUS: réduire les flush disque (safe avec WAL)
        db.run("PRAGMA synchronous = NORMAL;");

        // ⚡ TEMP STORE: mettre les tables temporaires en mémoire
        db.run("PRAGMA temp_store = MEMORY;");

        // ⚡ INDEX sur les colonnes les plus requêtées
        db.run(`CREATE INDEX IF NOT EXISTS idx_stock_outputs_date ON stock_outputs(output_date);`);
        db.run(`CREATE INDEX IF NOT EXISTS idx_stock_outputs_product ON stock_outputs(product_id);`);
        db.run(`CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date);`);
        db.run(`CREATE INDEX IF NOT EXISTS idx_audit_logs_date ON audit_logs(created_at);`);
        db.run(`CREATE INDEX IF NOT EXISTS idx_audit_logs_type ON audit_logs(action_type);`);
        db.run(`CREATE INDEX IF NOT EXISTS idx_inventory_batches_product ON inventory_batches(product_id);`);
        db.run(`CREATE INDEX IF NOT EXISTS idx_cash_transactions_id ON cash_transactions(id DESC);`);
    }
});

module.exports = db;
