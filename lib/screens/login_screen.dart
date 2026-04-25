import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({Key? key, required this.onLogin}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      widget.onLogin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/app_logo.png',
                height: 120,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.directions_car, size: 100, color: Color(0xFF2D2D2D)),
              ),
              const Text(
                "SMARTSLOT",
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.w900, 
                  color: Color(0xFF3F3D56),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              
              _buildTextField(
                label: "EMAIL ADDRESS", 
                obscureText: false,
                controller: _emailController,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: "PASSWORD", 
                obscureText: true,
                controller: _passwordController,
              ),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text("Forgot Password?", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F3D56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF3F3D56).withOpacity(0.5),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 25, 
                        width: 25, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: const Text(
                  "CREATE NEW ACCOUNT",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label, 
    required bool obscureText,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFFF),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        ),
      ),
    );
  }
}
