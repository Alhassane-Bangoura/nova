import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

class ErpSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const ErpSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.navyBlue,
      child: Column(
        children: [
          // Logo & Titre
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, color: AppColors.gold, size: 40),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'NOVA ERP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, 'Tableau de Bord'),
                // L'onglet Produits (1) a été supprimé à la demande du client
                // L'entrée se gère via "Achats Chine" et la sortie via "Ventes"
                _buildNavItem(2, Icons.warehouse_outlined, 'Stock'),
                _buildNavItem(3, Icons.outbox_outlined, 'Ventes'),
                _buildNavItem(4, Icons.flight_land, 'Commandes'),
                _buildNavItem(5, Icons.receipt_long_outlined, 'Dépenses'),

                _buildNavItem(7, Icons.gavel_outlined, 'Sanctions'),
                const Divider(color: Colors.white24, height: 32),
                _buildNavItem(8, Icons.analytics_outlined, 'Rapports & Analytics'),
                _buildNavItem(9, Icons.history_outlined, 'Audit & Historique'),
                _buildNavItem(10, Icons.settings_outlined, 'Paramètres'),
              ],
            ),
          ),
          
          // Bouton Déconnexion
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: AppColors.navyBlue),
              label: Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.gold : Colors.white70),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.gold : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => onItemSelected(index),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
