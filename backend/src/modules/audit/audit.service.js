const crypto = require('crypto');
const db = require('../../config/database');

const initAuditTable = () => {
    db.run(`
        CREATE TABLE IF NOT EXISTS audit_logs (
            id TEXT PRIMARY KEY,
            action TEXT NOT NULL,
            table_name TEXT NOT NULL,
            record_id TEXT NOT NULL,
            old_values TEXT,
            new_values TEXT,
            user_id TEXT,
            timestamp TEXT NOT NULL
        )
    `);
};
initAuditTable();

const logAction = (action, tableName, recordId, newValues, oldValues = null, userId = 'system') => {
    return new Promise((resolve, reject) => {
        const sql = `
            INSERT INTO audit_logs (id, action, table_name, record_id, old_values, new_values, user_id, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;
        db.run(sql, [
            crypto.randomUUID(),
            action,
            tableName,
            recordId,
            oldValues ? JSON.stringify(oldValues) : null,
            newValues ? JSON.stringify(newValues) : null,
            userId,
            new Date().toISOString()
        ], function(err) {
            if (err) {
                console.error("❌ [FATAL] Erreur lors de l'écriture dans l'Audit Log :", err);
                reject(err);
            } else {
                resolve();
            }
        });
    });
};

module.exports = { logAction };
