const db = require('../config/database');

const runMigration = () => {
    console.log("⏳ Démarrage de la migration de la base de données (Schéma Initial)...");

    db.serialize(() => {
        // 0. DROP TABLES IF EXIST pour s'assurer du nouveau schéma
        db.run('DROP TABLE IF EXISTS stock_outputs;');
        db.run('DROP TABLE IF EXISTS inventory_batches;');
        db.run('DROP TABLE IF EXISTS expenses;');
        db.run('DROP TABLE IF EXISTS cash_transactions;');
        db.run('DROP TABLE IF EXISTS sanctions;');
        db.run('DROP TABLE IF EXISTS products;');

        // 1. Table PRODUCTS
        db.run(`
            CREATE TABLE IF NOT EXISTS products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                category TEXT NOT NULL,
                color TEXT,
                min_stock INTEGER DEFAULT 30,
                selling_price REAL NOT NULL,
                image_url TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        `);

        // 2. Table INVENTORY_BATCHES (Les Achats Chine / Lots)
        db.run(`
            CREATE TABLE IF NOT EXISTS inventory_batches (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                product_id INTEGER NOT NULL,
                supplier_name TEXT NOT NULL,
                quantity_received INTEGER NOT NULL,
                quantity_remaining INTEGER NOT NULL,
                purchase_cost REAL NOT NULL,
                transport_cost REAL NOT NULL,
                unit_cost_real REAL NOT NULL,
                batch_date DATETIME DEFAULT CURRENT_TIMESTAMP,
                status TEXT DEFAULT 'En stock',
                FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
            );
        `);

        // 3. Table STOCK_OUTPUTS (Les Sorties Produits)
        db.run(`
            CREATE TABLE IF NOT EXISTS stock_outputs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                product_id INTEGER NOT NULL,
                batch_id INTEGER NOT NULL,
                quantity INTEGER NOT NULL,
                selling_price REAL NOT NULL,
                total_revenue REAL NOT NULL,
                total_profit REAL NOT NULL,
                location TEXT NOT NULL,
                client_name TEXT,
                output_date DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT,
                FOREIGN KEY (batch_id) REFERENCES inventory_batches (id) ON DELETE RESTRICT
            );
        `);

        // 4. Table EXPENSES (Les Dépenses)
        db.run(`
            CREATE TABLE IF NOT EXISTS expenses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                category TEXT NOT NULL,
                amount REAL NOT NULL,
                description TEXT,
                expense_date DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        `);

        // 5. Table CASH_TRANSACTIONS (Historique financier / Caisse)
        db.run(`
            CREATE TABLE IF NOT EXISTS cash_transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type TEXT NOT NULL CHECK(type IN ('IN', 'OUT')),
                amount REAL NOT NULL,
                reference_type TEXT NOT NULL, -- ex: 'OUTPUT', 'EXPENSE', 'PURCHASE', 'MANUAL'
                reference_id INTEGER,
                balance_after REAL NOT NULL,
                transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        `);

        // 6. Table SANCTIONS
        db.run(`
            CREATE TABLE IF NOT EXISTS sanctions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                employee_name TEXT NOT NULL,
                amount REAL NOT NULL,
                reason TEXT NOT NULL,
                sanction_date DATETIME DEFAULT CURRENT_TIMESTAMP
            );
        `, (err) => {
            if (err) {
                console.error("❌ Erreur lors de la migration :", err.message);
            } else {
                console.log("✅ Migration terminée avec succès. Toutes les tables sont prêtes.");
            }
        });
    });
};

runMigration();
