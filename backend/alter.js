const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, 'database/enterprise.db');
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error(err.message);
        return;
    }
    db.run("ALTER TABLE stock_outputs ADD COLUMN client_name TEXT;", (err) => {
        if (err) {
            console.error(err.message);
        } else {
            console.log("Column added successfully.");
        }
    });
});
