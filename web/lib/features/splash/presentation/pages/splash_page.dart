import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../auth/presentation/pages/auth_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    // Artificial delay for splash screen branding
    await Future.delayed(const Duration(seconds: 2));
    
    // Check if an admin account exists
    final bool hasAdmin = await AuthService.hasAdminAccount();
    
    if (!mounted) return;

    // Navigate to AuthScreen, passing whether it's a registration or login
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AuthScreen(isFirstTimeRegistration: !hasAdmin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14213D), // Navy Blue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            ClipOval(
              child: Image.asset(
                'assets/logo.png',
                width: 180,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'NOVA GENIX',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'DIGITAL',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Color(0xFFFCA311), // Gold
            ),
          ],
        ),
      ),
    );
  }
}
