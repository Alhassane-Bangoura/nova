import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/widgets/erp_sidebar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../main.dart'; // For themeNotifier
import '../../../../features/china_purchases/presentation/pages/china_purchases_page.dart';
import '../../../products/presentation/pages/products_page.dart';
import '../../../stock_outputs/presentation/pages/stock_outputs_page.dart';
import '../../../accounting/presentation/pages/accounting_page.dart';
import 'dashboard_view.dart';
import '../../../sanctions/presentation/pages/sanctions_page.dart';
import '../../../analytics/presentation/pages/analytics_page.dart';
import '../../../audit/presentation/pages/audit_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String _userName = 'Utilisateur';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('admin_username');
    if (username != null && username.isNotEmpty) {
      setState(() {
        _userName = username;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          ErpSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
          Expanded(
            child: Column(
              children: [
                // ── Top Bar ──────────────────────────────────────────
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.navyBlue : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Titre de page supprimé pour donner toute la place au texte défilant
                      // Marquee for Company Name
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.navyBlue, // Fond bleu marine pour faire ressortir le texte
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navyBlue.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const ClipRect(
                            child: _MarqueeText(
                              text: "NOVA GENIX DIGITAL - INNOVER. CONNECTER. PROPULSER.  ★★★  ",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gold, // Texte en or (gold) pour un contraste magnifique
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: Icon(
                          themeNotifier.value == ThemeMode.light 
                            ? Icons.dark_mode 
                            : Icons.light_mode, 
                          color: isDark ? Colors.white : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            themeNotifier.value = themeNotifier.value == ThemeMode.light 
                                ? ThemeMode.dark 
                                : ThemeMode.light;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.notifications_none, color: Colors.grey),
                      const SizedBox(width: 24),
                      CircleAvatar(
                        backgroundColor: AppColors.navyBlue.withValues(alpha: 0.1),
                        child: Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: AppColors.navyBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Zone de travail principale ────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildPageContent(_selectedIndex),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(int index) {
    const titles = {
      0: 'Tableau de Bord',
      1: 'Produits',
      2: 'Stock',
      3: 'Sorties Produits',
      4: 'Achats Chine',
      5: 'Dépenses',
      6: 'Finances & Caisse',
      7: 'Sanctions',
      8: 'Rapports & Analytics',
      9: 'Audit & Historique',
      10: 'Paramètres',
    };
    return titles[index] ?? 'NOVA ERP';
  }

  Widget _buildPageContent(int index) {
    // Modules câblés : chaque case retourne sa vraie page
    switch (index) {
      case 0:
        return const DashboardView();
      case 2:
        // ✅ MODULE STOCK & PRODUITS (Inventaire en temps réel)
        return const ProductsPage();
      case 3:
        // ✅ MODULE SORTIES PRODUITS
        return const StockOutputsPage();
      case 4:
        // ✅ MODULE ACHATS CHINE
        return const ChinaPurchasesPage();
      case 5:
      case 6:
        // ✅ FINANCIAL CONTROL CENTER (Dépenses, Caisse, Profits)
        return const AccountingPage();
      case 7:
        // ✅ MODULE SANCTIONS ÉQUIPE
        return const SanctionsPage();
      case 8:
        // ✅ MODULE RAPPORTS & ANALYTICS
        return const AnalyticsPage();
      case 9:
        // ✅ MODULE AUDIT & HISTORIQUE
        return const AuditPage();
      case 10:
        // ✅ PARAMÈTRES
        return const SettingsPage();

      default:
        // Placeholder pour les modules encore en construction
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction,
                    size: 80, color: AppColors.gold.withValues(alpha: 0.3)),
                const SizedBox(height: 24),
                Text(
                  'Module "${_getPageTitle(index)}" en construction',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prochain sprint de développement...',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  late ScrollController _scrollController;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isScrolling = true;
        _scroll();
      }
    });
  }

  Future<void> _scroll() async {
    while (_isScrolling && mounted) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          // Calculate duration based on distance to keep constant speed (e.g. 50 pixels per sec)
          final durationMs = (maxScroll * 20).toInt(); 
          if (durationMs > 0) {
            await _scrollController.animateTo(
              maxScroll,
              duration: Duration(milliseconds: durationMs),
              curve: Curves.linear,
            );
          } else {
            await Future.delayed(const Duration(milliseconds: 500));
          }
          if (!mounted) break;
          // Instantly jump back to start
          _scrollController.jumpTo(0.0);
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  @override
  void dispose() {
    _isScrolling = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 50.0),
            child: Text(widget.text, style: widget.style),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 50.0),
            child: Text(widget.text, style: widget.style),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 50.0),
            child: Text(widget.text, style: widget.style),
          ),
        ],
      ),
    );
  }
}


