import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import 'dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = await _auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        String? role = await _auth.getUserRole(user.uid);

        if (role == 'admin' || role == 'superAdmin') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
        } else {
          await _auth.logout();
          _showError('Access denied. Admin only.');
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      // ⭐ No white space
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.06,
                        vertical: height * 0.03,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ⭐ Space above (kama screen ni kubwa)
                          const Spacer(),

                          // ⭐ Logo
                          Container(
                            width: width * 0.25,
                            height: width * 0.25,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  AppColors.accentGold.withOpacity(0.5),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.admin_panel_settings,
                              size: width * 0.15,
                              color: AppColors.primary,
                            ),
                          ),

                          SizedBox(height: height * 0.025),

                          // ⭐ Title
                          Text(
                            'TURIVA ADMIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.08,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: height * 0.005),
                          Text(
                            'Management Portal',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: width * 0.04,
                            ),
                          ),

                          SizedBox(height: height * 0.04),

                          // ⭐ Email
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Admin Email',
                              labelStyle:
                              const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.email,
                                  color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.02),

                          // ⭐ Password
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle:
                              const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.lock,
                                  color: Colors.white70),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.04),

                          // ⭐ Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentGold,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                  color: Colors.white)
                                  : const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: height * 0.03),

                          // ⭐ Bottom text
                          Text(
                            '🔒 Authorized Personnel Only',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5)),
                          ),

                          // ⭐ Space below
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}