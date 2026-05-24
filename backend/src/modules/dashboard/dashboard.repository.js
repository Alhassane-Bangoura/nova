const { getQuery, allQuery } = require('../../utils/databaseHelper');

class DashboardRepository {
    // ==========================================
    // 1. KPIs GLOBAUX
    // ==========================================
    static async getCurrentCash() {
        const row = await getQuery(`SELECT balance_after FROM cash_transactions ORDER BY id DESC LIMIT 1`);
        return row ? row.balance_after : 0;
    }

    static async getDailyProfit() {
        const row = await getQuery(`SELECT SUM(total_profit) as profit FROM stock_outputs WHERE date(output_date) = date('now', 'localtime')`);
        return row?.profit || 0;
    }

    static async getDailyOutputs() {
        const row = await getQuery(`SELECT SUM(quantity) as qty FROM stock_outputs WHERE date(output_date) = date('now', 'localtime')`);
        return row?.qty || 0;
    }

    static async getDailyExpenses() {
        const row = await getQuery(`SELECT SUM(amount) as exp FROM expenses WHERE date(expense_date) = date('now', 'localtime')`);
        return row?.exp || 0;
    }

    static async getTotalStock() {
        const row = await getQuery(`SELECT SUM(quantity_remaining) as total_stock FROM inventory_batches`);
        return row?.total_stock || 0;
    }

    // ==========================================
    // 2. PERFORMANCE PRODUITS
    // ==========================================
    static async getTopProductsByVolume() {
        return await allQuery(`
            SELECT p.name, p.color, SUM(s.quantity) as total_qty 
            FROM stock_outputs s
            JOIN products p ON s.product_id = p.id
            GROUP BY p.id, p.name, p.color
            ORDER BY total_qty DESC LIMIT 5
        `);
    }

    static async getTopProductsByProfit() {
        return await allQuery(`
            SELECT p.name, p.color, SUM(s.total_profit) as total_profit 
            FROM stock_outputs s
            JOIN products p ON s.product_id = p.id
            GROUP BY p.id, p.name, p.color
            ORDER BY total_profit DESC LIMIT 5
        `);
    }

    // ==========================================
    // 3. ANALYTICS QUARTIERS
    // ==========================================
    static async getTopLocations() {
        return await allQuery(`
            SELECT location, SUM(quantity) as total_qty, SUM(total_profit) as total_profit
            FROM stock_outputs
            WHERE location IS NOT NULL AND location != ''
            GROUP BY location
            ORDER BY total_qty DESC LIMIT 5
        `);
    }

    // ==========================================
    // 4. ÉVOLUTION FINANCIÈRE (7 derniers jours)
    // ==========================================
    static async getFinancialEvolution() {
        return await allQuery(`
            SELECT date(output_date) as day, 
                   SUM(total_profit) as daily_profit, 
                   SUM(quantity) as daily_qty
            FROM stock_outputs
            WHERE output_date >= datetime('now', '-7 days')
            GROUP BY day
            ORDER BY day ASC
        `);
    }

    static async getExpenseEvolution() {
        return await allQuery(`
            SELECT date(expense_date) as day, 
                   SUM(amount) as daily_expense
            FROM expenses
            WHERE expense_date >= datetime('now', '-7 days')
            GROUP BY day
            ORDER BY day ASC
        `);
    }

    // ==========================================
    // 5. ALERTES BUSINESS
    // ==========================================
    static async getLowStockProducts() {
        return await allQuery(`
            SELECT p.id, p.name, p.color, p.min_stock, COALESCE(SUM(b.quantity_remaining), 0) as current_stock
            FROM products p
            LEFT JOIN inventory_batches b ON p.id = b.product_id
            GROUP BY p.id, p.name, p.color, p.min_stock
            HAVING current_stock < 30 OR current_stock <= p.min_stock
            ORDER BY current_stock ASC
        `);
    }

    // ==========================================
    // 6. TABLES DE DONNÉES (RÉTROCOMPATIBILITÉ UI)
    // ==========================================
    static async getRecentOutputs() {
        return await allQuery(`
            SELECT s.id, p.name as product_name, s.quantity, s.selling_price, s.total_profit, s.location, s.output_date 
            FROM stock_outputs s
            JOIN products p ON s.product_id = p.id
            WHERE date(s.output_date) = date('now', 'localtime')
            ORDER BY s.output_date DESC
        `);
    }

    static async getRecentExpenses() {
        return await allQuery(`
            SELECT id, category, amount, description, expense_date 
            FROM expenses 
            ORDER BY expense_date DESC 
            LIMIT 5
        `);
    }

    static async getRecentPurchases() {
        return await allQuery(`
            SELECT id, supplier_name, quantity_received, unit_cost_real, status, batch_date 
            FROM inventory_batches 
            ORDER BY batch_date DESC 
            LIMIT 5
        `);
    }
}

module.exports = DashboardRepository;
