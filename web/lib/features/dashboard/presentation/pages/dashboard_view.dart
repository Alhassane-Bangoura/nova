import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/erp_stat_card.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/repositories/product_repository.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isLoading = true;
  String _errorMessage = '';

  // Data
  Map<String, dynamic> _kpis = {};
  List<dynamic> _recentOutputs = [];

  List<dynamic> _lowStockAlerts = [];
  List<dynamic> _topProducts = [];
  List<dynamic> _topLocations = [];
  // ignore: unused_field
  List<dynamic> _financialEvolution = [];
  // Cache: don't reload if data is less than 60 seconds old
  DateTime? _lastLoadTime;

  final ProductRepository _productRepo = ProductRepository();
  List<ProductModel> _products = [];
  ProductModel? _selectedProduct;
  double _globalTotalProfit = 0;
  double _globalTotalExpenses = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData({bool force = false}) async {
    // Si les données ont été chargées il y a moins de 60 secondes, on ne recharge pas
    if (!force && _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!).inSeconds < 60 &&
        _kpis.isNotEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final db = await DatabaseHelper.instance.database;

      final cashRow = await db.rawQuery('SELECT balance_after FROM cash_transactions ORDER BY id DESC LIMIT 1');
      final currentCash = cashRow.isNotEmpty ? cashRow.first['balance_after'] : 0;

      final dailyOutputsRow = await db.rawQuery("SELECT SUM(quantity) as qty FROM stock_outputs WHERE date(output_date) = date('now', 'localtime')");
      final dailyOutputs = dailyOutputsRow.isNotEmpty ? dailyOutputsRow.first['qty'] ?? 0 : 0;

      final lowStockCountRow = await db.rawQuery("SELECT COUNT(*) as c FROM (SELECT p.id FROM products p LEFT JOIN inventory_batches b ON p.id = b.product_id GROUP BY p.id HAVING COALESCE(SUM(b.quantity_remaining), 0) < 30 OR COALESCE(SUM(b.quantity_remaining), 0) <= p.min_stock)");
      final lowStockCount = lowStockCountRow.isNotEmpty ? lowStockCountRow.first['c'] : 0;

      final recentOutputs = await db.rawQuery("SELECT s.id, p.name as product_name, s.quantity, s.selling_price, s.total_profit, s.location, s.output_date FROM stock_outputs s JOIN products p ON s.product_id = p.id WHERE date(s.output_date) = date('now', 'localtime') ORDER BY s.output_date DESC");

      final lowStockProducts = await db.rawQuery("SELECT p.id, p.name, p.color, p.min_stock, COALESCE(SUM(b.quantity_remaining), 0) as current_stock FROM products p LEFT JOIN inventory_batches b ON p.id = b.product_id GROUP BY p.id HAVING current_stock < 30 OR current_stock <= p.min_stock ORDER BY current_stock ASC");

      final topProducts = await db.rawQuery("SELECT p.name, p.color, SUM(s.quantity) as total_qty FROM stock_outputs s JOIN products p ON s.product_id = p.id GROUP BY p.id ORDER BY total_qty DESC LIMIT 5");

      final topLocations = await db.rawQuery("SELECT location, SUM(quantity) as total_qty, SUM(total_profit) as total_profit FROM stock_outputs WHERE location IS NOT NULL AND location != '' GROUP BY location ORDER BY total_qty DESC LIMIT 5");

      final prods = await _productRepo.getAllProducts();
      double totalP = 0;
      double totalE = 0;
      for (var p in prods) {
        final double tE = p.stockQuantity * p.unitCostReal;
        final double tR = p.stockQuantity * p.salePrice;
        final double tP = tR - tE;
        totalE += tE;
        totalP += tP;
      }

      if (mounted) {
        _lastLoadTime = DateTime.now();
        setState(() {
          _products = prods;
          _globalTotalProfit = totalP;
          _globalTotalExpenses = totalE;
          _kpis = {
            'currentCash': currentCash,
            'dailyOutputs': dailyOutputs,
            'lowStockCount': lowStockCount,
          };
          _recentOutputs = recentOutputs;
          _lowStockAlerts = lowStockProducts;
          _topProducts = topProducts;
          _topLocations = topLocations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des données locales : $e';
          _isLoading = false;
        });
      }
    }
  }

  // Format monétaire (ex: 150000 -> 150 000 GNF)
  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 GNF';
    final num? parsedAmount = (amount is String) ? num.tryParse(amount) : amount as num?;
    if (parsedAmount == null) return '0 GNF';
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(parsedAmount)} GNF';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchDashboardData(force: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyBlue,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 16),
          _buildProductFilter(isDark), // Product Filter Dropdown
          const SizedBox(height: 24),
          _buildKpiSection(), // PRIORITÉ 1: KPIs
          const SizedBox(height: 24),
          if (_lowStockAlerts.isNotEmpty)
            _buildCriticalAlerts(isDark), // PRIORITÉ 2: Alertes Business
          if (_lowStockAlerts.isNotEmpty) const SizedBox(height: 24),
          _buildRecentActivitySection(isDark), // PRIORITÉ 3: Activité Récente (Table)
          const SizedBox(height: 32),
          _buildAnalyticsSection(isDark), // PRIORITÉ 4: Analytics Visuels
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vue d\'ensemble de l\'activité',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.navyBlue,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent,
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Système ERP synchronisé en temps réel',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.navyBlue : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.sync_rounded, color: isDark ? Colors.white : AppColors.navyBlue),
              onPressed: () => _fetchDashboardData(force: true),
              tooltip: 'Actualiser les données',
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection() {
    final double displayProfit = _selectedProduct != null
        ? ((_selectedProduct!.stockQuantity * _selectedProduct!.salePrice) - (_selectedProduct!.stockQuantity * _selectedProduct!.unitCostReal)).toDouble()
        : _globalTotalProfit;

    final double displayExpenses = _selectedProduct != null
        ? (_selectedProduct!.stockQuantity * _selectedProduct!.unitCostReal).toDouble()
        : _globalTotalExpenses;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Expanded(
          child: ErpStatCard(
            title: 'Caisse Actuelle',
            value: _formatCurrency(_kpis['currentCash']),
            icon: Icons.account_balance_wallet,
            color: AppColors.gold,
            subtitle: 'Solde disponible',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ErpStatCard(
            title: 'Bénéfice Total',
            value: _formatCurrency(displayProfit),
            icon: Icons.trending_up,
            color: AppColors.navyBlue,
            subtitle: _selectedProduct != null ? 'Bénéfice du produit' : 'Bénéfice de tout le stock',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ErpStatCard(
            title: 'Dépenses Totales',
            value: _formatCurrency(displayExpenses),
            icon: Icons.receipt_long_outlined,
            color: AppColors.gold,
            subtitle: _selectedProduct != null ? 'Dépense du produit' : 'Coût total du stock',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ErpStatCard(
            title: 'Produits Écoulés',
            value: '${_kpis['dailyOutputs'] ?? 0} Unités',
            icon: Icons.outbox_outlined,
            color: AppColors.navyBlue,
            subtitle: 'Sorties du jour',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ErpStatCard(
            title: 'Stock Faible',
            value: '${_kpis['lowStockCount'] ?? 0} Alertes',
            icon: Icons.warning_amber_rounded,
            color: AppColors.gold,
            subtitle: 'À surveiller',
          ),
        ),
      ],
    ),
  );
}

  Widget _buildProductFilter(bool isDark) {
    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyBlue : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProductModel>(
          isExpanded: true,
          value: _selectedProduct,
          hint: const Text('Sélectionner un produit (Filtre Global)'),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
          dropdownColor: isDark ? AppColors.navyBlue : Colors.white,
          items: [
            const DropdownMenuItem<ProductModel>(
              value: null,
              child: Text('Tous les produits (Stock Global)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ..._products.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text('${p.name}${(p.color != null && p.color != "Unique") ? " (${p.color!})" : ""}'),
                )),
          ],
          onChanged: (val) {
            setState(() {
              _selectedProduct = val;
            });
          },
        ),
      ),
    );
  }

  // PRIORITÉ 2: Alertes Business Critiques
  Widget _buildCriticalAlerts(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.red.withValues(alpha: 0.15),
                  Colors.red.withValues(alpha: 0.05),
                ]
              : [
                  Colors.red.shade50,
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Alertes de Stock',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _lowStockAlerts.map((alert) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navyBlue.withValues(alpha: 0.8) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark ? Colors.red.withValues(alpha: 0.3) : Colors.red.shade100,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${alert['name']} ${alert['color'] != null && alert['color'] != 'Unique' ? "(${alert['color']})" : ""}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textDark,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.redAccent, Colors.red],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Reste ${alert['current_stock']} pc',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // PRIORITÉ 3: Activité Récente (Sorties)
  Widget _buildRecentActivitySection(bool isDark) {
    return _buildTableContainer(
      title: 'Sorties du Jour',
      isDark: isDark,
      child: _buildOutputsTable(isDark),
    );
  }

  // PRIORITÉ 4: Analytics Visuels (Ciblé & Clair)
  Widget _buildAnalyticsSection(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildChartContainer(
            title: 'Top Produits (Rotation & Profit)',
            height: 350,
            isDark: isDark,
            child: _buildTopProductsList(isDark),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildChartContainer(
            title: 'Top Quartiers',
            height: 350,
            isDark: isDark,
            child: _buildTopLocationsList(isDark),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGETS UTILITAIRES ET TABLES REELLES
  // ==========================================

  Widget _buildChartContainer({
    required String title,
    required double height,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyBlue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildTableContainer({required String title, required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyBlue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildOutputsTable(bool isDark) {
    if (_recentOutputs.isEmpty) return const Padding(padding: EdgeInsets.all(16.0), child: Text("Aucune sortie récente.", style: TextStyle(fontStyle: FontStyle.italic)));
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.navyBlue.withValues(alpha: 0.03)),
        dataRowMinHeight: 56,
        dataRowMaxHeight: 56,
        dividerThickness: 0.5,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey.shade300 : AppColors.navyBlue,
          fontSize: 13,
        ),
        columns: const [
          DataColumn(label: Text('Produit (Couleur)')),
          DataColumn(label: Text('Qté')),
          DataColumn(label: Text('Quartier')),
          DataColumn(label: Text('Bénéfice Réel')),
          DataColumn(label: Text('Date')),
        ],
        rows: _recentOutputs.map((output) {
          String formattedDate = '';
          if (output['output_date'] != null) {
            try {
              final date = DateTime.parse(output['output_date']);
              formattedDate = DateFormat('dd MMM HH:mm', 'fr_FR').format(date);
            } catch (e) {
              formattedDate = output['output_date'].toString().substring(0, 10);
            }
          }

          return DataRow(
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      output['product_name'].toString(),
                      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textDark),
                    ),
                  ],
                )
              ),
              DataCell(Text(output['quantity'].toString(), style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87, fontWeight: FontWeight.w500))),
              DataCell(Text(output['location'].toString(), style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _formatCurrency(output['total_profit']),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  formattedDate,
                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey[600], fontSize: 13),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopProductsList(bool isDark) {
    if (_topProducts.isEmpty) {
      return Center(child: Text("Pas assez de données", style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)));
    }
    return ListView.separated(
      itemCount: _topProducts.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
      itemBuilder: (context, index) {
        final product = _topProducts[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.navyBlue.withValues(alpha: 0.1), AppColors.navyBlue.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: isDark ? Colors.white70 : AppColors.navyBlue,
              size: 20,
            ),
          ),
          title: Text(
            '${product['name']} ${product['color'] != null && product['color'] != 'Unique' ? "(${product['color']})" : ""}',
            style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textDark, fontSize: 14),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${product['total_qty']} unités écoulées',
              style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey[500], fontSize: 12),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up,
              color: Colors.green,
              size: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopLocationsList(bool isDark) {
    if (_topLocations.isEmpty) {
      return Center(child: Text("Pas assez de données", style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)));
    }
    return ListView.separated(
      itemCount: _topLocations.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
      itemBuilder: (context, index) {
        final loc = _topLocations[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gold.withValues(alpha: 0.2), AppColors.gold.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.gold,
              size: 22,
            ),
          ),
          title: Text(
            loc['location'],
            style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textDark, fontSize: 14),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${loc['total_qty']} unités',
              style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey[500], fontSize: 12),
            ),
          ),
          trailing: Text(
            _formatCurrency(loc['total_profit']),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }
}
