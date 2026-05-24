const db = require('../../config/database');

const initDeliveryTable = () => {
    db.run(`
        CREATE TABLE IF NOT EXISTS deliveries (
            id TEXT PRIMARY KEY,
            sale_id TEXT NOT NULL,
            motard_name TEXT NOT NULL,
            status TEXT DEFAULT 'ASSIGNED', -- 'ASSIGNED', 'DELIVERED', 'FAILED'
            delivery_fee REAL DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY (sale_id) REFERENCES sales(id)
        )
    `);
};
initDeliveryTable();

const insert = (delivery) => {
    return new Promise((resolve, reject) => {
        const sql = `
            INSERT INTO deliveries (id, sale_id, motard_name, status, delivery_fee, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
        `;
        db.run(sql, [delivery.id, delivery.sale_id, delivery.motard_name, delivery.status, delivery.delivery_fee, delivery.created_at], function(err) {
            if (err) reject(err);
            else resolve(delivery);
        });
    });
};

const updateStatus = (deliveryId, status) => {
    return new Promise((resolve, reject) => {
        db.run(`UPDATE deliveries SET status = ? WHERE id = ?`, [status, deliveryId], function(err) {
            if (err) reject(err);
            else resolve(this.changes);
        });
    });
};

const findById = (deliveryId) => {
    return new Promise((resolve, reject) => {
        db.get(`SELECT * FROM deliveries WHERE id = ?`, [deliveryId], (err, row) => {
            if (err) reject(err);
            else resolve(row);
        });
    });
};

module.exports = { insert, updateStatus, findById };
