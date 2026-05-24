const db = require('../../config/database');

// Le Repository est le SEUL fichier autorisé à écrire du SQL.
// Impossible de trouver "SELECT" ou "INSERT" dans les autres fichiers.

// --- Utilitaires de Promesses pour SQLite ---
const run = (sql, params = []) => {
    return new Promise((resolve, reject) => {
        db.run(sql, params, function (err) {
            if (err) reject(err);
            else resolve(this);
        });
    });
};

const get = (sql, params = []) => {
    return new Promise((resolve, reject) => {
        db.get(sql, params, (err, row) => {
            if (err) reject(err);
            else resolve(row);
        });
    });
};

const all = (sql, params = []) => {
    return new Promise((resolve, reject) => {
        db.all(sql, params, (err, rows) => {
            if (err) reject(err);
            else resolve(rows);
        });
    });
};

// --- Création automatique de la table ---
const initTable = async () => {
    const sql = `
        CREATE TABLE IF NOT EXISTS employees (
            id TEXT PRIMARY KEY,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            role TEXT NOT NULL,
            is_synced INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )
    `;
    await run(sql);
};
// On initialise la table au lancement de l'application
initTable().catch(err => console.error("Erreur init table employees", err));


// --- Fonctions SQL (Data Access Layer) ---
const insert = async (emp) => {
    const sql = `
        INSERT INTO employees (id, first_name, last_name, email, role, is_synced, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    await run(sql, [
        emp.id, emp.first_name, emp.last_name, emp.email, emp.role, emp.is_synced, emp.created_at, emp.updated_at
    ]);
};

const findByEmail = async (email) => {
    const sql = `SELECT * FROM employees WHERE email = ?`;
    return await get(sql, [email]);
};

const findAll = async () => {
    // Tri par les plus récents en premier
    const sql = `SELECT * FROM employees ORDER BY created_at DESC`;
    return await all(sql);
};

module.exports = {
    insert,
    findByEmail,
    findAll
};
