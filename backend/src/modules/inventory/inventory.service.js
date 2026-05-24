const inventoryRepo = require('./inventory.repository');
const auditService = require('../audit/audit.service');

const getProductStock = async (productId) => {
    return await inventoryRepo.getStock(productId);
};

// Fonction critique : Modifie le stock et laisse une trace
const adjustStock = async (productId, qtyChange, reason = 'Ajustement manuel') => {
    await inventoryRepo.updateStock(productId, qtyChange);
    await auditService.logAction('STOCK_ADJUSTMENT', 'inventory', productId, { change: qtyChange, reason });
};

module.exports = { getProductStock, adjustStock };
