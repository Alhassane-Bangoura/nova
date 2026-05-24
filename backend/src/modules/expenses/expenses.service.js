const ExpensesRepository = require('./expenses.repository');
const db = require('../../config/database');

class ExpensesService {
    static async createExpense(data) {
        const { category, amount, description } = data;
        if (!category || !amount || amount <= 0) {
            throw new Error('Catégorie et montant valide requis.');
        }

        try {
            await ExpensesRepository.beginTransaction();

            const currentCash = await ExpensesRepository.getLastCashBalance();

            // Vérification du solde avant d'aller plus loin
            if (currentCash < amount) {
                await ExpensesRepository.rollbackTransaction();
                const err = new Error('INSUFFICIENT_CASH');
                err.currentCash = currentCash;
                err.requested = amount;
                throw err;
            }

            const expenseId = await ExpensesRepository.insertExpense(category, amount, description);
            const newBalance = currentCash - amount;
            await ExpensesRepository.insertCashTransaction('OUT', amount, 'EXPENSE', expenseId, newBalance);

            await ExpensesRepository.commitTransaction();

            // -- Audit log --
            db.run(`INSERT INTO audit_logs (action_type, entity_name, entity_id, description, employee_name) VALUES (?, ?, ?, ?, ?)`,
                ['DEPENSE', 'expenses', expenseId, `Dépense ${category}: ${amount} GNF - ${description || ''}`, 'Système']);

            return { id: expenseId, category, amount, new_cash_balance: newBalance };
        } catch (error) {
            await ExpensesRepository.rollbackTransaction();
            throw error;
        }
    }
    
    static async getExpenses() {
        return await ExpensesRepository.getAllExpenses();
    }
}
module.exports = ExpensesService;
