const http = require('http');

const makeRequest = (data) => {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 3000,
            path: '/api/stock_outputs',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(JSON.stringify(data))
            }
        };

        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                try {
                    resolve({ status: res.statusCode, data: JSON.parse(body) });
                } catch(e) {
                    resolve({ status: res.statusCode, body });
                }
            });
        });

        req.on('error', reject);
        req.write(JSON.stringify(data));
        req.end();
    });
};

const runTests = async () => {
    console.log("=== DÉBUT DES TESTS TRANSACTIONNELS ===");
    
    // TEST 1: Sortie simple (1 quantité). Devrait puiser dans le Lot 1 (Coût: 150k, Vente: 250k -> Profit: 100k)
    console.log("\n[TEST 1] Sortie simple (Quantité: 1)");
    const res1 = await makeRequest({
        productId: 1,
        quantity: 1,
        sellingPrice: 250000,
        location: 'Dixinn'
    });
    console.log("Status:", res1.status);
    console.log("Réponse:", JSON.stringify(res1.data, null, 2));

    // TEST 2: Sortie chevauchant 2 lots (Quantité: 4)
    // Lot 1 a 1 unité restante (Profit: 100k)
    // Lot 2 a 10 unités. On en prend 3 (Coût: 160k, Vente: 250k -> Profit unitaire: 90k -> Profit: 270k)
    // Total profit attendu: 370k
    console.log("\n[TEST 2] Sortie traversant 2 lots (Quantité: 4)");
    const res2 = await makeRequest({
        productId: 1,
        quantity: 4,
        sellingPrice: 250000,
        location: 'Kaloum'
    });
    console.log("Status:", res2.status);
    console.log("Réponse:", JSON.stringify(res2.data, null, 2));

    // TEST 3: Tentative de stock négatif (Quantité: 50 alors qu'il reste 7 unités dans le Lot 2)
    console.log("\n[TEST 3] Tentative de création de stock négatif (Quantité: 50)");
    const res3 = await makeRequest({
        productId: 1,
        quantity: 50,
        sellingPrice: 250000,
        location: 'Matoto'
    });
    console.log("Status:", res3.status);
    console.log("Réponse:", JSON.stringify(res3.data, null, 2));

    // VÉRIFICATION D'INTÉGRITÉ
    console.log("\n[VÉRIFICATION DB] Vérification de l'intégrité SQLite post-tests...");
    const db = require('./src/config/database');
    db.serialize(() => {
        db.all("SELECT * FROM inventory_batches", (err, rows) => {
            console.log("\n--- INVENTORY BATCHES ---");
            console.table(rows);
        });
        db.all("SELECT * FROM cash_transactions", (err, rows) => {
            console.log("\n--- CASH TRANSACTIONS ---");
            console.table(rows);
        });
        db.all("SELECT * FROM stock_outputs", (err, rows) => {
            console.log("\n--- STOCK OUTPUTS ---");
            console.table(rows);
        });
        db.all("SELECT * FROM audit_logs", (err, rows) => {
            console.log("\n--- AUDIT LOGS ---");
            console.table(rows);
        });
    });
    setTimeout(() => process.exit(0), 1000); // Laisse le temps à SQLite de répondre
};

// On attend 2 sec pour laisser le serveur backend démarrer s'il est lancé en même temps
setTimeout(runTests, 2000);
