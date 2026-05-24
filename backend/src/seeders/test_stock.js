const db = require('../config/database');

const runSeeder = () => {
    console.log("⏳ Démarrage du Seeder (Produits Réels & Lots)...");

    db.serialize(() => {
        db.run('DELETE FROM expenses');
        db.run('DELETE FROM cash_transactions');
        db.run('DELETE FROM stock_outputs');
        db.run('DELETE FROM inventory_batches');
        db.run('DELETE FROM products');
        db.run('DELETE FROM audit_logs');

        // Initialiser la caisse avec un petit fond de départ pour les tests
        db.run(`INSERT INTO cash_transactions (type, amount, reference_type, reference_id, balance_after) 
                VALUES ('IN', 500000, 'MANUAL', 0, 500000)`);

        // Produit 1 : Genouillère
        db.run(`INSERT INTO products (id, name, category, color, selling_price) 
                VALUES (1, 'Genouillère', 'Protection', 'Noir', 80000)`);

        // Produit 2 : Casque Enfant
        db.run(`INSERT INTO products (id, name, category, color, selling_price) 
                VALUES (2, 'Casque Enfant', 'Electronique', 'Bleu', 120000)`);

        // Lots pour Genouillère
        db.run(`INSERT INTO inventory_batches (id, product_id, supplier_name, quantity_received, quantity_remaining, purchase_cost, transport_cost, unit_cost_real, batch_date) 
                VALUES (1, 1, 'Fournisseur Chine A', 50, 50, 20000, 5000, 25000, '2026-05-01 10:00:00')`);

        // Lots pour Casque Enfant
        db.run(`INSERT INTO inventory_batches (id, product_id, supplier_name, quantity_received, quantity_remaining, purchase_cost, transport_cost, unit_cost_real, batch_date) 
                VALUES (2, 2, 'Fournisseur Chine B', 30, 30, 40000, 10000, 50000, '2026-05-10 10:00:00')`);

        console.log("✅ Données métiers réelles insérées avec succès dans la base de données.");
    });
};

runSeeder();
