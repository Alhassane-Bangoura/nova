const AccountingRepository = require('./accounting.repository');

class AccountingService {
    static async getFinancialControlCenterData() {
        const [
            cashHistory,
            profitSummary,
            expensesByCategory,
            netProfitEvolution
        ] = await Promise.all([
            AccountingRepository.getCashHistory(),
            AccountingRepository.getProfitabilitySummary(),
            AccountingRepository.getExpensesByCategory(),
            AccountingRepository.getNetProfitEvolution()
        ]);

        return {
            success: true,
            data: {
                profitSummary,
                expensesByCategory,
                netProfitEvolution,
                cashHistory
            }
        };
    }
    static async fundCaisse(amount, note) {
        const { runQuery, getQuery } = require('../../utils/databaseHelper');
        await runQuery('BEGIN IMMEDIATE TRANSACTION');
        try {
            const row = await getQuery(`SELECT balance_after FROM cash_transactions ORDER BY id DESC LIMIT 1`);
            const currentBalance = row ? row.balance_after : 0;
            const newBalance = currentBalance + amount;
            await runQuery(
                `INSERT INTO cash_transactions (type, amount, reference_type, reference_id, balance_after) VALUES (?, ?, ?, ?, ?)`,
                ['IN', amount, 'FUND', null, newBalance]
            );
            await runQuery('COMMIT');
            return { new_balance: newBalance, amount_added: amount, note };
        } catch (e) {
            await runQuery('ROLLBACK');
            throw e;
        }
    }
}

module.exports = AccountingService;
