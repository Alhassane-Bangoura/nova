const db = require('../../config/database');

const initInventoryTable = () => {
    db.run(`
        CREATE TABLE IF NOT EXISTS inventory (
            product_id TEXT PRIMARY KEY,
            quantity INTEGER DEFAULT 0,
            local_updated_at TEXT NOT NULL,
            FOREIGN KEY (product_id) REFERENCES products(id)
        )
    `);
};
initInventoryTable();

const getStock = (productId) => {
    return new Promise((resolve, reject) => {
        db.get(`SELECT quantity FROM inventory WHERE product_id = ?`, [productId], (err, row) => {
            if (err) reject(err);
            else resolve(row ? row.quantity : 0);
        });
    });
};

const updateStock = (productId, qtyChange) => {
    return new Promise((resolve, reject) => {
        const now = new Date().toISOString();
        // UPSERT (Crée la ligne si elle n'existe pas, sinon la met à jour)
        db.run(`
            INSERT INTO inventory (product_id, quantity, local_updated_at)
            VALUES (?, ?, ?)
            ON CONFLICT(product_id) DO UPDATE SET 
            quantity = quantity + ?, 
            local_updated_at = ?
        `, [productId, qtyChange, now, qtyChange, now], function(err) {
            if (err) reject(err);
            else resolve();
        });
    });
};

module.exports = { getStock, updateStock };
