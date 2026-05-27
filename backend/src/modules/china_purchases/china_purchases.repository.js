const { getQuery, allQuery, runQuery } = require('../../utils/databaseHelper');

const AppError = require('../../errors/AppError');

class ChinaPurchasesRepository {
    static async getAll() {
        return await allQuery(`
            SELECT b.*, p.name as product_name, p.selling_price
            FROM inventory_batches b
            JOIN products p ON b.product_id = p.id
            ORDER BY b.order_date DESC, b.batch_date DESC
        `);
    }

    static async create(data) {
        await runQuery('BEGIN IMMEDIATE TRANSACTION');
        try {
            // Find or create product by name
            let product = await getQuery('SELECT id FROM products WHERE name = ? COLLATE NOCASE', [data.productName]);
            let productId;
            if (!product) {
                const insertResult = await runQuery('INSERT INTO products (name, category, color, selling_price) VALUES (?, ?, ?, ?)', [data.productName, 'Général', '-', 0]);
                productId = insertResult.lastID;
            } else {
                productId = product.id;
            }

            const unitCost = parseFloat(data.unitCost) || 0;
            const quantity = parseInt(data.quantity) || 0;
            const transportCost = parseFloat(data.transportCost) || 0;
            const totalCost = (unitCost * quantity) + transportCost;
            const unitCostReal = quantity > 0 ? unitCost + (transportCost / quantity) : unitCost;
            const orderDate = data.orderDate || new Date().toISOString();

            // Validate cash balance
            const row = await getQuery(`SELECT balance_after FROM cash_transactions ORDER BY id DESC LIMIT 1`);
            const currentBalance = row ? row.balance_after : 0;
            
            if (currentBalance < totalCost) {
                throw new AppError(`Fonds insuffisants en caisse. Solde actuel: ${currentBalance} GNF, Coût total de la commande: ${totalCost} GNF.`, 400);
            }
            
            const insertBatchResult = await runQuery(`
                INSERT INTO inventory_batches 
                (product_id, supplier_name, quantity_received, quantity_remaining, purchase_cost, transport_cost, unit_cost_real, status, order_date)
                VALUES (?, ?, ?, ?, ?, ?, ?, 'En attente', ?)
            `, [
                productId,
                data.supplier,
                quantity,
                0, // remaining is 0 until received
                unitCost, 
                transportCost,
                unitCostReal,
                orderDate
            ]);
            
            const batchId = insertBatchResult.lastID;

            // Deduct cash
            const newBalance = currentBalance - totalCost;
            await runQuery(
                `INSERT INTO cash_transactions (type, amount, reference_type, reference_id, balance_after) VALUES (?, ?, ?, ?, ?)`,
                ['OUT', totalCost, 'PURCHASE_CHINA', batchId, newBalance]
            );

            await runQuery('COMMIT');
            return { id: batchId, totalCost };
        } catch (error) {
            await runQuery('ROLLBACK');
            throw error;
        }
    }

    static async markAsReceived(batchId, receptionTransportCost = 0) {
        const batch = await getQuery('SELECT purchase_cost, quantity_received, transport_cost FROM inventory_batches WHERE id = ?', [batchId]);
        if (!batch) return;

        const receptionDate = new Date().toISOString();
        const recTransport = parseFloat(receptionTransportCost) || 0;

        // Recompute unit_cost_real: (unit_cost * qty + transit_cost + reception_transport) / qty
        const newUnitCostReal = batch.quantity_received > 0
            ? batch.purchase_cost + ((batch.transport_cost + recTransport) / batch.quantity_received)
            : batch.purchase_cost;

        // Deduct reception transport from cash if any
        if (recTransport > 0) {
            const row = await getQuery(`SELECT balance_after FROM cash_transactions ORDER BY id DESC LIMIT 1`);
            const currentBalance = row ? row.balance_after : 0;
            if (currentBalance < recTransport) {
                throw new AppError(`Fonds insuffisants pour les frais de transport. Solde: ${currentBalance} GNF, Frais: ${recTransport} GNF.`, 400);
            }
            const newBalance = currentBalance - recTransport;
            await runQuery(
                `INSERT INTO cash_transactions (type, amount, reference_type, reference_id, balance_after) VALUES (?, ?, ?, ?, ?)`,
                ['OUT', recTransport, 'TRANSPORT_RECEPTION', batchId, newBalance]
            );
        }

        // When received, the remaining quantity becomes the received quantity
        return await runQuery(`
            UPDATE inventory_batches
            SET status = 'Reçu',
                reception_date = ?,
                quantity_remaining = quantity_received,
                reception_transport_cost = ?,
                unit_cost_real = ?
            WHERE id = ?
        `, [receptionDate, recTransport, newUnitCostReal, batchId]);
    }
    static async getReport(batchId) {
        const batch = await getQuery(`
            SELECT b.*, p.name as product_name
            FROM inventory_batches b
            JOIN products p ON b.product_id = p.id
            WHERE b.id = ?
        `, [batchId]);

        if (!batch) {
            throw new AppError('Commande introuvable', 404);
        }

        const totalSpent = (batch.purchase_cost * batch.quantity_received) + batch.transport_cost;

        const sales = await getQuery(`
            SELECT SUM(total_revenue) as total_earned, SUM(quantity) as quantity_sold
            FROM stock_outputs
            WHERE batch_id = ?
        `, [batchId]);

        const totalEarned = sales?.total_earned || 0;
        const quantitySold = sales?.quantity_sold || 0;
        const profitOrLoss = totalEarned - totalSpent;
        const isDepleted = batch.quantity_remaining === 0;

        return {
            batch,
            report: {
                totalSpent,
                totalEarned,
                profitOrLoss,
                quantitySold,
                isDepleted
            }
        };
    }
}

module.exports = ChinaPurchasesRepository;
