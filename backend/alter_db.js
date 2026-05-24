const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./database/enterprise.db');
db.serialize(() => {
    db.run("ALTER TABLE inventory_batches ADD COLUMN order_date DATETIME;", (err) => {
        if(err && !err.message.includes('duplicate')) console.log(err.message);
    });
    db.run("ALTER TABLE inventory_batches ADD COLUMN reception_date DATETIME;", (err) => {
        if(err && !err.message.includes('duplicate')) console.log(err.message);
    });
    console.log("Done");
});
db.close();
