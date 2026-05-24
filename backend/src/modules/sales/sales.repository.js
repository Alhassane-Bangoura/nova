const db = require('../../config/database');

const initSalesTable = () => {
    db.run(`
        CREATE TABLE IF NOT EXISTS sales (
            id TEXT PRIMARY KEY,
            product_id TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price REAL NOT NULL,
            total_price REAL NOT NULL,
            client_name TEXT NOT NULL,
            client_phone TEXT NOT NULL,
            neighborhood TEXT NOT NULL,
            payment_method TEXT NOT NULL, -- 'ORANGE_MONEY' ou 'ESPECES'
            status TEXT DEFAULT 'PENDING', -- 'PENDING', 'DELIVERED', 'CANCELLED'
            is_synced INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (product_id) REFERENCES products(id)
        )
    `);
};
initSalesTable();

const insert = (sale) => {
    return new Promise((resolve, reject) => {
        const sql = `
            INSERT INTO sales (
                id, product_id, quantity, unit_price, total_price, 
                client_name, client_phone, neighborhood, payment_method, 
                status, is_synced, created_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        db.run(sql, [
            sale.id, sale.product_id, sale.quantity, sale.unit_price, sale.total_price,
            sale.client_name, sale.client_phone, sale.neighborhood, sale.payment_method,
            sale.status, sale.is_synced, sale.created_at
        ], function(err) {
            if (err) reject(err);
            else resolve(sale);
        });
    });
};

const updateStatus = (saleId, status) => {
    return new Promise((resolve, reject) => {
        db.run(`UPDATE sales SET status = ? WHERE id = ?`, [status, saleId], function(err) {
            if (err) reject(err);
            else resolve(this.changes);
        });
    });
};

const findById = (saleId) => {
    return new Promise((resolve, reject) => {
        db.get(`SELECT * FROM sales WHERE id = ?`, [saleId], (err, row) => {
            if (err) reject(err);
            else resolve(row);
        });
    });
};

module.exports = { insert, updateStatus, findById };
