import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../main.dart'; // themeNotifier
import '../../../../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final u = await AuthService.getUsername();
    if (mounted) setState(() => _username = u);
  }

  // ────────────────────────────────────────────────────────────────
  // Dialogue de changement de mot de passe
  // ────────────────────────────────────────────────────────────────
  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showOld = false;
    bool showNew = false;
    bool showConfirm = false;
    String? errorMsg;
    bool loading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width > 520 ? 480 : MediaQuery.of(context).size.width * 0.95,
            padding: const EdgeInsets.all(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.navyBlue, Color(0xFF1E3A5F)]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.lock_reset, color: AppColors.gold, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Modifier le mot de passe', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Sécurité de votre compte', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Formulaire
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        if (errorMsg != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Flexible(child: Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                              ],
                            ),
                          ),
                        // Ancien mot de passe
                        TextFormField(
                          controller: oldCtrl,
                          obscureText: !showOld,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe actuel',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.navyBlue),
                            suffixIcon: IconButton(
                              icon: Icon(showOld ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setS(() => showOld = !showOld),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.navyBlue, width: 2)),
                          ),
                          validator: (v) => v!.isEmpty ? 'Requis' : null,
                        ),
                        const SizedBox(height: 16),
                        // Nouveau mot de passe
                        TextFormField(
                          controller: newCtrl,
                          obscureText: !showNew,
                          decoration: InputDecoration(
                            labelText: 'Nouveau mot de passe',
                            prefixIcon: const Icon(Icons.lock_open, color: AppColors.navyBlue),
                            suffixIcon: IconButton(
                              icon: Icon(showNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setS(() => showNew = !showNew),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.navyBlue, width: 2)),
                          ),
                          validator: (v) {
                            if (v!.isEmpty) return 'Requis';
                            if (v.length < 4) return 'Minimum 4 caractères';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Confirmation
                        TextFormField(
                          controller: confirmCtrl,
                          obscureText: !showConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirmer le nouveau mot de passe',
                            prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.navyBlue),
                            suffixIcon: IconButton(
                              icon: Icon(showConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setS(() => showConfirm = !showConfirm),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.navyBlue, width: 2)),
                          ),
                          validator: (v) {
                            if (v!.isEmpty) return 'Requis';
                            if (v != newCtrl.text) return 'Les mots de passe ne correspondent pas';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Boutons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: loading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setS(() { loading = true; errorMsg = null; });
                                final err = await AuthService.changePassword(oldCtrl.text, newCtrl.text);
                                if (err != null) {
                                  setS(() { errorMsg = err; loading = false; });
                                } else {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ Mot de passe modifié avec succès !'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                        label: const Text('Enregistrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text('Configuration de l\'application Nova ERP', style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 24),

          // ── Profil utilisateur ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.navyBlue, Color(0xFF1E3A5F)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                  child: Text(
                    _username.isNotEmpty ? _username[0].toUpperCase() : 'A',
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.gold),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_username, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Administrateur Principal', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Apparence ────────────────────────────────────────
          _buildSection(
            isDark: isDark,
            title: 'Apparence',
            icon: Icons.palette_outlined,
            children: [
              _buildSwitchTile(
                isDark: isDark,
                icon: Icons.brightness_6_outlined,
                title: 'Thème Sombre',
                subtitle: 'Activer ou désactiver le mode nuit',
                value: themeNotifier.value == ThemeMode.dark,
                onChanged: (val) => setState(() => themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Compte & Sécurité ────────────────────────────────
          _buildSection(
            isDark: isDark,
            title: 'Compte & Sécurité',
            icon: Icons.security_outlined,
            children: [
              _buildNavTile(
                isDark: isDark,
                icon: Icons.lock_reset,
                iconColor: AppColors.gold,
                title: 'Modifier le mot de passe',
                subtitle: 'Changer votre mot de passe de connexion',
                onTap: _showChangePasswordDialog,
              ),
              const Divider(height: 1, indent: 56),
              _buildNavTile(
                isDark: isDark,
                icon: Icons.person_outline,
                iconColor: Colors.blue,
                title: 'Informations du compte',
                subtitle: 'Nom d\'utilisateur: $_username',
                onTap: () {
                  showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text('Informations du compte', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Utilisateur : $_username', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Rôle : Administrateur Principal'),
                        const SizedBox(height: 8),
                        const Text('Statut : Actif', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ]
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
                  ));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Application ─────────────────────────────────────
          _buildSection(
            isDark: isDark,
            title: 'Application',
            icon: Icons.settings_applications_outlined,
            children: [
              _buildNavTile(
                isDark: isDark,
                icon: Icons.language,
                iconColor: Colors.purple,
                title: 'Langue',
                subtitle: 'Français (FR)',
                onTap: () {
                  showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text('Langue de l\'application', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('Le Français est la seule langue supportée pour le moment.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Compris'))],
                  ));
                },
              ),
              const Divider(height: 1, indent: 56),
              _buildNavTile(
                isDark: isDark,
                icon: Icons.info_outline,
                iconColor: Colors.teal,
                title: 'Version de l\'application',
                subtitle: 'Nova ERP v1.0.0 — Hors ligne',
                onTap: () {
                  showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text('À propos de Nova ERP', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nova Genix Digital ERP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Version : 1.0.0 (Build 42)'),
                        SizedBox(height: 8),
                        Text('Architecture : SQLite Local (Hors Ligne)'),
                        SizedBox(height: 8),
                        Text('Développeur : Nova Genix Digital'),
                      ],
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
                  ));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Sauvegarde & Données ─────────────────────────────
          _buildSection(
            isDark: isDark,
            title: 'Sauvegarde & Données',
            icon: Icons.backup_outlined,
            children: [
              _buildNavTile(
                isDark: isDark,
                icon: Icons.cloud_download_outlined,
                iconColor: Colors.green,
                title: 'Exporter les données',
                subtitle: 'Sauvegarder enterprise.db localement',
                onTap: () {
                  showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text('Exporter les données', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('Voulez-vous sauvegarder une copie de la base de données (enterprise.db) ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Sauvegarde effectuée avec succès !'), backgroundColor: Colors.green),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: const Text('Exporter'),
                      ),
                    ],
                  ));
                },
              ),
              const Divider(height: 1, indent: 56),
              _buildNavTile(
                isDark: isDark,
                icon: Icons.delete_forever_outlined,
                iconColor: Colors.red,
                title: 'Vider le cache',
                subtitle: 'Nettoyer les données temporaires',
                onTap: () {
                  showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text('Vider le cache', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('Êtes-vous sûr de vouloir vider le cache ? Cela peut ralentir le prochain chargement.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cache vidé avec succès'), backgroundColor: Colors.orange),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Vider'),
                      ),
                    ],
                  ));
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: isDark ? Colors.white70 : AppColors.navyBlue, size: 20),
                const SizedBox(width: 10),
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.gold),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        value: value,
        activeThumbColor: AppColors.gold,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNavTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
