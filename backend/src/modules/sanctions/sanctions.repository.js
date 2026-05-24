const db = require('../../config/database');

const runQuery = (sql, params = []) => new Promise((resolve, reject) => {
    db.run(sql, params, function(err) {
        if (err) reject(err);
        else resolve(this);
    });
});

const allQuery = (sql, params = []) => new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
    });
});

class SanctionsRepository {
    static async create(data) {
        // Amount is fixed at 5000 GNF according to rules
        const result = await runQuery(
            `INSERT INTO sanctions (employee_id, employee_name, reason, amount, status) 
             VALUES (?, (SELECT first_name || ' ' || last_name FROM employees WHERE id = ?), ?, ?, 'En attente')`,
            [data.employee_id, data.employee_id, data.reason, 5000]
        );
        return { id: result.lastID, ...data, amount: 5000, status: 'En attente' };
    }

    static async getAll() {
        return await allQuery(`
            SELECT s.*, e.first_name || ' ' || e.last_name as emp_name 
            FROM sanctions s
            LEFT JOIN employees e ON s.employee_id = e.id
            ORDER BY s.sanction_date DESC
        `);
    }

    static async getStats() {
        const stats = await allQuery(`
            SELECT 
                COUNT(*) as total_sanctions,
                SUM(CASE WHEN status = 'Payée' THEN amount ELSE 0 END) as total_collected,
                SUM(CASE WHEN status = 'En attente' THEN amount ELSE 0 END) as total_pending
            FROM sanctions
            WHERE status != 'Annulée'
        `);
        return stats[0];
    }

    static async updateStatus(id, status) {
        await runQuery(
            'UPDATE sanctions SET status = ? WHERE id = ?',
            [status, id]
        );
        return { id, status };
    }
}

module.exports = SanctionsRepository;
