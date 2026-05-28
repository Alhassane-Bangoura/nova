import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('enterprise.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialiser FFI pour Windows/Linux/Mac
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final appDocDir = await getApplicationSupportDirectory();
    final dbPath = join(appDocDir.path, filePath);

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
        onOpen: (db) async {
          // S'assurer que toutes les tables existent (utile pour les MAJ sans onUpgrade)
          await _createDB(db, 1);
          
          // Migrer la table expenses si nécessaire
          try {
            final columns = await db.rawQuery("PRAGMA table_info(expenses)");
            final hasProductId = columns.any((c) => c['name'] == 'product_id');
            if (!hasProductId) {
              await db.execute("ALTER TABLE expenses ADD COLUMN product_id INTEGER REFERENCES products(id) ON DELETE SET NULL");
            }
          } catch (e) {
            debugPrint("Erreur lors de la migration des colonnes: $e");
          }
        },
      ),
    );
  }

  Future _createDB(Database db, int version) async {
    debugPrint("⏳ Création de la base de données SQLite locale...");

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          color TEXT,
          min_stock INTEGER DEFAULT 30,
          selling_price REAL NOT NULL,
          image_url TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_batches (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          supplier_name TEXT NOT NULL,
          quantity_received INTEGER NOT NULL,
          quantity_remaining INTEGER NOT NULL,
          purchase_cost REAL NOT NULL,
          transport_cost REAL NOT NULL,
          unit_cost_real REAL NOT NULL,
          batch_date DATETIME DEFAULT CURRENT_TIMESTAMP,
          status TEXT DEFAULT 'En stock',
          order_date DATETIME,
          reception_date DATETIME,
          reception_transport_cost REAL DEFAULT 0,
          FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_outputs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          batch_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          selling_price REAL NOT NULL,
          total_revenue REAL NOT NULL,
          total_profit REAL NOT NULL,
          location TEXT NOT NULL,
          client_name TEXT,
          output_date DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT,
          FOREIGN KEY (batch_id) REFERENCES inventory_batches (id) ON DELETE RESTRICT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT,
          product_id INTEGER,
          expense_date DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL CHECK(type IN ('IN', 'OUT')),
          amount REAL NOT NULL,
          reference_type TEXT NOT NULL,
          reference_id INTEGER,
          description TEXT,
          balance_after REAL NOT NULL,
          transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS employees (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          role TEXT NOT NULL,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sanctions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          employee_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          reason TEXT NOT NULL,
          status TEXT DEFAULT 'En attente',
          sanction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (employee_id) REFERENCES employees (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action_type TEXT NOT NULL,
          entity_name TEXT NOT NULL,
          entity_id INTEGER,
          employee_name TEXT,
          description TEXT NOT NULL,
          old_value TEXT,
          new_value TEXT,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    debugPrint("✅ Base de données locale prête.");
  }

  Future<void> recordStockOutput({
    required int productId,
    required int quantityToDeduct,
    required double sellingPrice,
    required String location,
    required String clientName,
  }) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // 1. Fetch available batches
      final batches = await txn.query(
        'inventory_batches',
        where: 'product_id = ? AND quantity_remaining > 0 AND status = ?',
        whereArgs: [productId, 'Reçu'],
        orderBy: 'reception_date ASC, id ASC',
      );
      
      int remainingQty = quantityToDeduct;
      
      for (var batch in batches) {
        if (remainingQty <= 0) break;
        
        final batchId = batch['id'] as int;
        final batchQty = batch['quantity_remaining'] as int;
        final unitCost = (batch['unit_cost_real'] as num).toDouble();
        
        final qtyToTake = batchQty >= remainingQty ? remainingQty : batchQty;
        
        // Compute profit for this portion
        final revenue = qtyToTake * sellingPrice;
        final cost = qtyToTake * unitCost;
        final profit = revenue - cost;
        
        // Update batch
        await txn.update(
          'inventory_batches',
          {'quantity_remaining': batchQty - qtyToTake},
          where: 'id = ?',
          whereArgs: [batchId],
        );
        
        // Record output
        await txn.insert('stock_outputs', {
          'product_id': productId,
          'batch_id': batchId,
          'quantity': qtyToTake,
          'selling_price': sellingPrice,
          'total_revenue': revenue,
          'total_profit': profit,
          'location': location,
          'client_name': clientName,
        });
        
        remainingQty -= qtyToTake;
      }
      
      if (remainingQty > 0) {
        throw Exception('Stock insuffisant (Manque $remainingQty)');
      }
      
      // 2. Add cash transaction
      final cashRow = await txn.rawQuery('SELECT balance_after FROM cash_transactions ORDER BY id DESC LIMIT 1');
      final currentCash = cashRow.isNotEmpty ? (cashRow.first['balance_after'] as num).toDouble() : 0.0;
      
      final totalRevenue = quantityToDeduct * sellingPrice;
      
      await txn.insert('cash_transactions', {
        'type': 'IN',
        'amount': totalRevenue,
        'reference_type': 'VENTE',
        'description': 'Vente Produit #$productId',
        'balance_after': currentCash + totalRevenue,
      });
      
      // 3. Log
      await txn.insert('audit_logs', {
        'action_type': 'VENTE',
        'entity_name': 'stock_outputs',
        'description': 'Vente de $quantityToDeduct unités',
      });
    });
  }
}
