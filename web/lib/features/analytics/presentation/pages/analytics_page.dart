import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'dart:typed_data';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/erp_stat_card.dart';

const String _baseUrl = 'http://localhost:3000/api';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _selectedProductId = 'all';
  List<dynamic> _products = [];

  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _loadData();
  }

  Future<void> _fetchProducts() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/products'));
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _products = json.decode(res.body)['data'];
          });
        }
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final s = DateFormat('yyyy-MM-dd').format(_startDate);
      final e = DateFormat('yyyy-MM-dd').format(_endDate);
      
      final r = await http.get(Uri.parse('$_baseUrl/analytics/dashboard?startDate=$s&endDate=$e&productId=$_selectedProductId'));
      if (r.statusCode == 200) {
        final d = json.decode(r.body);
        if (mounted) {
          setState(() {
            _data = d['data'];
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Erreur serveur: ${r.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.navyBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  void _setPreset(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = DateTime.now().subtract(Duration(days: days));
    });
    _loadData();
  }

  String _fmt(dynamic v) {
    final n = num.tryParse(v?.toString() ?? '0') ?? 0;
    return '${NumberFormat('#,##0', 'fr_FR').format(n)} GNF';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rapports & Analytics',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyBlue,
                  ),
                ),
                Text(
                  'Vision globale de vos performances',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            Row(
              children: [
                _buildDateSelector(),
                const SizedBox(width: 16),
                _buildExportMenu(),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.gold)))
        else if (_errorMessage != null)
          Expanded(child: Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))))
        else if (_data != null)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKPIs(),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildLineChart()),
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: _buildPieChart()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTopProducts()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildComparison()),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        // Product Dropdown
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProductId,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.navyBlue),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.navyBlue),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('Tous les produits')),
                ..._products.map((p) => DropdownMenuItem(
                  value: p['id'].toString(),
                  child: Text(p['name'].toString()),
                )),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedProductId = val);
                  _loadData();
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        TextButton(
          onPressed: () => _setPreset(7),
          child: const Text('7 Jours', style: TextStyle(color: AppColors.navyBlue)),
        ),
        TextButton(
          onPressed: () => _setPreset(30),
          child: const Text('Ce Mois', style: TextStyle(color: AppColors.navyBlue)),
        ),
        InkWell(
          onTap: () => _selectDateRange(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportMenu() {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'pdf') _exportPdf();
        if (val == 'csv') _exportCsv();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red), SizedBox(width: 8), Text('Export PDF (Logo Nova)')])),
        const PopupMenuItem(value: 'csv', child: Row(children: [Icon(Icons.table_chart, color: Colors.green), SizedBox(width: 8), Text('Export CSV / Excel')])),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.download, size: 18, color: AppColors.navyBlue),
            const SizedBox(width: 8),
            Text('Exporter', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIs() {
    final kpis = _data!['kpis'];
    return Row(
      children: [
        Expanded(child: ErpStatCard(title: 'Chiffre d\'Affaires', value: _fmt(kpis['totalRevenue']), icon: Icons.attach_money, color: Colors.green.shade700)),
        const SizedBox(width: 16),
        Expanded(child: ErpStatCard(title: 'Bénéfice Net', value: _fmt(kpis['totalProfit']), icon: Icons.trending_up, color: AppColors.gold)),
        const SizedBox(width: 16),
        Expanded(child: ErpStatCard(title: 'Dépenses Totales', value: _fmt(kpis['totalExpenses']), icon: Icons.money_off, color: Colors.red.shade600)),
        const SizedBox(width: 16),
        Expanded(child: ErpStatCard(title: 'Sanctions Équipe', value: '${_data!['sanctionsCount']} Enregistrée(s)', icon: Icons.gavel, color: Colors.orange.shade700)),
      ],
    );
  }

  Widget _buildLineChart() {
    final List<dynamic> evol = _data!['dailyEvolution'] ?? [];
    if (evol.isEmpty) return _emptyCard('Pas de données pour le graphique');

    final List<FlSpot> revSpots = [];
    final List<FlSpot> profSpots = [];
    
    for (int i = 0; i < evol.length; i++) {
      revSpots.add(FlSpot(i.toDouble(), (evol[i]['revenue'] as num).toDouble()));
      profSpots.add(FlSpot(i.toDouble(), (evol[i]['profit'] as num).toDouble()));
    }

    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Évolution Ventes vs Bénéfices', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100000,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: evol.length > 5 ? (evol.length / 5).ceilToDouble() : 1,
                      getTitlesWidget: (val, meta) {
                        final index = val.toInt();
                        if (index < 0 || index >= evol.length) return const SizedBox.shrink();
                        // Format date like '15 Mai'
                        final dateStr = evol[index]['date'].toString();
                        final d = DateTime.tryParse(dateStr);
                        if (d == null) return const SizedBox.shrink();
                        final fmt = DateFormat('dd MMM').format(d);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(fmt, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return const SizedBox.shrink();
                        final String text = val >= 1000000 
                            ? '${(val / 1000000).toStringAsFixed(1)}M'
                            : '${(val / 1000).toStringAsFixed(0)}k';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.right),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: revSpots,
                    isCurved: true,
                    curveSmoothness: 0.5,
                    preventCurveOverShooting: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [Colors.green.withValues(alpha: 0.18), Colors.green.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: profSpots,
                    isCurved: true,
                    curveSmoothness: 0.5,
                    preventCurveOverShooting: true,
                    color: AppColors.gold,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.gold.withValues(alpha: 0.15), AppColors.gold.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: _legendItem(Colors.green, 'Chiffre d\'Affaires')),
              const SizedBox(width: 24),
              Expanded(child: _legendItem(AppColors.gold, 'Bénéfice')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final List<dynamic> dist = _data!['expenseDistribution'] ?? [];
    if (dist.isEmpty) return _emptyCard('Aucune dépense sur la période');

    final colors = [Colors.red.shade400, Colors.blue.shade400, Colors.orange.shade400, Colors.purple.shade400, Colors.teal.shade400];
    
    List<PieChartSectionData> sections = [];
    for (int i = 0; i < dist.length; i++) {
      final val = (dist[i]['total_amount'] as num).toDouble();
      final percentage = (val / dist.fold(0.0, (sum, item) => sum + (item['total_amount'] as num))) * 100;
      sections.add(PieChartSectionData(
        color: colors[i % colors.length],
        value: val,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Répartition des Dépenses', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: PieChart(
              PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: sections),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(dist.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _legendItem(colors[i % colors.length], dist[i]['category'], (dist[i]['total_amount'] as num).toDouble()),
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final List<dynamic> top = _data!['topProducts'] ?? [];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top 5 Produits Vendus', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (top.isEmpty) const Text('Aucune vente enregistrée.')
          else ...top.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(p['name'].toString().toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13))),
                Text('${p['total_quantity']} unités', style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                Text(_fmt(p['revenue']), style: GoogleFonts.inter(color: AppColors.navyBlue, fontWeight: FontWeight.w900)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildComparison() {
    final List<dynamic> comp = _data!['productComparison'] ?? [];
    
    double genProfit = 0;
    double casProfit = 0;
    for (var c in comp) {
      if (c['product_group'] == 'Genouillères') genProfit = (c['profit'] as num).toDouble();
      if (c['product_group'] == 'Casques') casProfit = (c['profit'] as num).toDouble();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comparatif Bénéfices', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _compCard('Genouillères', genProfit, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _compCard('Casques Enfant', casProfit, Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compCard(String title, double value, Color c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_fmt(value), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
        ],
      ),
    );
  }

  Widget _legendItem(Color c, String text, [double? amount]) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
        ),
        if (amount != null) ...[
          const SizedBox(width: 8),
          Text(_fmt(amount), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black87)),
        ]
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      height: 350,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.grey))),
    );
  }

  Future<void> _exportPdf() async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Text('NOVA GENIX DIGITAL - ERP', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xff1B2B48)))),
                pw.SizedBox(height: 10),
                pw.Center(child: pw.Text('Rapport Analytique', style: pw.TextStyle(fontSize: 18))),
                pw.Center(child: pw.Text('Période: ${DateFormat('dd/MM/yyyy').format(_startDate)} au ${DateFormat('dd/MM/yyyy').format(_endDate)}')),
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text('RÉSUMÉ FINANCIER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.Text('Chiffre d\'Affaires: ${_fmt(_data!['kpis']['totalRevenue'])}'),
                pw.Text('Bénéfice Net: ${_fmt(_data!['kpis']['totalProfit'])}'),
                pw.Text('Dépenses Totales: ${_fmt(_data!['kpis']['totalExpenses'])}'),
                pw.Text('Sanctions Équipe: ${_data!['sanctionsCount']} enregistrée(s)'),
                
                pw.SizedBox(height: 30),
                pw.Text('TOP PRODUITS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.SizedBox(height: 10),
                ...(_data!['topProducts'] as List).map((p) => pw.Text('${p['name']} : ${p['total_quantity']} unités vendues -> ${_fmt(p['revenue'])}')),
              ],
            );
          },
        ),
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Rapport_Nova_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur export PDF: $e')));
    }
  }

  Future<void> _exportCsv() async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(["Rapport Nova Genix", "${DateFormat('dd/MM/yyyy').format(_startDate)} au ${DateFormat('dd/MM/yyyy').format(_endDate)}"]);
      rows.add([]);
      rows.add(["Indicateur", "Valeur"]);
      rows.add(["Chiffre d'Affaires", _data!['kpis']['totalRevenue']]);
      rows.add(["Bénéfice Net", _data!['kpis']['totalProfit']]);
      rows.add(["Dépenses Totales", _data!['kpis']['totalExpenses']]);
      rows.add(["Sanctions Équipe", _data!['sanctionsCount']]);
      rows.add([]);
      rows.add(["Top Produits", "Quantité", "Revenu"]);
      for (var p in _data!['topProducts']) {
        rows.add([p['name'], p['total_quantity'], p['revenue']]);
      }
      
      String csvData = rows.map((r) => r.map((c) => '"${c.toString().replaceAll('"', '""')}"').join(',')).join('\n');
      
      await Printing.sharePdf(bytes: Uint8List.fromList(utf8.encode(csvData)), filename: 'Rapport_Nova.csv');
      
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur export CSV: $e')));
    }
  }
}
