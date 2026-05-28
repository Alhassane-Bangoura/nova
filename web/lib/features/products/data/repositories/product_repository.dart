import '../../../../core/database/database_helper.dart';
import '../models/product_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ProductRepository {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // Récupère tous les produits depuis la base SQLite locale
  Future<List<ProductModel>> getAllProducts() async {
    final db = await _db;
    
    // Aggregation logic mimicking the old backend
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
          p.id, 
          p.name, 
          p.category, 
          p.color, 
          p.selling_price, 
          COALESCE((SELECT SUM(quantity_remaining) FROM inventory_batches WHERE product_id = p.id), 0) AS stock_quantity,
          (SELECT SUM(quantity) FROM stock_outputs WHERE product_id = p.id) AS quantity_sold,
          (SELECT unit_cost_real FROM inventory_batches WHERE product_id = p.id ORDER BY id DESC LIMIT 1) AS unit_cost_real
      FROM products p
      ORDER BY p.name ASC
    ''');

    return results.map((json) => ProductModel.fromJson(json)).toList();
  }

  // Crée un nouveau produit
  Future<ProductModel> createProduct({
    required String name,
    required String category,
    String? color,
    required double salePrice,
    double? quantityReceived,
    double? purchaseCost,
    double? transportCost,
  }) async {
    final db = await _db;

    int productId = 0;
    
    await db.transaction((txn) async {
      // 1. Inserer le produit
      productId = await txn.rawInsert('''
        INSERT INTO products (name, category, color, selling_price)
        VALUES (?, ?, ?, ?)
      ''', [name, category, color, salePrice]);

      // 2. S'il y a un stock initial, inserer dans inventory_batches
      if (quantityReceived != null && quantityReceived > 0) {
        final double pCost = purchaseCost ?? 0.0;
        final double tCost = transportCost ?? 0.0;
        final double unitCost = (pCost + tCost) / quantityReceived;

        await txn.rawInsert('''
          INSERT INTO inventory_batches (
            product_id, supplier_name, quantity_received, quantity_remaining, 
            purchase_cost, transport_cost, unit_cost_real
          ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', [productId, 'Stock Initial', quantityReceived, quantityReceived, pCost, tCost, unitCost]);
      }
    });

    // Retourner le produit créé
    final results = await db.rawQuery('SELECT * FROM products WHERE id = ?', [productId]);
    final productJson = Map<String, dynamic>.from(results.first);
    productJson['stock_quantity'] = quantityReceived ?? 0;
    return ProductModel.fromJson(productJson);
  }

  // Modifie un produit existant
  Future<ProductModel> updateProduct(
    String id, {
    String? name,
    String? category,
    String? color,
    double? salePrice,
    String? batchId,
    double? transportCost,
  }) async {
    final db = await _db;
    
    List<String> updates = [];
    List<dynamic> args = [];
    
    if (name != null) { updates.add("name = ?"); args.add(name); }
    if (category != null) { updates.add("category = ?"); args.add(category); }
    if (color != null) { updates.add("color = ?"); args.add(color); }
    if (salePrice != null) { updates.add("selling_price = ?"); args.add(salePrice); }

    if (updates.isNotEmpty) {
      args.add(int.parse(id));
      await db.rawUpdate('''
        UPDATE products SET ${updates.join(', ')} WHERE id = ?
      ''', args);
    }
    
    // Pour simplifier on recharge la liste depuis getAllProducts pour récupérer l'objet complet
    final all = await getAllProducts();
    return all.firstWhere((p) => p.id == id);
  }

  // Supprime un produit
  Future<void> deleteProduct(String id) async {
    final db = await _db;
    await db.rawDelete('DELETE FROM products WHERE id = ?', [int.parse(id)]);
  }
}
