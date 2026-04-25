import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isRequesting = false;

  void _handleRequest() async {
    if (_emailController.text.isEmpty) return;
    
    setState(() => _isRequesting = true);
    try {
      await AuthService().requestPasswordReset(_emailController.text.trim());
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Request Sent"),
            content: const Text("Your password reset request has been sent to the Manager for approval. You will receive an email once approved."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
            ],
          ),
        ).then((_) => Navigator.pop(context));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password"), backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            const Icon(Icons.lock_reset, size: 80, color: Color(0xFF3F3D56)),
            const SizedBox(height: 20),
            const Text(
              "Security Protocol",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Enter your email to request a password reset. For security, a Manager must approve this request before you can change your password.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "EMAIL ADDRESS",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isRequesting ? null : _handleRequest,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F3D56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: _isRequesting ? const CircularProgressIndicator(color: Colors.white) : const Text("REQUEST RESET"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
