const productRepository = require('./product.repository');
const { runQuery, getQuery } = require('../../utils/databaseHelper');
const AppError = require('../../errors/AppError');

const createProduct = async (productData, userId = 'Moussa') => {
    // 1. Validation
    if (!productData.name) {
        throw new AppError('Le nom du produit est obligatoire.', 400);
    }
    if (!productData.selling_price || productData.selling_price <= 0) {
        throw new AppError('Le prix de vente doit être supérieur à 0.', 400);
    }

    // 2. Création via Repository
    const newProduct = await productRepository.create({
        name: productData.name,
        category: productData.category || 'Non classé',
        color: productData.color || null,
        min_stock: productData.min_stock || 30,
        selling_price: productData.selling_price,
    });

    // 3. Insertion du stock de Chine si fourni
    if (productData.quantity_received && productData.quantity_received > 0) {
        const pCost = productData.purchase_cost || 0;
        const tCost = productData.transport_cost || 0;
        const qty = productData.quantity_received;
        
        await productRepository.addChinaBatch({
            product_id: newProduct.id,
            supplier_name: 'Défaut Chine',
            quantity_received: qty,
            quantity_remaining: qty,
            purchase_cost: pCost,
            transport_cost: tCost,
            unit_cost_real: (pCost + tCost) / qty
        });
    }

    return newProduct;
};

const getActiveProducts = async () => {
    // Synchroniser le statut (stock 0 = alerte, puis archivage après 3 jours)
    await productRepository.syncStockStatus();
    
    // Retourne les produits avec leur stock calculé depuis inventory_batches
    return await productRepository.findAll();
};

const getProductById = async (id) => {
    const product = await productRepository.findById(id);
    if (!product) throw new AppError(`Produit ID ${id} introuvable.`, 404);
    return product;
};

const updateProduct = async (id, productData) => {
    // Vérifier l'existence
    const existing = await productRepository.findById(id);
    if (!existing) throw new AppError(`Produit ID ${id} introuvable.`, 404);

    if (productData.name === '') throw new AppError('Le nom du produit est obligatoire.', 400);

    const updated = await productRepository.update(id, {
        name: productData.name || existing.name,
        category: productData.category || existing.category,
        color: productData.color !== undefined ? productData.color : existing.color,
        min_stock: productData.min_stock || existing.min_stock,
        selling_price: productData.selling_price || existing.selling_price,
    });

    if (productData.batch_id && productData.transport_cost !== undefined) {
        const batch = await getQuery('SELECT purchase_cost, quantity_received FROM inventory_batches WHERE id = ?', [productData.batch_id]);
        if (batch) {
            const qty = batch.quantity_received > 0 ? batch.quantity_received : 1;
            const newUnitCost = batch.purchase_cost + (productData.transport_cost / qty);
            await runQuery(
                `UPDATE inventory_batches SET transport_cost = ?, unit_cost_real = ? WHERE id = ?`,
                [productData.transport_cost, newUnitCost, productData.batch_id]
            );
        }
    }

    return updated;
};

const deleteProduct = async (id) => {
    const existing = await productRepository.findById(id);
    if (!existing) throw new AppError(`Produit ID ${id} introuvable.`, 404);

    // Vérifier s'il y a du stock
    if (existing.stock_quantity > 0) {
        throw new AppError(`Impossible de supprimer un produit avec du stock existant (${existing.stock_quantity} unités).`, 400);
    }

    await productRepository.remove(id);
};

module.exports = { createProduct, getActiveProducts, getProductById, updateProduct, deleteProduct };
