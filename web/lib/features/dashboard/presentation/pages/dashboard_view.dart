import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/erp_stat_card.dart';

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
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/dashboard'),
      ).timeout(const Duration(seconds: 5)); // Timeout strict 5s

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          _lastLoadTime = DateTime.now();
          setState(() {
            _kpis = decoded['data']['kpis'];
            _recentOutputs = decoded['data']['tables']['recentOutputs'];
            _lowStockAlerts = decoded['data']['alerts']['lowStockProducts'] ?? [];
            _topProducts = decoded['data']['productsPerformance']['topByVolume'] ?? [];
            _topLocations = decoded['data']['locationsPerformance']['topLocations'] ?? [];
            _financialEvolution = decoded['data']['evolution']['financial'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Format de réponse invalide.'; _isLoading = false; });
        }
      } else {
        setState(() { _errorMessage = 'Erreur serveur: ${response.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de se connecter au serveur local. Vérifiez que Node.js tourne.';
        _isLoading = false;
      });
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
                style: GoogleFonts.outfit(
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
                    style: GoogleFonts.inter(
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
            title: 'Bénéfice (Jour)',
            value: _formatCurrency(_kpis['dailyProfit']),
            icon: Icons.trending_up,
            color: AppColors.navyBlue,
            subtitle: 'Profit net du jour',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ErpStatCard(
            title: 'Dépenses (Jour)',
            value: _formatCurrency(_kpis['dailyExpenses']),
            icon: Icons.receipt_long_outlined,
            color: AppColors.gold,
            subtitle: 'Charges du jour',
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
                style: GoogleFonts.outfit(
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
                      style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
            style: GoogleFonts.outfit(
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
            style: GoogleFonts.outfit(
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
        headingTextStyle: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textDark),
                    ),
                  ],
                )
              ),
              DataCell(Text(output['quantity'].toString(), style: GoogleFonts.inter(color: isDark ? Colors.grey.shade300 : Colors.black87, fontWeight: FontWeight.w500))),
              DataCell(Text(output['location'].toString(), style: GoogleFonts.inter(color: isDark ? Colors.grey.shade300 : Colors.black87))),
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
                    style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(color: isDark ? Colors.grey.shade400 : Colors.grey[600], fontSize: 13),
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
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textDark, fontSize: 14),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${product['total_qty']} unités écoulées',
              style: GoogleFonts.inter(color: isDark ? Colors.grey.shade500 : Colors.grey[500], fontSize: 12),
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
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textDark, fontSize: 14),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${loc['total_qty']} unités',
              style: GoogleFonts.inter(color: isDark ? Colors.grey.shade500 : Colors.grey[500], fontSize: 12),
            ),
          ),
          trailing: Text(
            _formatCurrency(loc['total_profit']),
            style: GoogleFonts.inter(
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
