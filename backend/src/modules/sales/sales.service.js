const crypto = require('crypto');
const db = require('../../config/database');
const AppError = require('../../errors/AppError');
const salesRepo = require('./sales.repository');

const inventoryService = require('../inventory/inventory.service');
const auditService = require('../audit/audit.service');

// Contexte Conakry : Une commande WhatsApp crée une Vente "PENDING". 
// L'argent n'entre pas en caisse tant que le motard n'a pas livré.
const createSale = async (saleData, userId = 'Moussa') => {
    const { productId, quantity, clientName, clientPhone, neighborhood, paymentMethod } = saleData;

    if (!productId || quantity <= 0 || !clientName || !clientPhone || !neighborhood || !paymentMethod) {
        throw new AppError('Toutes les informations client (Nom, Téléphone, Quartier, Paiement) sont obligatoires.', 400);
    }

    if (paymentMethod !== 'ORANGE_MONEY' && paymentMethod !== 'ESPECES') {
        throw new AppError('Le mode de paiement doit être ORANGE_MONEY ou ESPECES.', 400);
    }

    // 1. Récupérer le vrai prix du produit
    const getProduct = () => new Promise((resolve, reject) => {
        db.get(`SELECT * FROM products WHERE id = ?`, [productId], (err, row) => {
            if (err) reject(err); else resolve(row);
        });
    });
    
    const product = await getProduct();
    if (!product) throw new AppError('Produit introuvable.', 404);

    // 2. Vérifier le stock en direct
    const currentStock = await inventoryService.getProductStock(productId);
    if (currentStock < quantity) {
        throw new AppError(`Stock insuffisant à Conakry. Il ne reste que ${currentStock} unités.`, 400);
    }

    const totalPrice = product.sale_price * quantity;

    const newSale = {
        id: crypto.randomUUID(),
        product_id: productId,
        quantity: quantity,
        unit_price: product.sale_price,
        total_price: totalPrice,
        client_name: clientName,
        client_phone: clientPhone,
        neighborhood: neighborhood,
        payment_method: paymentMethod,
        status: 'PENDING', // En attente de livraison
        is_synced: 0,
        created_at: new Date().toISOString()
    };

    // TRANSACTION : On enregistre la commande et on RÉSERVE le stock.
    // L'argent n'est PAS encore ajouté en comptabilité (on attend le retour du motard).
    return new Promise((resolve, reject) => {
        db.serialize(async () => {
            db.run("BEGIN IMMEDIATE TRANSACTION;");
            try {
                await salesRepo.insert(newSale);
                // On déduit physiquement le stock pour qu'un autre client WhatsApp ne puisse pas le prendre
                await inventoryService.adjustStock(productId, -quantity, `Réservation Commande #${newSale.id}`);
                await auditService.logAction('SALE_PENDING', 'sales', newSale.id, newSale, null, userId);

                db.run("COMMIT;", (err) => {
                    if (err) throw err;
                    resolve(newSale);
                });
            } catch (error) {
                db.run("ROLLBACK;", () => {
                    reject(new AppError(`Échec transaction vente : ${error.message}`, 500));
                });
            }
        });
    });
};

module.exports = { createSale };
