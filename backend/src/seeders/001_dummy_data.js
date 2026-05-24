// Seeder vide — aucune donnée statique.
// Ajoutez vos propres insertions ci-dessous si nécessaire.

const db = require('../config/database');

const runQuery = (sql, params = []) => new Promise((resolve, reject) => {
    db.run(sql, params, function(err) {
        if (err) reject(err);
        else resolve(this);
    });
});

const seedDatabase = async () => {
    console.log("🌱 Seeder démarré (aucune donnée statique).");
    // Ajoutez vos INSERT ici si besoin
    console.log("✅ Terminé.");
};

seedDatabase();
