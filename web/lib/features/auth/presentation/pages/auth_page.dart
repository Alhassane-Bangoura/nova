import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/auth_service.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';

class AuthScreen extends StatefulWidget {
  final bool isFirstTimeRegistration;

  const AuthScreen({super.key, required this.isFirstTimeRegistration});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isRegistering;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _isRegistering = widget.isFirstTimeRegistration;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = '';
      });

      if (_isRegistering) {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = 'Les mots de passe ne correspondent pas.';
          });
          return;
        }

        await AuthService.registerAdmin(
          _usernameController.text,
          _passwordController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte administrateur créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _isRegistering = false;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        final bool success = await AuthService.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (success) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        } else {
          setState(() {
            _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect.';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRegistering) {
      return _buildRegistrationLayout();
    } else {
      return _buildLoginLayout();
    }
  }

  // ==========================================
  // REGISTRATION LAYOUT (Style Image 1 - Bleu et Blanc)
  // ==========================================
  Widget _buildRegistrationLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                Expanded(child: _buildRegistrationLeftPanel()),
                Expanded(child: Center(child: _buildRegistrationForm(isDesktop: true))),
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 350, width: double.infinity, child: _buildRegistrationLeftPanel()),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildRegistrationForm(isDesktop: false),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildRegistrationLeftPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF14213D), Color(0xFF000000)], // Navy Blue to Black
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Cercle supérieur gauche avec logo
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Opacity(
                  opacity: 0.1, // Opacité très faible pour l'effet filigrane
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Cercle inférieur droit avec logo
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Opacity(
                  opacity: 0.1, // Opacité très faible pour l'effet filigrane
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo principal en cercle
                ClipOval(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 280,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'BIENVENUE',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                // Les textes "NOVA GENIX DIGITAL" et le slogan ont été retirés ici 
                // car ils sont déjà inclus magnifiquement dans votre image de logo !
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm({required bool isDesktop}) {
    return Container(
      width: isDesktop ? 450 : double.infinity,
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inscription',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF14213D), // Navy Blue
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez créer votre compte administrateur',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 40),
            _buildRegTextField(
              controller: _usernameController,
              label: 'Nom d\'utilisateur',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildRegTextField(
              controller: _passwordController,
              label: 'Mot de passe',
              icon: Icons.lock,
              isPassword: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requis';
                final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$');
                if (!regex.hasMatch(value)) {
                  return 'Min 6 car., maj, min, chiffre, et spécial.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildRegTextField(
              controller: _confirmPasswordController,
              label: 'Confirmer le mot de passe',
              icon: Icons.lock,
              isPassword: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requis';
                return null;
              },
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14213D), // Navy Blue
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Bouton légèrement arrondi comme image 1
                  ),
                ),
                child: Text(
                  'S\'inscrire',
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[700]),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFFFCA311), // Gold
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFE5E5E5), // Light Gray
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator ?? (value) => value!.isEmpty ? 'Requis' : null,
    );
  }

  // ==========================================
  // LOGIN LAYOUT (Style Senior - Fond Image avec Cadre Arrondi)
  // ==========================================
  Widget _buildLoginLayout() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/logo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            // Une couche sombre supplémentaire pour assurer la lisibilité
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 450,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14213D).withValues(alpha: 0.85), // Navy Blue avec opacité
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CONNEXION',
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'INNOVER. CONNECTER. PROPULSER.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFCA311), // Gold
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Username Field (Icon Left)
                      _buildCustomLoginField(
                        controller: _usernameController,
                        hint: 'Nom d\'utilisateur',
                        icon: Icons.person_outline,
                        iconOnRight: false,
                      ),
                      const SizedBox(height: 24),
                      // Password Field (Icon Right)
                      _buildCustomLoginField(
                        controller: _passwordController,
                        hint: 'Mot de passe',
                        icon: Icons.lock_outline,
                        iconOnRight: true,
                        isPassword: true,
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)),
                      ],
                      const SizedBox(height: 48),
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFCA311), // Gold Button
                            foregroundColor: const Color(0xFF000000), // Black Text
                            elevation: 5,
                            shadowColor: const Color(0xFFFCA311).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30), // Bouton très arrondi
                            ),
                          ),
                          child: Text(
                            'SE CONNECTER',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildCustomLoginField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool iconOnRight,
    bool isPassword = false,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5).withOpacity(0.1), // Light Gray semi-transparent
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          // Text Field
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(
                left: iconOnRight ? 24 : 70,
                right: iconOnRight ? 70 : 24,
              ),
              child: TextFormField(
                controller: controller,
                obscureText: isPassword && !_isPasswordVisible,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
                validator: (value) => value!.isEmpty ? 'Requis' : null,
              ),
            ),
          ),
          // Circle Icon (à gauche ou à droite selon l'image 2)
          Align(
            alignment: iconOnRight ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              // Astuce UX : Cliquer sur le cadenas affiche/masque le mot de passe
              onTap: isPassword ? () => setState(() => _isPasswordVisible = !_isPasswordVisible) : null,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    // Change l'icône si on affiche le mot de passe
                    isPassword ? (_isPasswordVisible ? Icons.lock_open : Icons.lock_outline) : icon, 
                    color: const Color(0xFF14213D), // Navy Blue
                    size: 28
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
