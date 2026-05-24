import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../../core/theme/app_colors.dart';

class ChinaPurchasesPage extends StatefulWidget {
  const ChinaPurchasesPage({super.key});

  @override
  State<ChinaPurchasesPage> createState() => _ChinaPurchasesPageState();
}

class _ChinaPurchasesPageState extends State<ChinaPurchasesPage> {
  List<dynamic> _purchases = [];
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final resPurchases = await http.get(Uri.parse('http://localhost:3000/api/china-purchases'));
      final resProducts = await http.get(Uri.parse('http://localhost:3000/api/products'));
      if (resPurchases.statusCode == 200 && resProducts.statusCode == 200) {
        setState(() {
          _purchases = json.decode(resPurchases.body)['data'];
          _products = json.decode(resProducts.body)['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPurchase(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/china-purchases'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      
      final resData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300 && resData['success'] == true) {
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande créée avec succès !'), backgroundColor: Colors.green));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(resData['message'] ?? 'Erreur lors de la création de la commande.'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur de connexion: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _markAsReceived(String id) async {
    try {
      await http.put(
        Uri.parse('http://localhost:3000/api/china-purchases/$id/receive'),
        headers: {'Content-Type': 'application/json'},
      );
      _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reçu avec succès !'), backgroundColor: Colors.green));
      }
    } catch (e) {
      // Error
    }
  }

  Future<void> _showReportDialog(String id) async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/china-purchases/$id/report'));
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success']) {
        final report = data['data']['report'];
        final batch = data['data']['batch'];
        
        final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Bilan du Lot #${batch['id']} - ${batch['product_name']}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('État: ${report['isDepleted'] ? 'Écoulé 🔴' : 'En cours 🟢'}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Text('Quantité Commandée: ${batch['quantity_received']}'),
                  Text('Quantité Vendue: ${report['quantitySold']}'),
                  Text('Quantité Restante: ${batch['quantity_remaining']}'),
                  const Divider(height: 32),
                  Text('Total Dépensé (Achat + Transport): ${formatCurrency.format(report['totalSpent'])}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  Text('Total Gagné (Ventes): ${formatCurrency.format(report['totalEarned'])}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(
                    '${report['profitOrLoss'] >= 0 ? 'Bénéfice' : 'Perte'}: ${formatCurrency.format(report['profitOrLoss'])}',
                    style: TextStyle(
                      color: report['profitOrLoss'] >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))
              ],
            ),
          );
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors du chargement du bilan'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de connexion: $e'), backgroundColor: Colors.red));
    }
  }

  void _showAddPurchaseDialog() {
    final formKey = GlobalKey<FormState>();
    String productName = '';
    String supplier = '';
    int quantity = 0;
    double unitCost = 0;
    double transportCost = 0;
    DateTime orderDate = DateTime.now();
    TextEditingController dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(orderDate));

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

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                    const Icon(Icons.flight_takeoff_rounded, color: AppColors.gold, size: 28),
                    const SizedBox(width: 16),
                    Expanded(child: Text('Nouvelle Commande', style: GoogleFonts.outfit(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<String>.empty();
                            }
                            final uniqueNames = _products.map((p) => p['name'].toString()).toSet().toList();
                            return uniqueNames.where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (String selection) {
                            productName = selection;
                          },
                          fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                            return TextFormField(
                              controller: fieldTextEditingController,
                              focusNode: fieldFocusNode,
                              decoration: buildInputDecoration('Nom du Produit (existant ou nouveau)', Icons.inventory_2_outlined),
                              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                              onSaved: (v) {
                                if (v != null && v.isNotEmpty) {
                                  productName = v;
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: buildInputDecoration('Fournisseur (ex: Alibaba)', Icons.business_outlined),
                          validator: (v) => v!.isEmpty ? 'Requis' : null,
                          onSaved: (v) => supplier = v!,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: TextFormField(decoration: buildInputDecoration('Quantité', Icons.numbers), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requis' : null, onSaved: (v) => quantity = int.parse(v!))),
                            const SizedBox(width: 16),
                            Expanded(child: TextFormField(decoration: buildInputDecoration('Coût Unitaire (GNF)', Icons.payments), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Requis' : null, onSaved: (v) => unitCost = double.parse(v!))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: buildInputDecoration('Frais de Transitaire (GNF)', Icons.local_shipping_outlined),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => transportCost = v!.isEmpty ? 0 : double.parse(v),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: dateController,
                          readOnly: true,
                          decoration: buildInputDecoration('Date de Commande', Icons.calendar_today),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: orderDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null && picked != orderDate) {
                              orderDate = picked;
                              dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                            }
                          },
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
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          _createPurchase({
                            'productName': productName,
                            'supplier': supplier,
                            'quantity': quantity,
                            'unitCost': unitCost,
                            'transportCost': transportCost,
                            'orderDate': orderDate.toIso8601String()
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.navyBlue),
                      child: const Text('Confirmer la Commande', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Achats Chine', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
              ElevatedButton.icon(
                onPressed: _showAddPurchaseDialog,
                icon: const Icon(Icons.flight_takeoff, color: Colors.white),
                label: const Text('Lancer une commande', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: _purchases.isEmpty
                  ? Center(child: Text('Aucune commande', style: TextStyle(color: Colors.grey.shade500)))
                  : ListView(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Produit')),
                              DataColumn(label: Text('Fournisseur')),
                              DataColumn(label: Text('Qté')),
                              DataColumn(label: Text('Date Commande')),
                              DataColumn(label: Text('Réception')),
                              DataColumn(label: Text('Transit')),
                              DataColumn(label: Text('Statut')),
                              DataColumn(label: Text('Actions')),
                            ],
                          rows: _purchases.map((p) {
                            final isReceived = p['status'] == 'Reçu';
                            final orderDateStr = p['order_date'];
                            final orderDate = orderDateStr != null ? DateTime.tryParse(orderDateStr.toString()) : null;
                            final receptionDateStr = p['reception_date'];
                            final receptionDate = receptionDateStr != null ? DateTime.tryParse(receptionDateStr.toString()) : null;
                            
                            int transitDays = 0;
                            if (orderDate != null) {
                              if (receptionDate != null && isReceived) {
                                transitDays = receptionDate.difference(orderDate).inDays;
                              } else {
                                transitDays = DateTime.now().difference(orderDate).inDays;
                              }
                            }

                            return DataRow(cells: [
                              DataCell(Text(p['product_name']?.toString() ?? 'Inconnu', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(p['supplier_name']?.toString() ?? '-')),
                              DataCell(Text(p['quantity_received']?.toString() ?? '0')),
                              DataCell(Text(orderDate != null ? DateFormat('dd/MM/yyyy').format(orderDate) : '-')),
                              DataCell(Text(receptionDate != null ? DateFormat('dd/MM/yyyy').format(receptionDate) : '-')),
                              DataCell(Text(orderDate != null ? '$transitDays jours' : '-')),
                              DataCell(Text(p['status']?.toString() ?? 'Inconnu', style: TextStyle(color: isReceived ? Colors.green : Colors.orange, fontWeight: FontWeight.bold))),
                              DataCell(
                                Row(
                                  children: [
                                    isReceived
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : IconButton(icon: const Icon(Icons.inventory, color: AppColors.navyBlue), onPressed: () => _markAsReceived(p['id'].toString())),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.bar_chart, color: AppColors.gold),
                                      tooltip: 'Voir le bilan',
                                      onPressed: () => _showReportDialog(p['id'].toString()),
                                    ),
                                  ],
                                ),
                              ),
                            ]);
                          }).toList(),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
