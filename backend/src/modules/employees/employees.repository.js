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

class EmployeesRepository {
    static async create(data) {
        const { v4: uuidv4 } = require('uuid');
        const id = uuidv4();
        const parts = (data.name || '').split(' ');
        const firstName = parts[0] || 'Inconnu';
        const lastName = parts.slice(1).join(' ');
        const now = new Date().toISOString();
        
        await runQuery(
            `INSERT INTO employees (id, first_name, last_name, email, role, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [id, firstName, lastName, data.email || `${id}@novagenix.com`, data.role || 'Membre', now, now]
        );
        return { id, name: data.name, role: data.role || 'Membre' };
    }

    static async getAll() {
        const rows = await allQuery('SELECT id, first_name || \' \' || last_name as name, role FROM employees ORDER BY first_name ASC');
        return rows;
    }

    static async update(id, data) {
        const parts = (data.name || '').split(' ');
        const firstName = parts[0] || 'Inconnu';
        const lastName = parts.slice(1).join(' ');

        await runQuery(
            'UPDATE employees SET first_name = ?, last_name = ?, role = ? WHERE id = ?',
            [firstName, lastName, data.role || 'Membre', id]
        );
        return { id, name: data.name, role: data.role || 'Membre' };
    }

    static async delete(id) {
        await runQuery('DELETE FROM employees WHERE id = ?', [id]);
    }
}

module.exports = EmployeesRepository;
