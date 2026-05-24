const { runQuery, allQuery } = require('../../utils/databaseHelper');

class StockOutputRepository {
    
    /**
     * Démarrer une transaction
     */
    static async beginTransaction() {
        await runQuery('BEGIN IMMEDIATE TRANSACTION');
    }

    /**
     * Valider une transaction
     */
    static async commitTransaction() {
        await runQuery('COMMIT');
    }

    /**
     * Annuler une transaction
     */
    static async rollbackTransaction() {
        await runQuery('ROLLBACK');
    }

    /**
     * Récupère les lots disponibles en mode FIFO
     */
    static async getAvailableBatchesFIFO(productId) {
        return await allQuery(
            `SELECT id, quantity_remaining, unit_cost_real 
             FROM inventory_batches 
             WHERE product_id = ? AND quantity_remaining > 0 
             ORDER BY batch_date ASC`, 
            [productId]
        );
    }

    /**
     * Déduit la quantité d'un lot d'inventaire
     */
    static async deductBatchQuantity(batchId, quantityToDeduct) {
        await runQuery(
            `UPDATE inventory_batches SET quantity_remaining = quantity_remaining - ? WHERE id = ?`,
            [quantityToDeduct, batchId]
        );
    }

    /**
     * Enregistre une sortie de stock individuelle (par lot)
     */
    static async insertStockOutput(data) {
        const { productId, batchId, quantity, sellingPrice, totalRevenue, totalProfit, location, clientName } = data;
        const result = await runQuery(
            `INSERT INTO stock_outputs (product_id, batch_id, quantity, selling_price, total_revenue, total_profit, location, client_name) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
            [productId, batchId, quantity, sellingPrice, totalRevenue, totalProfit, location, clientName]
        );
        return result.lastID;
    }

    /**
     * Enregistre l'entrée d'argent dans la caisse
     */
    static async insertCashTransaction(amount, referenceId) {
        await runQuery(
            `INSERT INTO cash_transactions (type, amount, reference_type, reference_id, balance_after) 
             VALUES ('IN', ?, 'OUTPUT', ?, (IFNULL((SELECT balance_after FROM cash_transactions ORDER BY id DESC LIMIT 1), 0) + ?))`,
            [amount, referenceId, amount]
        );
    }

    /**
     * Enregistre une entrée d'audit log
     */
    static async insertAuditLog(actionType, entityName, entityId, description, employeeName = 'Moussa') {
        await runQuery(
            `INSERT INTO audit_logs (action_type, entity_name, entity_id, description, employee_name) 
             VALUES (?, ?, ?, ?, ?)`,
            [actionType, entityName, entityId, description, employeeName]
        );
    }

    /**
    * Récupère l'historique complet des sorties (pour le dashboard)
    */
    static async findAllOutputs() {
        return await allQuery(`
            SELECT s.id, p.name as product_name, s.quantity, s.selling_price, s.total_profit, s.location, s.client_name, s.output_date 
            FROM stock_outputs s
            JOIN products p ON s.product_id = p.id
            ORDER BY s.output_date DESC
            LIMIT 50
        `);
    }

    /**
    * Récupère une sortie de stock par ID
    */
    static async getOutputById(id) {
        return await allQuery(`SELECT * FROM stock_outputs WHERE id = ?`, [id]);
    }

    /**
    * Supprime une sortie de stock
    */
    static async deleteStockOutput(id) {
        await runQuery(`DELETE FROM stock_outputs WHERE id = ?`, [id]);
    }
}
module.exports = StockOutputRepository;
