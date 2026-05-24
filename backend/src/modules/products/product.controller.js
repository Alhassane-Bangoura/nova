const productService = require('./product.service');
const db = require('../../config/database');

const createProduct = async (req, res, next) => {
    try {
        const product = await productService.createProduct(req.body);
        // -- Audit log (ajout de stock) --
        const { name, quantity_received, transport_cost } = req.body;
        if (quantity_received && quantity_received > 0) {
            db.run(
                `INSERT INTO audit_logs (action_type, entity_name, entity_id, description, employee_name) VALUES (?, ?, ?, ?, ?)`,
                ['STOCK', 'products', product.id || 0,
                 `Ajout de stock: ${name} — ${quantity_received} unités reçues (Frais transport: ${transport_cost || 0} GNF)`,
                 'Système']
            );
        } else {
            db.run(
                `INSERT INTO audit_logs (action_type, entity_name, entity_id, description, employee_name) VALUES (?, ?, ?, ?, ?)`,
                ['STOCK', 'products', product.id || 0,
                 `Nouveau produit créé: ${name}`,
                 'Système']
            );
        }
        res.status(201).json({ success: true, data: product });
    } catch (error) {
        next(error);
    }
};

const getAllProducts = async (req, res, next) => {
    try {
        const products = await productService.getActiveProducts();
        res.status(200).json({ success: true, data: products });
    } catch (error) {
        next(error);
    }
};

const getProductById = async (req, res, next) => {
    try {
        const product = await productService.getProductById(req.params.id);
        res.status(200).json({ success: true, data: product });
    } catch (error) {
        next(error);
    }
};

const updateProduct = async (req, res, next) => {
    try {
        const product = await productService.updateProduct(req.params.id, req.body);
        // -- Audit log (modification produit) --
        db.run(
            `INSERT INTO audit_logs (action_type, entity_name, entity_id, description, employee_name) VALUES (?, ?, ?, ?, ?)`,
            ['STOCK', 'products', req.params.id,
             `Produit modifié ID ${req.params.id}: ${req.body.name || '?'}`,
             'Système']
        );
        res.status(200).json({ success: true, data: product });
    } catch (error) {
        next(error);
    }
};

const deleteProduct = async (req, res, next) => {
    try {
        await productService.deleteProduct(req.params.id);
        // -- Audit log --
        db.run(
            `INSERT INTO audit_logs (action_type, entity_name, entity_id, description, employee_name) VALUES (?, ?, ?, ?, ?)`,
            ['STOCK', 'products', req.params.id,
             `Produit supprimé (ID ${req.params.id})`,
             'Système']
        );
        res.status(200).json({ success: true, message: "Produit supprimé avec succès." });
    } catch (error) {
        next(error);
    }
};

module.exports = { createProduct, getAllProducts, getProductById, updateProduct, deleteProduct };
