const ChinaPurchasesRepository = require('./china_purchases.repository');
const inventoryService = require('../inventory/inventory.service');
const { getQuery } = require('../../utils/databaseHelper');
const db = require('../../config/database');

const getAll = async (req, res, next) => {
    try {
        const purchases = await ChinaPurchasesRepository.getAll();
        res.status(200).json({ success: true, data: purchases });
    } catch (error) {
        next(error);
    }
};

const create = async (req, res, next) => {
    try {
        const result = await ChinaPurchasesRepository.create(req.body);
        // -- Audit log --
        const { product_id, quantity_ordered, unit_cost_cny } = req.body;
        db.run(`INSERT INTO audit_logs (action_type, entity_name, entity_id, description, employee_name) VALUES (?, ?, ?, ?, ?)`,
            ['STOCK', 'china_purchases', result.id || 0, `Nouvelle commande Chine: ${quantity_ordered} unités (produit ID ${product_id}) à ${unit_cost_cny} CNY/u`, 'Système']);
        res.status(201).json({ success: true, data: result });
    } catch (error) {
        next(error);
    }
};

const receive = async (req, res, next) => {
    try {
        const batchId = req.params.id;
        await ChinaPurchasesRepository.markAsReceived(batchId);
        const batch = await getQuery('SELECT product_id, quantity_received FROM inventory_batches WHERE id = ?', [batchId]);
        // -- Audit log --
        db.run(`INSERT INTO audit_logs (action_type, entity_name, entity_id, description, employee_name) VALUES (?, ?, ?, ?, ?)`,
            ['STOCK', 'china_purchases', batchId, `Réception commande Chine ID ${batchId}: ${batch ? batch.quantity_received : '?'} unités ajoutées au stock`, 'Système']);
        res.status(200).json({ success: true, message: 'Commande marquée comme reçue' });
    } catch (error) {
        next(error);
    }
};

const getReport = async (req, res, next) => {
    try {
        const batchId = req.params.id;
        const result = await ChinaPurchasesRepository.getReport(batchId);
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        next(error);
    }
};

module.exports = { getAll, create, receive, getReport };
