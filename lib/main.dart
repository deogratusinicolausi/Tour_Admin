import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:turiva_admin/screens/test_upload_screen.dart';
import 'firebase_options.dart';
import 'screens/admin_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TurivaAdminApp());
}

class TurivaAdminApp extends StatelessWidget {
  const TurivaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Turiva Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AdminLoginScreen(),    );
  }
}