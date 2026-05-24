const db = require('../../config/database');

const initPurchasesTable = () => {
    db.run(`
        CREATE TABLE IF NOT EXISTS purchases (
            id TEXT PRIMARY KEY,
            product_id TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            total_cost REAL NOT NULL,
            supplier_name TEXT NOT NULL,
            is_synced INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (product_id) REFERENCES products(id)
        )
    `);
};
initPurchasesTable();

const insert = (purchase) => {
    return new Promise((resolve, reject) => {
        const sql = `
            INSERT INTO purchases (id, product_id, quantity, total_cost, supplier_name, is_synced, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        `;
        db.run(sql, [
            purchase.id, purchase.product_id, purchase.quantity, 
            purchase.total_cost, purchase.supplier_name, 
            purchase.is_synced, purchase.created_at
        ], function(err) {
            if (err) reject(err);
            else resolve(purchase);
        });
    });
};

module.exports = { insert };
