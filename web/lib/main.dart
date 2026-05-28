import 'package:flutter/material.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';

// Global Theme Notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NovaApp());
}

class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          title: 'NOVA GENIX DIGITAL',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
          ],
          locale: const Locale('fr', 'FR'),
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFCA311), // Gold
              brightness: Brightness.light,
            ),
            textTheme: ThemeData(brightness: Brightness.light).textTheme,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFCA311), // Gold
              brightness: Brightness.light, // Forcé en light pour éviter les problèmes d'adaptation
              surface: const Color(0xFFF1F5F9), // Background Light
            ),
            textTheme: ThemeData(brightness: Brightness.light).textTheme,
          ),
          home: const SplashScreen(), // Restore authentication flow
        );
      },
    );
  }
}
