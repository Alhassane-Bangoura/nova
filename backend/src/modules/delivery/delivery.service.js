const crypto = require('crypto');
const db = require('../../config/database');
const AppError = require('../../errors/AppError');
const deliveryRepo = require('./delivery.repository');
const salesRepo = require('../sales/sales.repository');
const accountingService = require('../accounting/accounting.service');
const auditService = require('../audit/audit.service');

// Étape 1 : Assigner un colis à un motard
const assignMotard = async (saleId, motardName, deliveryFee = 0, userId = 'Moussa') => {
    if (!saleId || !motardName) throw new AppError('Sale ID et Nom du Motard requis.', 400);

    const sale = await salesRepo.findById(saleId);
    if (!sale) throw new AppError('Vente introuvable.', 404);
    if (sale.status !== 'PENDING') throw new AppError('Cette vente est déjà livrée ou annulée.', 400);

    const newDelivery = {
        id: crypto.randomUUID(),
        sale_id: saleId,
        motard_name: motardName,
        status: 'ASSIGNED',
        delivery_fee: deliveryFee,
        created_at: new Date().toISOString()
    };

    await deliveryRepo.insert(newDelivery);
    await auditService.logAction('MOTARD_ASSIGNED', 'deliveries', newDelivery.id, newDelivery, null, userId);

    return newDelivery;
};

// Étape 2 : Le motard revient, la livraison est validée (L'ARGENT RENTRE EN CAISSE)
const completeDelivery = async (deliveryId, userId = 'Moussa') => {
    const delivery = await deliveryRepo.findById(deliveryId);
    if (!delivery) throw new AppError('Livraison introuvable.', 404);
    if (delivery.status === 'DELIVERED') throw new AppError('Cette livraison est déjà validée.', 400);

    const sale = await salesRepo.findById(delivery.sale_id);

    return new Promise((resolve, reject) => {
        db.serialize(async () => {
            db.run("BEGIN IMMEDIATE TRANSACTION;");
            try {
                // 1. Marquer la livraison comme terminée
                await deliveryRepo.updateStatus(deliveryId, 'DELIVERED');

                // 2. Marquer la vente comme terminée
                await salesRepo.updateStatus(sale.id, 'DELIVERED');

                // 3. ENTRÉE FINANCIÈRE : L'argent rentre dans la caisse de l'entreprise
                await accountingService.recordIncome(
                    sale.total_price, 
                    `Vente livrée par ${delivery.motard_name} (Paiement: ${sale.payment_method})`, 
                    sale.id
                );

                // 4. SORTIE FINANCIÈRE (Optionnel) : Payer le motard s'il y a des frais
                if (delivery.delivery_fee > 0) {
                    await accountingService.recordExpense(
                        delivery.delivery_fee, 
                        `Frais livraison payés au motard ${delivery.motard_name}`, 
                        delivery.id
                    );
                }

                // 5. Audit
                await auditService.logAction('DELIVERY_COMPLETED', 'deliveries', deliveryId, { status: 'DELIVERED' }, { status: delivery.status }, userId);

                db.run("COMMIT;", (err) => {
                    if (err) throw err;
                    resolve({ message: 'Livraison et paiements validés.' });
                });
            } catch (error) {
                db.run("ROLLBACK;", () => {
                    reject(new AppError(`Échec validation livraison : ${error.message}`, 500));
                });
            }
        });
    });
};

module.exports = { assignMotard, completeDelivery };
