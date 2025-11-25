import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomePage.dart';
import 'network/api_service.dart';
import 'signup_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}


class _LoginPageState extends State<LoginPage> {
  final TextEditingController _mobileController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _login(String mobileNo) async {
    setState(() => _isLoading = true);
    try {
      final loginResponse = await _apiService.login(mobileNo);
      final status = loginResponse.statusCode;
      final message = loginResponse.message;

      if(status == '200' && loginResponse.empLogin != null) {
        await _saveUserData(loginResponse.empLogin!);
        if (!mounted) return;
        _navigateToHomePage();
      } else {
        _showMessage(message.isNotEmpty ? message : "Invalid login data");
      }
    } catch (e) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> loginData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userid', loginData['Id']?.toString().trim() ?? '');
    await prefs.setString('name', loginData['EmpName']?.toString().trim() ?? '');
    await prefs.setString('empCode', loginData['EmpCode']?.toString().trim() ?? '');
    await prefs.setString('companyID', loginData['CompanyID']?.toString().trim() ?? '');
    await prefs.setString('status', loginData['Status']?.toString().trim() ?? '');
    await prefs.setString('usertype', 'Employee');
    await prefs.setBool('userlogin', true);
  }

  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Login Info"),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
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
                  horizontal: mq.width * 0.08,
                  vertical: mq.height * 0.04,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Image.asset('assets/images/logo.jpg', width: mq.width * 0.3),
                    SizedBox(height: mq.height * 0.03),
                    Text(
                      'Welcome!',
                      style: GoogleFonts.poppins(
                        fontSize: mq.width * 0.07,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D2C60),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please enter your mobile number to continue.',
                      style: GoogleFonts.poppins(
                        fontSize: mq.width * 0.04,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: mq.height * 0.04),
                    TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF2D2C60)),
                      ),
                    ),
                    SizedBox(height: mq.height * 0.03),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                          final mobile = _mobileController.text.trim();
                          if (mobile.isEmpty) {
                            _showMessage('Please enter your mobile number');
                          } else if (mobile.length != 10) {
                            _showMessage('Please enter a valid 10-digit mobile number');
                          } else {
                            _login(mobile);
                          }
                        },
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
                            : Text('Login', style: GoogleFonts.poppins(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF2D2C60),
                            fontWeight: FontWeight.w400,
                          ),
                          children: [
                            TextSpan(
                              text: "Go Sign Up",
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
    );
  }

}
