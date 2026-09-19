import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/app_theme_provider.dart';
import 'screens/admin_login_screen.dart';
import 'features/gesture_control/gesture_control_screen.dart';
import 'utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDDKlIwhqR51p9Vb0tnwlbWJnpgV0MUcXk",
      appId: "1:749360118137:android:cb2a144e34389a062497a8",
      messagingSenderId: "749360118137",
      projectId: "turiva",
      authDomain: "turiva.firebaseapp.com",
      storageBucket: "turiva.firebasestorage.app",
    ),
  );
  runApp(const TurivaAdminApp());
}

class TurivaAdminApp extends StatelessWidget {
  const TurivaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppThemeProvider()..loadSettings(),
      child: Consumer<AppThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TURIVA ADMIN',
            themeMode: themeProvider.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            routes: {
              '/gesture-control': (context) => const GestureControlScreen(),
            },
            home: const AdminLoginScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accentGold,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.accentGold,
        secondary: AppColors.accentGold,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E1E1E)),
      useMaterial3: true,
    );
  }
}