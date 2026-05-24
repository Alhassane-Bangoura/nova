import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/erp_stat_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ProductRepository _repo = ProductRepository();
  List<ProductModel> _products = [];
  List<ProductModel> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final products = await _repo.getAllProducts();
      setState(() {
        _products = products;
        _filtered = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _products.where((p) =>
          p.name.toLowerCase().contains(query) ||
          (p.category?.toLowerCase().contains(query) ?? false)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistiques rapides
        if (!_isLoading && _errorMessage == null) _buildStats(),
        const SizedBox(height: 20),

        // En-tête du tableau (Recherche + Bouton Ajouter)
        _buildTableHeader(),
        const SizedBox(height: 16),

        // Tableau ou États
        Expanded(child: _buildBody()),
      ],
    );
  }

  String _getBaseProductName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('genouill')) return 'Genouillères';
    if (lowerName.contains('casque')) return 'Casques';
    if (lowerName.contains('chaussure')) return 'Chaussures';
    return name.split(' ').first.toUpperCase();
  }

  Widget _buildStats() {
    final totalProducts = _products.length;
    final totalStock = _products.fold<int>(0, (sum, p) => sum + p.stockQuantity);

    // Grouping by base product name
    final Map<String, int> stockByBaseName = {};
    for (var p in _products) {
      final baseName = _getBaseProductName(p.name);
      stockByBaseName[baseName] = (stockByBaseName[baseName] ?? 0) + p.stockQuantity;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ErpStatCard(
                title: 'Produits au Catalogue',
                value: '$totalProducts',
                icon: Icons.inventory_2_outlined,
                color: AppColors.navyBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ErpStatCard(
                title: 'Volume Global en Stock',
                value: '$totalStock Unités',
                icon: Icons.warehouse_outlined,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        if (stockByBaseName.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Résumé par type d\'article',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: stockByBaseName.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.checkroom, size: 16, color: AppColors.gold),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade600)),
                          Text('${entry.value} restants', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyBlue)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        // Barre de recherche
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Bouton Rafraîchir
        IconButton(
          onPressed: _loadProducts,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualiser',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 8),
        // Bouton Ajouter
        ElevatedButton.icon(
          onPressed: () => _showAddProductDialog(context),
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
          label: Text('Nouveau Produit',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navyBlue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    if (_filtered.isEmpty) {
      return _buildEmptyState();
    }
    return _buildProductTable();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Connexion impossible', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red.shade400)),
          const SizedBox(height: 8),
          Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyBlue, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 72, color: AppColors.gold.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Aucun produit trouvé', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text('Ajoutez votre premier produit (Genouillère, Casque...)',
              style: TextStyle(color: Colors.grey.shade400)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddProductDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un produit'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.navyBlue, foregroundBuilder: null),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // En-têtes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.navyBlue.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                _tableHeader('Produit', flex: 3),
                _tableHeader('Catégorie', flex: 2),
                _tableHeader('Prix Vente (Base)', flex: 2),
                _tableHeader('En Stock', flex: 2),
                _tableHeader('Sortis', flex: 2),
                _tableHeader('Actions', flex: 2),
              ],
            ),
          ),
          // Lignes de données
          Expanded(
            child: ListView.separated(
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemCount: _filtered.length,
              itemBuilder: (context, index) => _buildProductRow(_filtered[index]),
            ),
          ),
          // Footer (Nombre de résultats)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} produit(s) affiché(s)',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildProductRow(ProductModel product) {
    return InkWell(
      onTap: () => _showProductDetails(context, product),
      hoverColor: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  if (product.color != null && product.color!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Couleur: ${product.color}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                  if (product.stockQuantity <= 0 && product.stockEmptyAt != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Rupture ! Archivage auto dans ${3 - DateTime.now().difference(product.stockEmptyAt!).inDays} jour(s)',
                            style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                product.category ?? '-',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${product.salePrice.toStringAsFixed(0)} GNF',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.stockQuantity > 0 ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${product.stockQuantity} Unité(s)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: product.stockQuantity > 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.quantitySold > 0 ? Colors.blue.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${product.quantitySold} Unité(s)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: product.quantitySold > 0 ? Colors.blue.shade700 : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                    tooltip: 'Modifier',
                    onPressed: () => _showEditProductDialog(context, product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    tooltip: 'Supprimer',
                    onPressed: () => _showDeleteProductDialog(context, product),
                  ),
                  IconButton(
                    icon: Icon(Icons.print_outlined, color: Colors.grey.shade600, size: 20),
                    tooltip: 'Imprimer étiquette',
                    onPressed: () => _printProduct(product),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, ProductModel product) {
    final double totalExpenses = product.stockQuantity * product.unitCostReal;
    final double totalRevenue = product.stockQuantity * product.salePrice;
    final double totalProfit = totalRevenue - totalExpenses;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(ctx).size.width > 550 ? 500 : MediaQuery.of(ctx).size.width * 0.95,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.navyBlue, Color(0xFF1E293B)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.gold, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text('Détails: ${product.name}',
                          style: GoogleFonts.outfit(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.navyBlue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navyBlue.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Dépenses Totales', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.grey.shade300, fontSize: 13)),
                              Text(
                                '${totalExpenses.toStringAsFixed(0)} GNF',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Revenu Total', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.grey.shade300, fontSize: 13)),
                              Text(
                                '${totalRevenue.toStringAsFixed(0)} GNF',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Colors.white24, height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Bénéfice Total', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                              Text(
                                '${totalProfit.toStringAsFixed(0)} GNF',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: totalProfit >= 0 ? AppColors.gold : Colors.redAccent),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _printProductDetailsPdf(product, totalExpenses, totalRevenue, totalProfit);
                        },
                        icon: const Icon(Icons.picture_as_pdf, color: AppColors.navyBlue),
                        label: const Text('Imprimer PDF (WhatsApp)', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.navyBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ProductFormDialog(
        onSaved: () {
          Navigator.of(ctx).pop();
          _loadProducts();
        },
        repo: _repo,
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => _ProductFormDialog(
        onSaved: () {
          Navigator.of(ctx).pop();
          _loadProducts();
        },
        repo: _repo,
        product: product,
      ),
    );
  }

  void _showDeleteProductDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFDC2626), Color(0xFF991B1B)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text('Confirmer la suppression',
                          style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Voulez-vous vraiment supprimer le produit "${product.name}" ? Cette action est irréversible.', style: TextStyle(fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('Annuler', style: TextStyle(color: Colors.grey.shade700)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        try {
                          await _repo.deleteProduct(product.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Produit supprimé avec succès'), backgroundColor: Colors.green),
                            );
                          }
                          _loadProducts();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printProduct(ProductModel product) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('NOVA GENIX DIGITAL - ERP', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.SizedBox(height: 20),
                  pw.Text('Fiche Produit', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.Text('Nom: ${product.name}', style: const pw.TextStyle(fontSize: 18)),
                  pw.Text('Catégorie: ${product.category ?? "-"}', style: const pw.TextStyle(fontSize: 18)),
                  pw.Text('Prix Vente: ${product.salePrice.toStringAsFixed(0)} GNF', style: const pw.TextStyle(fontSize: 18)),
                  pw.Text('Stock Actuel: ${product.stockQuantity}', style: const pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 40),
                  pw.BarcodeWidget(
                    data: product.id,
                    barcode: pw.Barcode.code128(),
                    width: 200,
                    height: 80,
                  ),
                ],
              ),
            );
          },
        ),
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Produit_${product.name.replaceAll(' ', '_')}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'impression: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printProductDetailsPdf(ProductModel product, double expenses, double revenue, double profit) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('NOVA GENIX DIGITAL - ERP', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xff1B2B48))),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: const PdfColor.fromInt(0xffD0D5DD)),
                  pw.SizedBox(height: 30),
                  pw.Text('Rapport de Commande / Bilan', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 30),
                  
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xffF8F9FA),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xffE9ECEF))
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Produit: ${product.name}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 10),
                        pw.Text('Stock Actuel: ${product.stockQuantity} Unités', style: const pw.TextStyle(fontSize: 14)),
                        pw.SizedBox(height: 20),
                        
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Dépenses Totales:', style: const pw.TextStyle(fontSize: 14)),
                            pw.Text('${expenses.toStringAsFixed(0)} GNF', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xffDC3545))),
                          ]
                        ),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Revenu Total Estimé:', style: const pw.TextStyle(fontSize: 14)),
                            pw.Text('${revenue.toStringAsFixed(0)} GNF', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xff28A745))),
                          ]
                        ),
                        pw.SizedBox(height: 15),
                        pw.Divider(color: const PdfColor.fromInt(0xffD0D5DD)),
                        pw.SizedBox(height: 15),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Bénéfice Total:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                            pw.Text('${profit.toStringAsFixed(0)} GNF', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: profit >= 0 ? const PdfColor.fromInt(0xff28A745) : const PdfColor.fromInt(0xffDC3545))),
                          ]
                        ),
                      ]
                    )
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text('Généré par Nova Genix Digital ERP', style: const pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xff6C757D))),
                ],
              ),
            );
          },
        ),
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Bilan_${product.name.replaceAll(' ', '_')}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'impression: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ============================================================
// DIALOG D'AJOUT DE PRODUIT
// ============================================================
class _ProductFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  final ProductRepository repo;
  final ProductModel? product;

  const _ProductFormDialog({required this.onSaved, required this.repo, this.product});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _purchaseCostCtrl = TextEditingController(); // UNIT purchase price
  final _supplierFeeCtrl = TextEditingController(); // Frais Fournisseur
  final _transitFeeCtrl = TextEditingController(); // Frais Transitaire
  bool _isSaving = false;
  String? _error;
  List<dynamic> _purchases = [];
  bool _isLoadingPurchases = false;
  String? _selectedPurchaseId;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameCtrl.text = widget.product!.name;
      _categoryCtrl.text = widget.product!.category ?? '';
      _salePriceCtrl.text = widget.product!.salePrice.toStringAsFixed(0);
      _qtyCtrl.text = widget.product!.stockQuantity > 0 ? widget.product!.stockQuantity.toString() : '';
    } else {
      _fetchPurchases();
    }
    _qtyCtrl.addListener(() => setState(() {}));
    _purchaseCostCtrl.addListener(() => setState(() {}));
    _salePriceCtrl.addListener(() => setState(() {}));
    _supplierFeeCtrl.addListener(() => setState(() {}));
    _transitFeeCtrl.addListener(() => setState(() {}));
  }

  Future<void> _fetchPurchases() async {
    setState(() => _isLoadingPurchases = true);
    try {
      final res = await http.get(Uri.parse('http://localhost:3000/api/china-purchases'));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _purchases = json.decode(res.body)['data'];
            _isLoadingPurchases = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPurchases = false);
    }
  }

  void _disposeControllers() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _salePriceCtrl.dispose();
    _qtyCtrl.dispose();
    _purchaseCostCtrl.dispose();
    _supplierFeeCtrl.dispose();
    _transitFeeCtrl.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSaving = true; _error = null; });
    try {
      final double? qty = double.tryParse(_qtyCtrl.text.trim());
      final double? unitPCost = double.tryParse(_purchaseCostCtrl.text.trim());
      final double sFee = double.tryParse(_supplierFeeCtrl.text.trim()) ?? 0;
      final double tFee = double.tryParse(_transitFeeCtrl.text.trim()) ?? 0;
      final double totalTransportAndFees = sFee + tFee;

      final double? totalPurchase = (qty != null && unitPCost != null) ? (qty * unitPCost) : null;

      if (widget.product == null && _selectedPurchaseId != null) {
        // If an order was selected, the product already exists in DB! We just update it.
        final selected = _purchases.firstWhere((p) => p['id'].toString() == _selectedPurchaseId);
        await widget.repo.updateProduct(
          selected['product_id'].toString(),
          name: _nameCtrl.text.trim(),
          category: _categoryCtrl.text.trim(),
          salePrice: double.parse(_salePriceCtrl.text.trim()),
          batch_id: _selectedPurchaseId,
          transport_cost: totalTransportAndFees > 0 ? totalTransportAndFees : null,
        );
        // We can also call receive API if we want to update transport cost, but for now we update product.
      } else if (widget.product == null) {
        await widget.repo.createProduct(
          name: _nameCtrl.text.trim(),
          category: _categoryCtrl.text.trim(),
          salePrice: double.parse(_salePriceCtrl.text.trim()),
          quantity_received: qty,
          purchase_cost: totalPurchase,
          transport_cost: totalTransportAndFees > 0 ? totalTransportAndFees : null,
        );
      } else {
        // En édition, on met aussi à jour ces champs si modifiés (sera traité par le backend si supporté)
        await widget.repo.updateProduct(
          widget.product!.id,
          name: _nameCtrl.text.trim(),
          category: _categoryCtrl.text.trim(),
          salePrice: double.parse(_salePriceCtrl.text.trim()),
        );
      }
      widget.onSaved();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width > 650 ? 600 : MediaQuery.of(context).size.width * 0.95,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.navyBlue, Color(0xFF1E293B)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_box_outlined, color: AppColors.gold, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.product == null ? 'Nouveau Produit' : 'Modifier le Produit',
                      style: GoogleFonts.outfit(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                
                if (widget.product == null) ...[
                  Text('Sélectionner une commande (Optionnel)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  if (_isLoadingPurchases)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.flight_takeoff, size: 20, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.navyBlue, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      hint: const Text('Lier à une commande de Chine...'),
                      value: _selectedPurchaseId,
                      items: _purchases.map<DropdownMenuItem<String>>((p) {
                        return DropdownMenuItem<String>(
                          value: p['id'].toString(),
                          child: Text('${p['product_name']} - ${p['supplier_name']} (${p['quantity_received']} unités)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPurchaseId = val;
                          if (val != null) {
                            final selected = _purchases.firstWhere((p) => p['id'].toString() == val);
                            _nameCtrl.text = selected['product_name']?.toString() ?? '';
                            _qtyCtrl.text = selected['quantity_received']?.toString() ?? '';
                            _purchaseCostCtrl.text = selected['purchase_cost']?.toString() ?? '';
                            _transitFeeCtrl.text = selected['transport_cost']?.toString() ?? '';
                          }
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                ],

                _buildField('Nom du produit', 'ex: Casque Bébé, Genouillère Pro', _nameCtrl, Icons.label_outline),
                const SizedBox(height: 16),
                _buildField('Catégorie', 'ex: Protection, Sécurité', _categoryCtrl, Icons.category_outlined),
                _buildField('Prix de Vente Unitaire (GNF)', 'ex: 150000', _salePriceCtrl, Icons.attach_money, isNumber: true),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text('Arrivage Chine (Détails du Stock)', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Quantité Commandée', 'ex: 100', _qtyCtrl, Icons.inventory_2_outlined, isNumber: true, isOptional: widget.product != null)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Prix d\'Achat Unitaire (GNF)', 'ex: 50000', _purchaseCostCtrl, Icons.money_off, isNumber: true, isOptional: widget.product != null)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Frais Fournisseur (GNF)', 'ex: 500000', _supplierFeeCtrl, Icons.local_shipping_outlined, isNumber: true, isOptional: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Frais de Transport (GNF)', 'ex: 1000000', _transitFeeCtrl, Icons.flight_land, isNumber: true, isOptional: true)),
                ],
              ),
              const SizedBox(height: 24),
              
              // Dynamic Calculation display
              Builder(
                builder: (context) {
                  final double qty = double.tryParse(_qtyCtrl.text) ?? 0;
                  final double unitPurchase = double.tryParse(_purchaseCostCtrl.text) ?? 0;
                  final double unitSale = double.tryParse(_salePriceCtrl.text) ?? 0;
                  final double supplierFee = double.tryParse(_supplierFeeCtrl.text) ?? 0;
                  final double transitFee = double.tryParse(_transitFeeCtrl.text) ?? 0;
                  
                  final double totalPurchaseGoods = qty * unitPurchase;
                  final double totalExpenses = totalPurchaseGoods + supplierFee + transitFee;
                  final double totalRevenue = qty * unitSale;
                  final double totalProfit = totalRevenue - totalExpenses;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.navyBlue,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navyBlue.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Dépenses Totales (Produits + Frais)', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.grey.shade300, fontSize: 13)),
                            Text(
                              '${totalExpenses.toStringAsFixed(0)} GNF',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Revenu Total Estimé', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.grey.shade300, fontSize: 13)),
                            Text(
                              '${totalRevenue.toStringAsFixed(0)} GNF',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.white24, height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Bénéfice Total Estimé', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                            Text(
                              '${totalProfit.toStringAsFixed(0)} GNF',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: totalProfit >= 0 ? AppColors.gold : Colors.redAccent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler', style: TextStyle(color: Colors.grey.shade700)),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.navyBlue, strokeWidth: 2))
                  : const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ],
  ),
),
);
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, IconData icon, {bool isNumber = false, bool isOptional = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.navyBlue, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.red.shade300)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (v) {
            if (isOptional && (v == null || v.trim().isEmpty)) return null;
            if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
            if (isNumber && double.tryParse(v.trim()) == null) return 'Entrez un nombre valide';
            return null;
          },
        ),
      ],
    );
  }
}
