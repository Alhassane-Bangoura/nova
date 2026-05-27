const { allQuery, getQuery } = require('../../utils/databaseHelper');

const getDashboardData = async (startDate, endDate, productId = null) => {
    let productFilter = '';
    let paramsWithProduct = [startDate, endDate];
    if (productId && productId !== 'all') {
        productFilter = ' AND product_id = ?';
        paramsWithProduct.push(productId);
    }
    
    let productFilterS = '';
    if (productId && productId !== 'all') {
        productFilterS = ' AND s.product_id = ?';
    }

    // 1. KPIs
    const salesData = await getQuery(`
        SELECT 
            COALESCE(SUM(total_revenue), 0) as total_revenue,
            COALESCE(SUM(total_profit), 0) as total_profit
        FROM stock_outputs
        WHERE date(output_date) BETWEEN ? AND ? ${productFilter}
    `, paramsWithProduct);

    const expensesData = await getQuery(`
        SELECT COALESCE(SUM(amount), 0) as total_expenses
        FROM expenses
        WHERE date(expense_date) BETWEEN ? AND ?
    `, [startDate, endDate]);

    // 2. Top Selling Products
    const topProducts = await allQuery(`
        SELECT p.name, SUM(s.quantity) as total_quantity, SUM(s.total_revenue) as revenue
        FROM stock_outputs s
        JOIN products p ON s.product_id = p.id
        WHERE date(s.output_date) BETWEEN ? AND ? ${productFilterS}
        GROUP BY s.product_id
        ORDER BY total_quantity DESC
        LIMIT 5
    `, paramsWithProduct);

    // 3. Expense Distribution (Pie Chart)
    const expenseDistribution = await allQuery(`
        SELECT category, SUM(amount) as total_amount
        FROM expenses
        WHERE date(expense_date) BETWEEN ? AND ?
        GROUP BY category
        ORDER BY total_amount DESC
    `, [startDate, endDate]);

    // 4. Daily Evolution (Line Chart)
    const dailyEvolution = await allQuery(`
        SELECT date(output_date) as date, 
               SUM(total_revenue) as revenue, 
               SUM(total_profit) as profit
        FROM stock_outputs
        WHERE date(output_date) BETWEEN ? AND ? ${productFilter}
        GROUP BY date(output_date)
        ORDER BY date ASC
    `, paramsWithProduct);

    // 5. Product Comparison (Genouillères vs Casques)
    const productComparison = await allQuery(`
        SELECT 
            CASE 
                WHEN LOWER(p.name) LIKE '%genouill%' THEN 'Genouillères'
                WHEN LOWER(p.name) LIKE '%casque%' THEN 'Casques'
                ELSE 'Autres'
            END as product_group,
            SUM(s.total_profit) as profit
        FROM stock_outputs s
        JOIN products p ON s.product_id = p.id
        WHERE date(s.output_date) BETWEEN ? AND ? ${productFilterS}
        GROUP BY product_group
    `, paramsWithProduct);

    // 6. Sanctions count
    const sanctionsData = await getQuery(`
        SELECT COUNT(*) as sanctions_count
        FROM sanctions
        WHERE date(sanction_date) BETWEEN ? AND ?
    `, [startDate, endDate]);

    return {
        kpis: {
            totalRevenue: salesData.total_revenue,
            totalProfit: salesData.total_profit,
            totalExpenses: expensesData.total_expenses
        },
        topProducts,
        expenseDistribution,
        dailyEvolution,
        productComparison,
        sanctionsCount: sanctionsData.sanctions_count
    };
};

module.exports = {
    getDashboardData
};
