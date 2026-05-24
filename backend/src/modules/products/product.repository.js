const db = require('../../config/database');

// Helpers Promise
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

const getQuery = (sql, params = []) => new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
        if (err) reject(err);
        else resolve(row);
    });
});

// ─── PRODUCTS REPOSITORY (Aligné sur le schéma 001_init_schema.js) ────────────

const create = async (product) => {
    const result = await runQuery(
        `INSERT INTO products (name, category, color, min_stock, selling_price) 
         VALUES (?, ?, ?, ?, ?)`,
        [
            product.name,
            product.category || 'Non classé',
            product.color || null,
            product.min_stock || 30,
            product.selling_price || 0,
        ]
    );
    return { id: result.lastID, ...product };
};

const addChinaBatch = async (batch) => {
    const result = await runQuery(
        `INSERT INTO inventory_batches (product_id, supplier_name, quantity_received, quantity_remaining, purchase_cost, transport_cost, unit_cost_real) 
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
            batch.product_id,
            batch.supplier_name,
            batch.quantity_received,
            batch.quantity_remaining,
            batch.purchase_cost,
            batch.transport_cost,
            batch.unit_cost_real
        ]
    );
    return result.lastID;
};

const findAll = async () => {
    return await allQuery(
        `SELECT p.id, p.name, p.category, p.color, p.min_stock, p.selling_price, p.stock_empty_at,
                COALESCE(SUM(b.quantity_remaining), 0) as stock_quantity,
                COALESCE(SUM(b.quantity_received), 0) - COALESCE(SUM(b.quantity_remaining), 0) as quantity_sold,
                COALESCE(AVG(b.unit_cost_real), 0) as unit_cost_real
         FROM products p
         LEFT JOIN inventory_batches b ON p.id = b.product_id
         WHERE p.is_archived = 0
         GROUP BY p.id
         ORDER BY p.name ASC`
    );
};

const findById = async (id) => {
    return await getQuery(
        `SELECT p.id, p.name, p.category, p.color, p.min_stock, p.selling_price, p.stock_empty_at,
                COALESCE(SUM(b.quantity_remaining), 0) as stock_quantity,
                COALESCE(SUM(b.quantity_received), 0) - COALESCE(SUM(b.quantity_remaining), 0) as quantity_sold,
                COALESCE(AVG(b.unit_cost_real), 0) as unit_cost_real
         FROM products p
         LEFT JOIN inventory_batches b ON p.id = b.product_id
         WHERE p.id = ?
         GROUP BY p.id`,
        [id]
    );
};

const update = async (id, product) => {
    await runQuery(
        `UPDATE products 
         SET name = ?, category = ?, color = ?, min_stock = ?, selling_price = ?
         WHERE id = ?`,
        [
            product.name,
            product.category,
            product.color,
            product.min_stock,
            product.selling_price,
            id
        ]
    );
    return { id, ...product };
};

const remove = async (id) => {
    await runQuery(`DELETE FROM products WHERE id = ?`, [id]);
};

const syncStockStatus = async () => {
    // 1. Mark products as empty if they have 0 stock
    await runQuery(`
        UPDATE products 
        SET stock_empty_at = CURRENT_TIMESTAMP
        WHERE stock_empty_at IS NULL AND is_archived = 0
        AND id IN (
            SELECT p.id 
            FROM products p
            LEFT JOIN inventory_batches b ON p.id = b.product_id
            GROUP BY p.id
            HAVING COALESCE(SUM(b.quantity_remaining), 0) <= 0
        )
    `);

    // 2. Remove empty mark if stock > 0
    await runQuery(`
        UPDATE products 
        SET stock_empty_at = NULL, is_archived = 0
        WHERE stock_empty_at IS NOT NULL
        AND id IN (
            SELECT p.id 
            FROM products p
            LEFT JOIN inventory_batches b ON p.id = b.product_id
            GROUP BY p.id
            HAVING COALESCE(SUM(b.quantity_remaining), 0) > 0
        )
    `);

    // 3. Archive products that have been empty for 3 days
    await runQuery(`
        UPDATE products 
        SET is_archived = 1
        WHERE is_archived = 0 
        AND stock_empty_at IS NOT NULL 
        AND stock_empty_at <= datetime('now', '-3 days')
    `);
};

module.exports = { create, findAll, findById, addChinaBatch, update, remove, syncStockStatus };
