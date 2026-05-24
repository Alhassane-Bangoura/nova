import '../../../../core/services/api_service.dart';
import '../models/product_model.dart';

class ProductRepository {
  // Récupère tous les produits depuis l'API Node.js locale
  Future<List<ProductModel>> getAllProducts() async {
    final result = await ApiService.get('/products');

    if (result['success'] == true) {
      // Le backend répond : { status: 'success', results: N, data: [...] }
      final List<dynamic> rawList = result['data']['data'] ?? [];
      return rawList.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception(result['message']);
    }
  }

  // Crée un nouveau produit
  Future<ProductModel> createProduct({
    required String name,
    required String category,
    String? color,
    required double salePrice,
    double? quantity_received,
    double? purchase_cost,
    double? transport_cost,
  }) async {
    final result = await ApiService.post('/products', {
      'name': name,
      'category': category,
      if (color != null) 'color': color,
      'selling_price': salePrice,
      if (quantity_received != null) 'quantity_received': quantity_received,
      if (purchase_cost != null) 'purchase_cost': purchase_cost,
      if (transport_cost != null) 'transport_cost': transport_cost,
    });

    if (result['success'] == true) {
      return ProductModel.fromJson(result['data']['data'] ?? result['data']);
    } else {
      throw Exception(result['message']);
    }
  }

  // Modifie un produit existant
  Future<ProductModel> updateProduct(
    String id, {
    String? name,
    String? category,
    String? color,
    double? salePrice,
    String? batch_id,
    double? transport_cost,
  }) async {
    final Map<String, dynamic> body = {};
    if (name != null) body['name'] = name;
    if (category != null) body['category'] = category;
    if (color != null) body['color'] = color;
    if (salePrice != null) body['selling_price'] = salePrice;
    if (batch_id != null) body['batch_id'] = batch_id;
    if (transport_cost != null) body['transport_cost'] = transport_cost;

    final result = await ApiService.put('/products/$id', body);

    if (result['success'] == true) {
      return ProductModel.fromJson(result['data']['data'] ?? result['data']);
    } else {
      throw Exception(result['message']);
    }
  }

  // Supprime un produit
  Future<void> deleteProduct(String id) async {
    final result = await ApiService.delete('/products/$id');
    if (result['success'] != true) {
      throw Exception(result['message']);
    }
  }
}
