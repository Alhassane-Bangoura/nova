const { getQuery, allQuery } = require('../../utils/databaseHelper');

class AccountingRepository {
    static async getCashHistory(productId = null) {
        let where = '';
        const params = [];
        if (productId) {
            where = `WHERE 
                (c.reference_type = 'EXPENSE' AND e.product_id = ?) OR
                (c.reference_type = 'OUTPUT' AND so.product_id = ?) OR
                (c.reference_type = 'PURCHASE_CHINA' AND ib.product_id = ?)`;
            params.push(productId, productId, productId);
        }

        return await allQuery(`
            SELECT 
                c.id, c.type, c.amount, c.reference_type, c.reference_id, c.balance_after, c.transaction_date,
                CASE 
                    WHEN c.reference_type = 'EXPENSE' THEN COALESCE(e.category, 'Dépense') || ' - ' || COALESCE(e.description, '')
                    WHEN c.reference_type = 'OUTPUT' THEN 'Vente de produit (Réf: ' || c.reference_id || ')'
                    WHEN c.reference_type = 'PURCHASE_CHINA' THEN 'Achat Fournisseur Chine (Lot #' || c.reference_id || ')'
                    WHEN c.reference_type = 'TRANSPORT_RECEPTION' THEN 'Frais de Transport/Douane (Lot #' || c.reference_id || ')'
                    WHEN c.reference_type = 'FUND' THEN COALESCE(c.description, 'Alimentation Manuelle de Caisse')
                    ELSE c.reference_type 
                END as description
            FROM cash_transactions c
            LEFT JOIN expenses e ON c.reference_type = 'EXPENSE' AND c.reference_id = e.id
            LEFT JOIN stock_outputs so ON c.reference_type = 'OUTPUT' AND c.reference_id = so.id
            LEFT JOIN inventory_batches ib ON c.reference_type IN ('PURCHASE_CHINA', 'TRANSPORT_RECEPTION') AND c.reference_id = ib.id
            ${where}
            ORDER BY c.transaction_date DESC
        `, params);
    }

    static async getProfitabilitySummary(productId = null) {
        let profitQuery = `SELECT SUM(total_profit) as gross_profit FROM stock_outputs`;
        let expenseQuery = `SELECT SUM(amount) as total_expenses FROM expenses`;
        const params = [];

        if (productId) {
            profitQuery += ` WHERE product_id = ?`;
            expenseQuery += ` WHERE product_id = ?`;
            params.push(productId);
        }

        const profit = await getQuery(profitQuery, productId ? [productId] : []);
        const expenses = await getQuery(expenseQuery, productId ? [productId] : []);
        
        const grossProfit = profit?.gross_profit || 0;
        const totalExpenses = expenses?.total_expenses || 0;
        const netProfit = grossProfit - totalExpenses;

        return {
            gross_profit: grossProfit,
            total_expenses: totalExpenses,
            net_profit: netProfit
        };
    }

    static async getExpensesByCategory(productId = null) {
        let where = '';
        const params = [];
        if (productId) {
            where = `WHERE product_id = ?`;
            params.push(productId);
        }

        return await allQuery(`
            SELECT category, SUM(amount) as total_amount 
            FROM expenses 
            ${where}
            GROUP BY category 
            ORDER BY total_amount DESC
        `, params);
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
