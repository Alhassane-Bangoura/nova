import 'package:flutter/material.dart';
import '../../../../core/database/database_helper.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

const double _sanctionAmount = 5000;

final _motifs = [
  'Retard (arrivée après 20h10)',
  'Débat pendant la réunion',
  'Action non liée à la réunion',
  'Absence sans motif',
  'Autre (préciser)',
];

class SanctionsPage extends StatefulWidget {
  const SanctionsPage({super.key});
  @override
  State<SanctionsPage> createState() => _SanctionsPageState();
}

class _SanctionsPageState extends State<SanctionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _sanctions = [];
  List<dynamic> _employees = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadSanctions(), _loadEmployees(), _loadStats()]);
    setState(() => _loading = false);
  }

  Future<void> _loadSanctions() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.rawQuery('''
        SELECT s.*, e.name as employee_name 
        FROM sanctions s 
        JOIN employees e ON s.employee_id = e.id 
        ORDER BY s.sanction_date DESC
      ''');
      if (mounted) setState(() => _sanctions = results);
    } catch (_) {}
  }

  Future<void> _loadEmployees() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query('employees', orderBy: 'name ASC');
      if (mounted) setState(() => _employees = results);
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final totalRow = await db.rawQuery('SELECT COUNT(*) as total FROM sanctions');
      final collectedRow = await db.rawQuery("SELECT SUM(amount) as collected FROM sanctions WHERE status = 'Payée'");
      final pendingRow = await db.rawQuery("SELECT SUM(amount) as pending FROM sanctions WHERE status = 'En attente'");
      
      if (mounted) {
        setState(() {
          _stats = {
            'total_sanctions': totalRow.first['total'] ?? 0,
            'total_collected': collectedRow.first['collected'] ?? 0,
            'total_pending': pendingRow.first['pending'] ?? 0,
          };
        });
      }
    } catch (_) {}
  }

  String _fmt(dynamic v) {
    final n = num.tryParse(v?.toString() ?? '0') ?? 0;
    return '${NumberFormat('#,##0', 'fr_FR').format(n)} GNF';
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update('sanctions', {'status': status}, where: 'id = ?', whereArgs: [int.parse(id)]);
      _loadAll();
    } catch (_) {}
  }

  Future<void> _showAddSanctionDialog() async {
    if (_employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ajoutez d'abord un membre d'équipe"), backgroundColor: Colors.orange),
      );
      return;
    }
    dynamic selectedEmployee;
    String? selectedMotif;
    final customMotifCtrl = TextEditingController();
    bool submitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.navyBlue, Color(0xFF1E293B)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(children: [
                const Icon(Icons.gavel, color: AppColors.gold, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text('Enregistrer une Sanction',
                  style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<dynamic>(
                decoration: _inputDeco('Sélectionner un membre', Icons.person),
                items: _employees.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e['name']?.toString() ?? ''),
                )).toList(),
                onChanged: (v) => setS(() => selectedEmployee = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: _inputDeco('Motif de la sanction', Icons.warning_amber),
                items: _motifs.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setS(() => selectedMotif = v),
              ),
              if (selectedMotif == 'Autre (préciser)') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: customMotifCtrl,
                  decoration: _inputDeco('Veuillez préciser le motif', Icons.edit_note),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Montant de la sanction :', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('5 000 GNF', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: submitting || selectedEmployee == null || selectedMotif == null || (selectedMotif == 'Autre (préciser)' && customMotifCtrl.text.trim().isEmpty) ? null : () async {
                  setS(() => submitting = true);
                  try {
                    final finalReason = selectedMotif == 'Autre (préciser)' ? customMotifCtrl.text.trim() : selectedMotif;
                    final db = await DatabaseHelper.instance.database;
                    await db.insert('sanctions', {
                      'employee_id': selectedEmployee['id'],
                      'reason': finalReason,
                      'amount': _sanctionAmount,
                    });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    _loadAll();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sanction enregistrée'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (_) {}
                  if (ctx.mounted) setS(() => submitting = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyBlue))
                  : Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
              )),
            ])),
          ]),
        ),
      )),
    );
  }

  Future<void> _showAddEmployeeDialog({dynamic emp}) async {
    final nameCtrl = TextEditingController(text: emp?['name'] ?? '');
    final roleCtrl = TextEditingController(text: emp?['role'] ?? '');
    final isEdit = emp != null;
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Icon(isEdit ? Icons.edit : Icons.person_add, color: AppColors.navyBlue),
              const SizedBox(width: 8),
              Text(isEdit ? 'Modifier le membre' : 'Ajouter un membre',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: _inputDeco('Nom complet', Icons.person)),
            const SizedBox(height: 12),
            TextField(controller: roleCtrl, decoration: _inputDeco('Rôle (ex: Commercial)', Icons.work)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: submitting ? null : () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  setS(() => submitting = true);
                  try {
                    final db = await DatabaseHelper.instance.database;
                    if (isEdit) {
                      await db.update('employees', {
                        'name': nameCtrl.text.trim(),
                        'role': roleCtrl.text.trim(),
                      }, where: 'id = ?', whereArgs: [emp['id']]);
                    } else {
                      await db.insert('employees', {
                        'name': nameCtrl.text.trim(),
                        'role': roleCtrl.text.trim(),
                      });
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadEmployees();
                  } catch (_) {}
                  if (ctx.mounted) setS(() => submitting = false);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyBlue, foregroundColor: Colors.white),
                child: submitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Modifier' : 'Ajouter'),
              ),
            ]),
          ]),
        ),
      )),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400]),
    prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.navyBlue, width: 2)),
  );

  @override
  Widget build(BuildContext context) {
    final total = _stats['total_sanctions'] ?? 0;
    final collected = _stats['total_collected'] ?? 0;
    final pending = _stats['total_pending'] ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sanctions Équipe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text('Gestion disciplinaire · 5 000 GNF / sanction · Caisse Sanctions indépendante',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ]),
        ElevatedButton.icon(
          onPressed: _showAddSanctionDialog,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('Nouvelle Sanction', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
      const SizedBox(height: 24),

      // Stats Cards
      Row(children: [
        _statCard('Total Sanctions', '$total', Icons.gavel, Colors.red.shade600, Colors.red.shade50),
        const SizedBox(width: 16),
        _statCard('Caisse Sanctions', _fmt(collected), Icons.account_balance_wallet, Colors.green.shade600, Colors.green.shade50),
        const SizedBox(width: 16),
        _statCard('En Attente', _fmt(pending), Icons.hourglass_empty, Colors.orange.shade600, Colors.orange.shade50),
        const SizedBox(width: 16),
        _statCard('Membres Équipe', '${_employees.length}', Icons.group, AppColors.navyBlue, AppColors.navyBlue.withValues(alpha: 0.05)),
      ]),
      const SizedBox(height: 24),

      // Tabs
      Expanded(
        child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.gold,
              labelColor: AppColors.navyBlue,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: '  Historique des Sanctions  '),
                Tab(text: '  Gestion de l\'Équipe  '),
              ],
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : TabBarView(controller: _tabController, children: [
                  _buildSanctionsList(),
                  _buildEmployeesList(),
                ]),
          ),
        ]),
      )),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color bg) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ));
  }

  Widget _buildSanctionsList() {
    if (_sanctions.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.gavel, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Aucune sanction enregistrée', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
      ]));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.backgroundLight),
          columns: [
            DataColumn(label: Text('Membre', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
            DataColumn(label: Text('Motif', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
            DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
            DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
          ],
          rows: _sanctions.map((s) {
            final status = s['status']?.toString() ?? 'En attente';
            final date = s['sanction_date']?.toString() ?? '';
            String fmtDate = '-';
            try { fmtDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(date).toLocal()); } catch (_) {}

            Color statusColor = Colors.orange;
            if (status == 'Payée') statusColor = Colors.green;
            if (status == 'Annulée') statusColor = Colors.grey;

            return DataRow(cells: [
              DataCell(Text(s['employee_name']?.toString() ?? s['emp_name']?.toString() ?? '-',
                style: TextStyle(fontWeight: FontWeight.bold))),
              DataCell(SizedBox(width: 200, child: Text(s['reason']?.toString() ?? '-',
                style: TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))),
              DataCell(Text('${NumberFormat('#,##0', 'fr_FR').format(s['amount'] ?? _sanctionAmount)} GNF',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red))),
              DataCell(Text(fmtDate, style: TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              )),
              DataCell(status == 'En attente' ? Row(children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                  tooltip: 'Marquer comme Payée',
                  onPressed: () => _updateStatus(s['id'].toString(), 'Payée'),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.grey, size: 20),
                  tooltip: 'Annuler',
                  onPressed: () => _updateStatus(s['id'].toString(), 'Annulée'),
                ),
              ]) : const SizedBox()),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmployeesList() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          ElevatedButton.icon(
            onPressed: () => _showAddEmployeeDialog(),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Ajouter un membre'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyBlue, foregroundColor: Colors.white),
          ),
        ]),
      ),
      if (_employees.isEmpty)
        Expanded(child: Center(child: Text('Aucun membre dans l\'équipe',
          style: TextStyle(color: Colors.grey[500]))))
      else
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _employees.length,
            itemBuilder: (context, i) {
              final e = _employees[i];
              final name = e['name']?.toString() ?? '';
              final role = e['role']?.toString() ?? 'Membre';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(role, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600, fontSize: 14)),
                  ])),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.navyBlue, size: 20),
                    onPressed: () => _showAddEmployeeDialog(emp: e),
                  ),
                ]),
              );
            },
          ),
        ),
    ]);
  }
}
