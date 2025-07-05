import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/navigation/AppRoutes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  /// ✅ Check if already logged in and redirect
  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedKYC = prefs.getBool('hasCompletedKYC') ?? false;
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null && session.user != null) {
      if (hasCompletedKYC) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.kyc);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please fill in all fields.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final prefs = await SharedPreferences.getInstance();
        final hasCompletedKYC = prefs.getBool('hasCompletedKYC') ?? false;

        if (hasCompletedKYC) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.kyc);
        }
      } else {
        _showMessage("Login failed: Unknown error");
      }
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage("Unexpected error: $error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
      // After returning from OAuth, _checkExistingSession() logic will re-check
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage("Unexpected error: $error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  BoxDecoration _inputShadow() {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.deepPurple.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JourneyCraft',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome Back ✈️',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to continue your journey',
                  style: GoogleFonts.poppins(color: Colors.black54),
                ),
                const SizedBox(height: 48),
                Container(
                  decoration: _inputShadow(),
                  child: TextField(
                    controller: _emailController,
                    decoration: _inputDecoration('Email', Icons.email_rounded),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  decoration: _inputShadow(),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(
                      'Password',
                      Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.deepPurple,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF651FFF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Center(
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    'or continue with',
                    style: GoogleFonts.poppins(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _signInWithGoogle,
                    child: Image.asset(
                      'lib/assets/google_logo.png',
                      height: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account?',
                        style: GoogleFonts.poppins(),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.register,
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(color: Colors.deepPurple),
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
}
