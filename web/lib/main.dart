import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'NOVA GENIX DIGITAL',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
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
            textTheme: GoogleFonts.interTextTheme(
              ThemeData(brightness: Brightness.light).textTheme,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFCA311), // Gold
              brightness: Brightness.dark,
              surface: const Color(0xFF14213D), // Navy Blue
            ),
            textTheme: GoogleFonts.interTextTheme(
              ThemeData(brightness: Brightness.dark).textTheme,
            ),
          ),
          home: const SplashScreen(), // Activé le flux d'authentification
        );
      },
    );
  }
}
