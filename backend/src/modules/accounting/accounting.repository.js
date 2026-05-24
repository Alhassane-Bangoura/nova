const { getQuery, allQuery } = require('../../utils/databaseHelper');

class AccountingRepository {
    // 1. Historique complet de la caisse
    static async getCashHistory() {
        return await allQuery(`
            SELECT id, type, amount, reference_type, reference_id, balance_after, transaction_date 
            FROM cash_transactions 
            ORDER BY transaction_date DESC
        `);
    }

    // 2. Profit Brut vs Profit Net
    static async getProfitabilitySummary() {
        const profit = await getQuery(`SELECT SUM(total_profit) as gross_profit FROM stock_outputs`);
        const expenses = await getQuery(`SELECT SUM(amount) as total_expenses FROM expenses`);
        
        const grossProfit = profit?.gross_profit || 0;
        const totalExpenses = expenses?.total_expenses || 0;
        const netProfit = grossProfit - totalExpenses;

        return {
            gross_profit: grossProfit,
            total_expenses: totalExpenses,
            net_profit: netProfit
        };
    }

    // 3. Dépenses par catégorie
    static async getExpensesByCategory() {
        return await allQuery(`
            SELECT category, SUM(amount) as total_amount 
            FROM expenses 
            GROUP BY category 
            ORDER BY total_amount DESC
        `);
    }

    // 4. Analytics Financiers (Evolution du net)
    static async getNetProfitEvolution() {
        return await allQuery(`
            SELECT 
                d.day,
                COALESCE(p.daily_gross, 0) as daily_gross,
                COALESCE(e.daily_expense, 0) as daily_expense,
                (COALESCE(p.daily_gross, 0) - COALESCE(e.daily_expense, 0)) as daily_net
            FROM (
                SELECT DISTINCT date(output_date) as day FROM stock_outputs
                UNION
                SELECT DISTINCT date(expense_date) as day FROM expenses
            ) d
            LEFT JOIN (
                SELECT date(output_date) as day, SUM(total_profit) as daily_gross 
                FROM stock_outputs GROUP BY day
            ) p ON d.day = p.day
            LEFT JOIN (
                SELECT date(expense_date) as day, SUM(amount) as daily_expense 
                FROM expenses GROUP BY day
            ) e ON d.day = e.day
            ORDER BY d.day DESC LIMIT 30
        `);
    }
}
module.exports = AccountingRepository;
