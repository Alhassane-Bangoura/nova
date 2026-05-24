class ProductModel {
  final String id;
  final String name;
  final String? category;
  final String? color;
  final double salePrice;
  final int stockQuantity;
  final int quantitySold;
  final double unitCostReal;
  final DateTime? stockEmptyAt;

  ProductModel({
    required this.id,
    required this.name,
    this.category,
    this.color,
    required this.salePrice,
    required this.stockQuantity,
    this.quantitySold = 0,
    this.unitCostReal = 0.0,
    this.stockEmptyAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      category: json['category'],
      color: json['color'],
      salePrice: num.tryParse(json['selling_price']?.toString() ?? '0')?.toDouble() ?? 0.0,
      stockQuantity: num.tryParse(json['stock_quantity']?.toString() ?? '0')?.toInt() ?? 0,
      quantitySold: num.tryParse(json['quantity_sold']?.toString() ?? '0')?.toInt() ?? 0,
      unitCostReal: num.tryParse(json['unit_cost_real']?.toString() ?? '0')?.toDouble() ?? 0.0,
      stockEmptyAt: json['stock_empty_at'] != null ? DateTime.tryParse(json['stock_empty_at']) : null,
    );
  }
}
