import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

const String _auditBaseUrl = 'http://localhost:3000/api';

class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _logs = [];
  Map<String, dynamic> _stats = {'total': 0, 'VENTE': 0, 'DEPENSE': 0, 'STOCK': 0, 'SANCTION': 0};

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedType = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  // Cache simple pour éviter rechargements inutiles
  String? _lastQueryKey;

  final Map<String, Map<String, dynamic>> _typeConfig = {
    'ALL':      {'label': 'Tous',        'icon': Icons.history,              'color': Colors.blueGrey},
    'VENTE':    {'label': 'Ventes',      'icon': Icons.point_of_sale,        'color': Colors.green},
    'DEPENSE':  {'label': 'Dépenses',    'icon': Icons.money_off,            'color': Colors.red},
    'STOCK':    {'label': 'Stock',       'icon': Icons.inventory_2,          'color': Colors.blue},
    'SANCTION': {'label': 'Sanctions',   'icon': Icons.gavel,                'color': Colors.orange},
  };

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _buildQueryKey() {
    final s = DateFormat('yyyy-MM-dd').format(_startDate);
    final e = DateFormat('yyyy-MM-dd').format(_endDate);
    return '$s|$e|$_selectedType|${_searchController.text.trim()}';
  }

  Future<void> _loadData() async {
    final key = _buildQueryKey();
    if (key == _lastQueryKey && !_isLoading) return; // éviter double chargement

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final s = DateFormat('yyyy-MM-dd').format(_startDate);
      final e = DateFormat('yyyy-MM-dd').format(_endDate);
      final type = _selectedType == 'ALL' ? '' : _selectedType;
      final search = _searchController.text.trim();

      final uri = Uri.parse('$_auditBaseUrl/audit?startDate=$s&endDate=$e&actionType=$type&search=$search');
      final r = await http.get(uri).timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final d = json.decode(r.body);
        if (mounted) {
          setState(() {
            _logs = d['data']['logs'] ?? [];
            _stats = Map<String, dynamic>.from(d['data']['stats'] ?? {});
            _isLoading = false;
            _lastQueryKey = key;
          });
        }
      } else {
        throw Exception('Erreur serveur: ${r.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.navyBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { _startDate = picked.start; _endDate = picked.end; });
      _loadData();
    }
  }

  // ────────────────────────────────────────────────────────────────
  // Dialogue de détail d'un log
  // ────────────────────────────────────────────────────────────────
  void _showLogDetail(Map<String, dynamic> log) {
    final type = log['action_type']?.toString() ?? 'AUTRE';
    final cfg = _typeConfig[type] ?? {'icon': Icons.info_outline, 'color': Colors.grey, 'label': type};
    final color = cfg['color'] as Color;
    final icon = cfg['icon'] as IconData;

    DateTime? dt;
    try { dt = DateTime.parse(log['created_at'] ?? ''); } catch (_) {}
    final dateStr = dt != null
        ? DateFormat('dd MMMM yyyy à HH:mm:ss', 'fr_FR').format(dt.toLocal())
        : '—';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width > 550 ? 500 : MediaQuery.of(context).size.width * 0.95,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête coloré selon le type
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cfg['label'] as String,
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text('Détail de l\'action', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Contenu
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(Icons.description_outlined, 'Description', log['description']?.toString() ?? '—', color),
                    const SizedBox(height: 16),
                    _detailRow(Icons.category_outlined, 'Module', log['entity_name']?.toString() ?? '—', color),
                    const SizedBox(height: 16),
                    _detailRow(Icons.person_outline, 'Effectué par', log['employee_name']?.toString() ?? '—', color),
                    const SizedBox(height: 16),
                    _detailRow(Icons.schedule, 'Date & Heure', dateStr, color),
                    const SizedBox(height: 16),
                    _detailRow(Icons.tag, 'ID de l\'action', '#${log['id']?.toString() ?? '?'}', color),
                  ],
                ),
              ),
              // Bouton fermer
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── En-tête ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audit & Historique',
                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navyBlue),
                ),
                Text('Cliquez sur une action pour voir les détails', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
            Row(
              children: [
                // Bouton rafraîchir
                IconButton(
                  onPressed: () { _lastQueryKey = null; _loadData(); },
                  icon: const Icon(Icons.refresh, color: AppColors.navyBlue),
                  tooltip: 'Actualiser',
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _selectDateRange,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: AppColors.navyBlue),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(_startDate)} – ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.navyBlue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Cartes KPI ───────────────────────────────────────────────────────
        _buildStatCards(),
        const SizedBox(height: 20),

        // ── Filtres ──────────────────────────────────────────────────────────
        _buildFilters(),
        const SizedBox(height: 20),

        // ── Liste des logs ────────────────────────────────────────────────────
        Expanded(child: _buildLogList()),
      ],
    );
  }

  Widget _buildStatCards() {
    final cards = [
      {'key': 'total',    'label': 'Total Actions',   'icon': Icons.history,       'color': AppColors.navyBlue},
      {'key': 'VENTE',    'label': 'Ventes',          'icon': Icons.point_of_sale, 'color': Colors.green.shade700},
      {'key': 'DEPENSE',  'label': 'Dépenses',        'icon': Icons.money_off,     'color': Colors.red.shade600},
      {'key': 'STOCK',    'label': 'Mvts Stock',      'icon': Icons.inventory_2,   'color': Colors.blue.shade600},
      {'key': 'SANCTION', 'label': 'Sanctions',       'icon': Icons.gavel,         'color': Colors.orange.shade700},
    ];
    return Row(
      children: cards.asMap().entries.map((entry) {
        final i = entry.key;
        final c = entry.value;
        final count = _stats[c['key']] ?? 0;
        final color = c['color'] as Color;
        final isFilterable = c['key'] != 'total';
        return Expanded(
          child: GestureDetector(
            onTap: isFilterable ? () {
              setState(() => _selectedType = c['key'] as String);
              _loadData();
            } : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < cards.length - 1 ? 12 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedType == c['key'] ? color.withValues(alpha: 0.12) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedType == c['key'] ? color : Colors.transparent, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(c['icon'] as IconData, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                      Text(c['label'] as String, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par description, employé, module...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _loadData(); })
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.navyBlue)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onSubmitted: (_) => _loadData(),
          ),
        ),
        const SizedBox(width: 16),
        ...['ALL', 'VENTE', 'DEPENSE', 'STOCK', 'SANCTION'].map((type) {
          final cfg = _typeConfig[type]!;
          final isSelected = _selectedType == type;
          final color = cfg['color'] as Color;
          return GestureDetector(
            onTap: () { setState(() => _selectedType = type); _loadData(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? color : Colors.grey.shade300),
                boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cfg['icon'] as IconData, size: 14, color: isSelected ? Colors.white : color),
                  const SizedBox(width: 6),
                  Text(
                    cfg['label'] as String,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : color),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLogList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Impossible de charger l\'historique', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () { _lastQueryKey = null; _loadData(); },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyBlue, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text('Aucune activité enregistrée', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            Text('pour la période sélectionnée', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // En-tête tableau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.navyBlue.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 44),
                Expanded(flex: 3, child: Text('Description', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.grey.shade700, fontSize: 13))),
                Expanded(flex: 1, child: Text('Module', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.grey.shade700, fontSize: 13))),
                Expanded(flex: 1, child: Text('Employé', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.grey.shade700, fontSize: 13))),
                SizedBox(width: 140, child: Text('Date & Heure', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.grey.shade700, fontSize: 13))),
                const SizedBox(width: 32),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lignes
          Expanded(
            child: ListView.separated(
              itemCount: _logs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (context, i) => _buildLogRow(_logs[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogRow(Map<String, dynamic> log) {
    final type = log['action_type']?.toString() ?? 'AUTRE';
    final cfg = _typeConfig[type] ?? {'icon': Icons.info_outline, 'color': Colors.grey, 'label': type};
    final color = cfg['color'] as Color;
    final icon = cfg['icon'] as IconData;

    DateTime? dt;
    try { dt = DateTime.parse(log['created_at'] ?? ''); } catch (_) {}
    final dateStr = dt != null ? DateFormat('dd/MM/yy à HH:mm', 'fr_FR').format(dt.toLocal()) : '—';

    return InkWell(
      onTap: () => _showLogDetail(log),
      hoverColor: color.withValues(alpha: 0.04),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Icône type
            Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 15, color: color),
            ),
            // Description
            Expanded(
              flex: 3,
              child: Text(
                log['description']?.toString() ?? '—',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Module
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  log['entity_name']?.toString() ?? '—',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Employé
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.navyBlue.withValues(alpha: 0.1),
                    child: Text(
                      (log['employee_name']?.toString() ?? '?').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.navyBlue),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      log['employee_name']?.toString() ?? '—',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Date
            SizedBox(
              width: 140,
              child: Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ),
            // Icône "voir détails"
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
