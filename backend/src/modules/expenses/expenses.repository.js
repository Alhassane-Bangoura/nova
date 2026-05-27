const { runQuery, getQuery, allQuery } = require('../../utils/databaseHelper');

class ExpensesRepository {
    static async beginTransaction() { await runQuery('BEGIN IMMEDIATE TRANSACTION'); }
    static async commitTransaction() { await runQuery('COMMIT'); }
    static async rollbackTransaction() { await runQuery('ROLLBACK'); }

    static async insertExpense(category, amount, description, productId) {
        const result = await runQuery(
            `INSERT INTO expenses (category, amount, description, product_id) VALUES (?, ?, ?, ?)`,
            [category, amount, description, productId || null]
        );
        return result.lastID;
    }

    static async getLastCashBalance() {
        const row = await getQuery(`SELECT balance_after FROM cash_transactions ORDER BY id DESC LIMIT 1`);
        return row ? row.balance_after : 0;
    }

    static async insertCashTransaction(type, amount, refType, refId, balanceAfter) {
        await runQuery(
            `INSERT INTO cash_transactions (type, amount, reference_type, reference_id, balance_after) 
             VALUES (?, ?, ?, ?, ?)`,
            [type, amount, refType, refId, balanceAfter]
        );
    }
    
    static async getAllExpenses() {
        return await allQuery(`
            SELECT e.*, p.name as product_name
            FROM expenses e
            LEFT JOIN products p ON e.product_id = p.id
            ORDER BY e.expense_date DESC
        `);
    }
}
module.exports = ExpensesRepository;
