import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
// PAGE PRINCIPALE — SORTIES PRODUITS
// ─────────────────────────────────────────────────────────────
class StockOutputsPage extends StatefulWidget {
  const StockOutputsPage({super.key});

  @override
  State<StockOutputsPage> createState() => _StockOutputsPageState();
}

class _StockOutputsPageState extends State<StockOutputsPage> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<dynamic> _outputs = [];

  @override
  void initState() {
    super.initState();
    _fetchOutputs();
  }

  Future<void> _fetchOutputs() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/stock_outputs'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          setState(() { _outputs = decoded['data']; _isLoading = false; });
        }
      } else {
        setState(() { _errorMessage = 'Erreur serveur: ${response.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _errorMessage = 'Impossible de se connecter au serveur local.'; _isLoading = false; });
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 GNF';
    final num? parsedAmount = (amount is String) ? num.tryParse(amount) : amount as num?;
    if (parsedAmount == null) return '0 GNF';
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(parsedAmount)} GNF';
  }

  Future<void> _openNewOutputDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const NewOutputDialog(),
    );
    // Rafraîchir la liste si une sortie a été créée
    if (result == true) {
      _fetchOutputs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sorties Produits',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Historique des sorties · Calcul bénéfice automatique · Stock mis à jour en temps réel',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _openNewOutputDialog,
          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
          label: Text('Enregistrer une Sortie',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Map<String, List<dynamic>> _groupOutputsByDay() {
    final Map<String, List<dynamic>> grouped = {};
    for (var output in _outputs) {
      String dateStr = output['output_date'] ?? '';
      if (dateStr.length >= 10) {
        dateStr = dateStr.substring(0, 10);
      } else {
        dateStr = 'Date inconnue';
      }
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(output);
    }
    return grouped;
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
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
              onPressed: _fetchOutputs,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyBlue),
              child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }
    if (_outputs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.outbox_outlined, size: 80, color: AppColors.gold.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text('Aucune sortie enregistrée.', style: GoogleFonts.outfit(fontSize: 20, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('Cliquez sur le bouton doré pour enregistrer la première sortie.',
                style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          ],
        ),
      );
    }

    final grouped = _groupOutputsByDay();
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final date = sortedKeys[index];
        final dayOutputs = grouped[date]!;
        double dailyProfit = 0;
        int dailyItems = 0;
        for (var o in dayOutputs) {
           dailyProfit += (o['total_profit'] as num?)?.toDouble() ?? 0.0;
           dailyItems += (o['quantity'] as num?)?.toInt() ?? 0;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.navyBlue),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '$dailyItems articles vendus • Bénéfice: ${_formatCurrency(dailyProfit)}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.transparent),
                  columns: const [
                    DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Heure', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Produit', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Qté', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Prix Vente (U)', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Bénéfice', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Quartier', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: dayOutputs.map((output) {
                    final outputDateStr = output['output_date'] ?? '';
                    String formattedTime = '-';
                    if (outputDateStr.toString().isNotEmpty) {
                      try {
                        final parsedDate = DateTime.parse(outputDateStr).toLocal();
                        formattedTime = DateFormat('HH:mm').format(parsedDate);
                      } catch (e) {
                        formattedTime = '-';
                      }
                    }

                    return DataRow(cells: [
                      DataCell(Text('OUT-${output['id']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyBlue))),
                      DataCell(Text(formattedTime)),
                      DataCell(Text(output['product_name'].toString())),
                      DataCell(Text(output['client_name']?.toString() ?? '-')),
                      DataCell(Text(output['quantity'].toString())),
                      DataCell(Text(_formatCurrency(output['selling_price']))),
                      DataCell(
                        Text(_formatCurrency(output['total_profit']), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                      ),
                      DataCell(Text(output['location'].toString())),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.print_outlined, color: AppColors.navyBlue),
                          tooltip: 'Imprimer le Reçu',
                          onPressed: () => _printOutputPdf(output, date),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _printOutputPdf(dynamic output, String date) async {
    try {
      final pdf = pw.Document();
      
      final qty = (output['quantity'] as num?)?.toInt() ?? 0;
      final price = (output['selling_price'] as num?)?.toDouble() ?? 0.0;
      final total = qty * price;

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
                  pw.Text('Reçu de Sortie / Facture', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 14, color: PdfColor.fromInt(0xff6C757D))),
                  pw.Text('Référence: OUT-${output['id']}', style: const pw.TextStyle(fontSize: 14, color: PdfColor.fromInt(0xff6C757D))),
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
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Client:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.Text(output['client_name']?.toString() ?? 'Non renseigné', style: const pw.TextStyle(fontSize: 14)),
                          ]
                        ),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Destination / Quartier:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.Text(output['location']?.toString() ?? 'Non renseigné', style: const pw.TextStyle(fontSize: 14)),
                          ]
                        ),
                        pw.SizedBox(height: 20),
                        pw.Divider(color: const PdfColor.fromInt(0xffD0D5DD)),
                        pw.SizedBox(height: 20),

                        pw.Text('Détails de l\'article:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 10),
                        pw.Text(output['product_name'].toString(), style: const pw.TextStyle(fontSize: 16)),
                        pw.SizedBox(height: 10),
                        
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Quantité:', style: const pw.TextStyle(fontSize: 14)),
                            pw.Text('$qty Unité(s)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          ]
                        ),
                        pw.SizedBox(height: 10),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Prix Unitaire:', style: const pw.TextStyle(fontSize: 14)),
                            pw.Text('${price.toStringAsFixed(0)} GNF', style: const pw.TextStyle(fontSize: 14)),
                          ]
                        ),
                        pw.SizedBox(height: 20),
                        pw.Divider(color: const PdfColor.fromInt(0xffD0D5DD)),
                        pw.SizedBox(height: 20),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total à Payer:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                            pw.Text('${total.toStringAsFixed(0)} GNF', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xff1B2B48))),
                          ]
                        ),
                      ]
                    )
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text('Merci pour votre confiance !', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xff28A745))),
                  pw.SizedBox(height: 10),
                  pw.Text('Généré par Nova Genix Digital ERP', style: const pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xff6C757D))),
                ],
              ),
            );
          },
        ),
      );
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Facture_OUT_${output['id']}',
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

// ─────────────────────────────────────────────────────────────
// DIALOG — FORMULAIRE DE NOUVELLE SORTIE
// ─────────────────────────────────────────────────────────────
class NewOutputDialog extends StatefulWidget {
  const NewOutputDialog({super.key});

  @override
  State<NewOutputDialog> createState() => _NewOutputDialogState();
}

class _NewOutputDialogState extends State<NewOutputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  List<dynamic> _products = [];
  dynamic _selectedProduct;
  bool _isLoadingProducts = true;
  bool _isSubmitting = false;
  String _submitError = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _quantityCtrl.addListener(_updateCalculations);
    _priceCtrl.addListener(_updateCalculations);
  }

  void _updateCalculations() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _customerCtrl.dispose();
    _quantityCtrl.removeListener(_updateCalculations);
    _priceCtrl.removeListener(_updateCalculations);
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/products'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Gère les deux formats possibles
        final List<dynamic> list = decoded is List ? decoded : (decoded['data'] ?? []);
        final stockedProducts = list.where((p) => (p['stock_quantity'] ?? 0) > 0).toList();
        setState(() { _products = stockedProducts; _isLoadingProducts = false; });
      } else {
        setState(() { _isLoadingProducts = false; });
      }
    } catch (e) {
      setState(() { _isLoadingProducts = false; });
    }
  }

  Future<void> _submitOutput() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      setState(() { _submitError = 'Veuillez sélectionner un produit.'; });
      return;
    }

    setState(() { _isSubmitting = true; _submitError = ''; });

    try {
      final body = json.encode({
        'clientName': _customerCtrl.text.trim(),
        'productId': _selectedProduct['id'],
        'quantity': int.parse(_quantityCtrl.text.trim()),
        'sellingPrice': double.parse(_priceCtrl.text.trim()),
        'location': _locationCtrl.text.trim(),
      });

      final response = await http.post(
        Uri.parse('http://localhost:3000/api/stock_outputs'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final decoded = json.decode(response.body);

      if (response.statusCode == 201 && decoded['success'] == true) {
        if (mounted) Navigator.of(context).pop(true); // Retour avec succès
      } else {
        setState(() {
          _submitError = decoded['message'] ?? 'Erreur lors de l\'enregistrement.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _submitError = 'Impossible de joindre le serveur local.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
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
                  const Icon(Icons.outbox_outlined, color: AppColors.gold, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nouvelle Sortie de Stock', style: GoogleFonts.outfit(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Le stock, la caisse et le bénéfice se mettront à jour automatiquement.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop(false)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Champ : Sélection Produit
                      _isLoadingProducts
                          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                          : DropdownButtonFormField<dynamic>(
                              decoration: _inputDecoration('Sélectionnez un produit...', Icons.inventory_2_outlined).copyWith(labelText: 'Produit'),
                              items: _products.map((p) {
                                final name = p['name']?.toString() ?? '';
                                final isCasque = name.toLowerCase().contains('casque');
                                final label = isCasque ? name : '$name${p['color'] != null ? " - ${p['color']}" : ""}';
                                return DropdownMenuItem(value: p, child: Text(label));
                              }).toList(),
                              onChanged: (val) {
                                setState(() { _selectedProduct = val; });
                                if (val != null && val['selling_price'] != null) {
                                  _priceCtrl.text = val['selling_price'].toString();
                                }
                              },
                              validator: (val) => val == null ? 'Champ requis' : null,
                            ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: _inputDecoration('Ex: 3', Icons.numbers).copyWith(labelText: 'Quantité'),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Requis';
                                if (int.tryParse(val) == null || int.parse(val) <= 0) return 'Valeur invalide';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              decoration: _inputDecoration('Ex: 150000', Icons.attach_money).copyWith(labelText: 'Prix de Vente (GNF)'),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Requis';
                                if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Valeur invalide';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationCtrl,
                        decoration: _inputDecoration('Ex: Kipé, Dixinn, Kaloum...', Icons.location_on_outlined).copyWith(labelText: 'Quartier / Destination'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customerCtrl,
                        decoration: _inputDecoration('Ex: Ousmane Barry', Icons.person_outline).copyWith(labelText: 'Nom de la personne qui commande'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Champ requis' : null,
                      ),
                      if (_submitError.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_submitError, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.navyBlue.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.navyBlue.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Montant Total Encaissement :', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                Text(_calculateTotalRevenue(), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Stock Restant Estimé :', style: GoogleFonts.inter(color: Colors.grey.shade700)),
                                Text(_calculateRemainingStock(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.navyBlue)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Bénéfice Écoulement (estimé) :', style: GoogleFonts.inter(color: Colors.grey.shade700)),
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, size: 14, color: AppColors.gold),
                                    const SizedBox(width: 4),
                                    Text(_calculateBatchProfit(), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
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
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    child: Text('Annuler', style: TextStyle(color: Colors.grey.shade700)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitOutput,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.navyBlue),
                    child: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.navyBlue, strokeWidth: 2))
                        : const Text('Enregistrer la Sortie', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.navyBlue, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.red.shade300)),
    );
  }

  String _calculateTotalRevenue() {
    final qty = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final total = qty * price;
    if (total == 0) return '0 GNF';
    final formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(total)} GNF';
  }

  /// Calcule le bénéfice estimé pour l'écoulement de cette commande
  /// = Montant total encaissé - Coût de revient estimé (unit_cost_real * qty)
  String _calculateBatchProfit() {
    if (_selectedProduct == null) return '— GNF';
    final qty = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    if (qty <= 0 || price <= 0) return '— GNF';

    final totalRevenue = qty * price;

    // On utilise unit_cost_real si disponible (fourni par l'API via les lots FIFO)
    final rawUnitCost = _selectedProduct['unit_cost_real'] ?? _selectedProduct['cost_price'] ?? 0;
    final double unitCost = num.tryParse(rawUnitCost.toString())?.toDouble() ?? 0.0;

    final double profit = totalRevenue - (unitCost * qty);
    final formatter = NumberFormat('#,##0', 'fr_FR');
    
    if (unitCost == 0) {
      // Coût inconnu → on montre juste le revenu brut
      return '${formatter.format(totalRevenue)} GNF (brut)';
    }
    return '${formatter.format(profit)} GNF';
  }

  String _calculateRemainingStock() {
    if (_selectedProduct == null) return '-';
    final rawStock = _selectedProduct['current_stock'] ?? _selectedProduct['quantity'] ?? _selectedProduct['stock_quantity'] ?? 0;
    final int currentStock = num.tryParse(rawStock.toString())?.toInt() ?? 0;
    final qtyToOut = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    final remaining = currentStock - qtyToOut;
    
    if (remaining < 0) return 'Stock Insuffisant ($remaining)';
    return '$remaining unité(s)';
  }
}
