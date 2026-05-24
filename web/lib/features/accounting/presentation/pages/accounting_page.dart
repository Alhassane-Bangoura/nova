
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/erp_stat_card.dart';

class AccountingPage extends StatefulWidget {
  const AccountingPage({super.key});

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> {
  bool _isLoading = true;
  String _errorMessage = '';

  Map<String, dynamic> _profitSummary = {};
  List<dynamic> _cashHistory = [];
  List<dynamic> _expensesByCategory = [];
  List<dynamic> _recentExpenses = [];

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  Future<void> _fetchFinancialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final accRes = await ApiService.get('/accounting/dashboard');
      final expRes = await ApiService.get('/expenses');

      if (accRes['success'] == true && expRes['success'] == true) {
        final accData = accRes['data']['data'];
        final expData = expRes['data']['data'];

        setState(() {
          _profitSummary = accData['profitSummary'] ?? {};
          _cashHistory = accData['cashHistory'] ?? [];
          _expensesByCategory = accData['expensesByCategory'] ?? [];
          _recentExpenses = expData ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = accRes['message'] ?? expRes['message'] ?? "Erreur lors du chargement des données financières.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur de connexion au serveur.";
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return "0 GNF";
    final num? parsed = (amount is String) ? num.tryParse(amount) : amount as num?;
    if (parsed == null) return "0 GNF";
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);
    return formatter.format(parsed);
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM/yy HH:mm').format(date);
    } catch (_) {
      return isoString.substring(0, 10);
    }
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NewExpenseDialog(
        onSuccess: () => _fetchFinancialData(),
      ),
    );
  }

  void _showFundCaisseDialog() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool loading = false;
    String err = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: SizedBox(
              width: MediaQuery.of(ctx).size.width > 550 ? 500 : MediaQuery.of(ctx).size.width * 0.95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF0A7C48), Color(0xFF14213D)]),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: AppColors.gold, size: 28),
                        const SizedBox(width: 16),
                        Expanded(child: Text('Alimenter la Caisse', style: GoogleFonts.outfit(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold))),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (err.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Text(err, style: TextStyle(color: Colors.red.shade700)),
                          ),
                        TextFormField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Montant à ajouter (GNF)',
                            prefixIcon: const Icon(Icons.add_circle_outline, color: Color(0xFF0A7C48)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0A7C48), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: noteCtrl,
                          decoration: InputDecoration(
                            labelText: 'Note (optionnel)',
                            prefixIcon: const Icon(Icons.note_alt_outlined, color: AppColors.navyBlue),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.navyBlue, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Annuler', style: TextStyle(color: Colors.grey.shade700)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, color: Colors.white, size: 18),
                          label: const Text('Confirmer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A7C48), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                          onPressed: loading ? null : () async {
                            final amount = double.tryParse(amountCtrl.text);
                            if (amount == null || amount <= 0) {
                              setDlgState(() => err = 'Veuillez entrer un montant valide.');
                              return;
                            }
                            setDlgState(() => loading = true);
                            try {
                              final res = await ApiService.post('/accounting/fund-cash', {
                                'amount': amount,
                                'note': noteCtrl.text.isNotEmpty ? noteCtrl.text : 'Alimentation manuelle de caisse',
                              });
                              if (res['success'] == true) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                _fetchFinancialData();
                              } else {
                                setDlgState(() { err = res['message'] ?? 'Erreur.'; loading = false; });
                              }
                            } catch (e) {
                              setDlgState(() { err = 'Erreur de connexion.'; loading = false; });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));

    final currentCash = _cashHistory.isNotEmpty ? _cashHistory.first['balance_after'] : 0;
    final grossProfit = _profitSummary['gross_profit'] ?? 0;
    final totalExpenses = _profitSummary['total_expenses'] ?? 0;
    final netProfit = _profitSummary['net_profit'] ?? 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contrôle Financier & Caisse',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showFundCaisseDialog,
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                    label: const Text('Alimenter la Caisse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A7C48),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddExpenseDialog,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 18),
                    label: const Text('Enregistrer Dépense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildKpis(currentCash, grossProfit, totalExpenses, netProfit),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildSectionContainer(
                  title: 'Livre de Caisse (Chronologie)',
                  icon: Icons.history,
                  isDark: isDark,
                  child: _buildCashLedger(isDark),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildSectionContainer(
                      title: 'Répartition Dépenses',
                      icon: Icons.pie_chart_outline,
                      isDark: isDark,
                      child: _buildExpenseDistribution(isDark),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionContainer(
                      title: 'Dépenses Récentes',
                      icon: Icons.receipt_long_outlined,
                      isDark: isDark,
                      child: _buildRecentExpenses(isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildKpis(dynamic cash, dynamic gross, dynamic exp, dynamic net) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ErpStatCard(title: 'Caisse Actuelle', value: _formatCurrency(cash), icon: Icons.account_balance_wallet, color: AppColors.navyBlue, subtitle: 'Disponibilité immédiate')),
          const SizedBox(width: 16),
          Expanded(child: ErpStatCard(title: 'Bénéfice Brut', value: _formatCurrency(gross), icon: Icons.monetization_on, color: Colors.blue, subtitle: 'Profit généré par les ventes')),
          const SizedBox(width: 16),
          Expanded(child: ErpStatCard(title: 'Total Dépenses', value: _formatCurrency(exp), icon: Icons.arrow_downward, color: Colors.red, subtitle: 'Toutes charges confondues')),
          const SizedBox(width: 16),
          Expanded(child: ErpStatCard(title: 'Bénéfice Net Réel', value: _formatCurrency(net), icon: Icons.trending_up, color: Colors.green, subtitle: 'Bénéfice après toutes charges')),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required String title, required IconData icon, required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyBlue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isDark ? Colors.white : AppColors.navyBlue, size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCashLedger(bool isDark) {
    if (_cashHistory.isEmpty) return const Text("Aucune transaction enregistrée.");
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(isDark ? AppColors.backgroundDark : Colors.grey[50]),
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Origine')),
          DataColumn(label: Text('Montant')),
          DataColumn(label: Text('Nouveau Solde')),
        ],
        rows: _cashHistory.map((trx) {
          final isIncome = trx['type'] == 'IN';
          return DataRow(cells: [
            DataCell(Text(_formatDate(trx['transaction_date']), style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : null))),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isIncome ? 'ENTRÉE' : 'SORTIE',
                  style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            DataCell(Text(trx['reference_type'].toString(), style: TextStyle(color: isDark ? Colors.grey.shade300 : null))),
            DataCell(Text(_formatCurrency(trx['amount']), style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
            DataCell(Text(_formatCurrency(trx['balance_after']), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.navyBlue))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildExpenseDistribution(bool isDark) {
    if (_expensesByCategory.isEmpty) return const Text("Aucune dépense.");
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _expensesByCategory.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final cat = _expensesByCategory[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.category, color: AppColors.gold),
          title: Text(cat['category'].toString(), style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
          trailing: Text(_formatCurrency(cat['total_amount']), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        );
      },
    );
  }

  Widget _buildRecentExpenses(bool isDark) {
    if (_recentExpenses.isEmpty) return const Text("Aucune dépense.");
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentExpenses.length > 5 ? 5 : _recentExpenses.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final exp = _recentExpenses[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(exp['description'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
          subtitle: Text(exp['category'].toString(), style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey[600], fontSize: 12)),
          trailing: Text(_formatCurrency(exp['amount']), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        );
      },
    );
  }
}

class _NewExpenseDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const _NewExpenseDialog({required this.onSuccess});

  @override
  State<_NewExpenseDialog> createState() => _NewExpenseDialogState();
}

class _NewExpenseDialogState extends State<_NewExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Connexion (Publicité)';
  bool _isSubmitting = false;
  String _error = '';

  final List<String> _categories = [
    'Connexion (Publicité)',
    'Connexion (Réception Msgs)',
    'Crédit (Appels WhatsApp)',
    'Boostage (Hebdomadaire)',
    'Autres Dépenses'
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = '';
    });

    final amount = double.tryParse(_amountController.text) ?? 0;

    try {
      final res = await ApiService.post('/expenses', {
        'category': _selectedCategory,
        'amount': amount,
        'description': _descController.text,
      });

      if (res['success'] == true) {
        if (mounted) Navigator.of(context).pop();
        widget.onSuccess();
      } else {
        String errMsg;
        if (res['code'] == 'INSUFFICIENT_CASH') {
          final cash = res['currentCash'] ?? 0;
          final needed = res['requested'] ?? 0;
          final formatter = NumberFormat('#,###', 'fr_FR');
          errMsg = '⚠️ Caisse insuffisante !\n'
              'Solde actuel : ${formatter.format(cash)} GNF\n'
              'Montant demandé : ${formatter.format(needed)} GNF\n'
              'Veuillez alimenter la caisse avant d\'effectuer cette dépense.';
        } else {
          errMsg = res['message'] ?? 'Erreur lors de la création de la dépense.';
        }
        setState(() {
          _error = errMsg;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur de connexion.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration buildInputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.navyBlue.withValues(alpha: 0.5), size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.navyBlue, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
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
                  const Icon(Icons.receipt_long, color: AppColors.gold, size: 28),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Enregistrer une Dépense', style: GoogleFonts.outfit(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
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
                    children: [
                      if (_error.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.red.shade50,
                          child: Text(_error, style: TextStyle(color: Colors.red.shade700)),
                        ),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: buildInputDecoration('Catégorie', Icons.category),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: buildInputDecoration('Montant (GNF)', Icons.money),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Requis';
                          if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Montant invalide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        decoration: buildInputDecoration('Description claire', Icons.description),
                        validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
                      ),
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
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: Text('Annuler', style: TextStyle(color: Colors.grey.shade700)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.navyBlue),
                    child: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.navyBlue, strokeWidth: 2))
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
}
