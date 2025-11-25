import 'package:dd_hrms/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'network/api_service.dart';
import 'Model/SignupResponse.dart'; // ✅ Import your correct model

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  /// 🔹 Signup Function
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final mobile = _mobileController.text.trim();
      final email = _emailController.text.trim();

      // 🔸 Call signup API
      final response = await _apiService.signUp(name, mobile, email);

      // ✅ Convert raw JSON into model
      final signupResponse = SignupResponse.fromJson(response);

      if (signupResponse.statusCode == '200' &&
          signupResponse.status.toLowerCase() == 'success') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              signupResponse.message,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // ✅ Optionally show user info (from EmpLogin)
        final emp = signupResponse.empLogin;
        debugPrint("✅ Signup Successful for: ${emp?.empName} | ID: ${emp?.id}");

        Navigator.pop(context); // Go back to login
      } else {
        _showMessage(signupResponse.message);
      }
    } catch (e) {
      _showMessage("Something went wrong. Please try again.");
      debugPrint("❌ Signup Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade100, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: mq.width * 0.08, vertical: mq.height * 0.04),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo.jpg',
                          width: mq.width * 0.3),
                      SizedBox(height: mq.height * 0.03),
                      Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: mq.width * 0.07,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D2C60),
                        ),
                      ),
                      const SizedBox(height: 25),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon:
                          const Icon(Icons.person, color: Color(0xFF2D2C60)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          prefixIcon:
                          const Icon(Icons.phone, color: Color(0xFF2D2C60)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter mobile number';
                          if (value.length != 10)
                            return 'Enter valid 10-digit number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email ID',
                          prefixIcon:
                          const Icon(Icons.email, color: Color(0xFF2D2C60)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return 'Please enter email ID';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: mq.height * 0.04),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D2C60),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Text('Sign Up',
                              style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF2D2C60),
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: "Login",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF2D2C60),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
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
    );
  }

}