const db = require('../config/database');

const insertProducts = () => {
    console.log("⏳ Insertion des vrais produits de base...");
    db.serialize(() => {
        const stmt = db.prepare(`INSERT INTO products (name, category, color, selling_price) VALUES (?, ?, ?, ?)`);
        
        // Genouillères avec toutes les couleurs
        stmt.run("Genouillère", "Protection", "Noir", 0);
        stmt.run("Genouillère", "Protection", "Bleu", 0);
        stmt.run("Genouillère", "Protection", "Rouge", 0);
        
        // Casque Enfant
        stmt.run("Casque Enfant", "Sécurité", "Unique", 0);

        stmt.finalize((err) => {
            if (err) {
                console.error("❌ Erreur :", err.message);
            } else {
                console.log("✅ Produits réels insérés. La base est propre !");
            }
        });
    });
};

insertProducts();
