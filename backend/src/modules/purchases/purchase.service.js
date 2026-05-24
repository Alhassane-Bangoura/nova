const crypto = require('crypto');
const db = require('../../config/database');
const AppError = require('../../errors/AppError');
const purchaseRepo = require('./purchase.repository');
const inventoryService = require('../inventory/inventory.service');
const accountingService = require('../accounting/accounting.service');
const auditService = require('../audit/audit.service');

const receiveStockFromChina = async (purchaseData, userId = 'Moussa') => {
    const { productId, quantity, totalCost, supplierName } = purchaseData;

    if (!productId || !quantity || quantity <= 0 || totalCost === undefined || totalCost < 0) {
        throw new AppError('Données invalides. Produit, quantité (>0) et coût total sont obligatoires.', 400);
    }

    const newPurchase = {
        id: crypto.randomUUID(),
        product_id: productId,
        quantity: quantity,
        total_cost: totalCost,
        supplier_name: supplierName || 'Fournisseur Chine Anonyme',
        is_synced: 0,
        created_at: new Date().toISOString()
    };

    // TRANSACTION SQLITE : On enregistre l'achat, on augmente le stock, et on sort l'argent
    return new Promise((resolve, reject) => {
        db.serialize(async () => {
            db.run("BEGIN IMMEDIATE TRANSACTION;");

            try {
                // 1. Enregistrer la commande d'achat
                await purchaseRepo.insert(newPurchase);

                // 2. Augmenter le stock physiquement (+quantity)
                await inventoryService.adjustStock(productId, quantity, `Réception Chine #${newPurchase.id}`);

                // 3. Sortir l'argent de la caisse (Dépense Comptable)
                await accountingService.recordExpense(totalCost, `Paiement fournisseur Chine (${newPurchase.supplier_name}) pour ${quantity} unités`, newPurchase.id);

                // 4. Traçabilité (Audit)
                await auditService.logAction('PURCHASE_RECEIVED', 'purchases', newPurchase.id, newPurchase, null, userId);

                // Validation définitive
                db.run("COMMIT;", (err) => {
                    if (err) throw err;
                    resolve(newPurchase);
                });
            } catch (error) {
                // Annulation totale en cas de problème
                db.run("ROLLBACK;", () => {
                    reject(new AppError(`Échec de la transaction de réception de stock : ${error.message}`, 500));
                });
            }
        });
    });
};

module.exports = { receiveStockFromChina };
