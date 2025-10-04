import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/auth_service.dart';
import 'registration_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  final String selectedLanguage;

  const LoginScreen({super.key, required this.selectedLanguage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _pin = '';
  bool _isLoading = false;
  String _errorMessage = '';

  // Language-specific text
  Map<String, Map<String, String>> _texts = {
    'hi': {
      'title': 'रुपया में लॉगिन करें',
      'subtitle': 'अपने खाते में वापस आएं',
      'phone': 'मोबाइल नंबर (10 अंक)',
      'phonePlaceholder': '9876543210',
      'pin': 'अपना 4 अंकों का PIN दर्ज करें',
      'login': 'लॉगिन करें',
      'noAccount': 'कोई खाता नहीं है?',
      'registerHere': 'यहाँ पंजीकरण करें',
      'enterPhone': 'कृपया अपना मोबाइल नंबर दर्ज करें',
      'enterPin': 'कृपया अपना PIN दर्ज करें',
      'invalidPhone': 'कृपया वैध 10 अंकों का मोबाइल नंबर दर्ज करें',
      'invalidPin': 'PIN 4 अंकों का होना चाहिए',
    },
    'mr': {
      'title': 'रुपयामध्ये लॉगिन करा',
      'subtitle': 'तुमच्या खात्यात परत या',
      'phone': 'मोबाइल नंबर (10 अंक)',
      'phonePlaceholder': '9876543210',
      'pin': 'तुमचा 4 अंकी PIN टाका',
      'login': 'लॉगिन करा',
      'noAccount': 'खाते नाही?',
      'registerHere': 'येथे नोंदणी करा',
      'enterPhone': 'कृपया तुमचा मोबाइल नंबर टाका',
      'enterPin': 'कृपया तुमचा PIN टाका',
      'invalidPhone': 'कृपया वैध 10 अंकी मोबाइल नंबर टाका',
      'invalidPin': 'PIN 4 अंकी असावा',
    },
    'en': {
      'title': 'Login to Rupaya',
      'subtitle': 'Welcome back to your account',
      'phone': 'Mobile Number (10 digits)',
      'phonePlaceholder': '9876543210',
      'pin': 'Enter your 4-digit PIN',
      'login': 'Login',
      'noAccount': 'Don\'t have an account?',
      'registerHere': 'Register here',
      'enterPhone': 'Please enter your mobile number',
      'enterPin': 'Please enter your PIN',
      'invalidPhone': 'Please enter a valid 10-digit mobile number',
      'invalidPin': 'PIN must be 4 digits',
    },
  };

  String _getText(String key) {
    return _texts[widget.selectedLanguage]?[key] ?? _texts['en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom - 48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                    // Logo/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF46ec13).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 60,
                        color: Color(0xFF46ec13),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      _getText('title'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      _getText('subtitle'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Phone Number Input
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: _getText('phone'),
                        hintText: _getText('phonePlaceholder'),
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF46ec13)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF46ec13), width: 2),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // PIN Input
                    Text(
                      _getText('pin'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    PinCodeTextField(
                      appContext: context,
                      length: 4,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      cursorColor: Colors.black,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(8),
                        fieldHeight: 60,
                        fieldWidth: 60,
                        activeColor: const Color(0xFF46ec13),
                        inactiveColor: Colors.grey.withOpacity(0.3),
                        selectedColor: const Color(0xFF46ec13),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _pin = value;
                          _errorMessage = ''; // Clear error when user types
                        });
                      },
                    ),

                    // Error message
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                const SizedBox(height: 32),

                // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF46ec13),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        )
                      : Text(
                          _getText('login'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getText('noAccount'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistrationScreen(
                            selectedLanguage: widget.selectedLanguage,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      _getText('registerHere'),
                      style: const TextStyle(
                        color: Color(0xFF46ec13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _login() async {
    // Validate inputs
    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = _getText('enterPhone');
      });
      return;
    }

    if (_phoneController.text.trim().length != 10) {
      setState(() {
        _errorMessage = _getText('invalidPhone');
      });
      return;
    }

    if (_pin.length != 4) {
      setState(() {
        _errorMessage = _getText('invalidPin');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await AuthService.login(
        phoneNumber: _phoneController.text.trim(),
        pin: _pin,
      );

      if (result['success']) {
        // Navigate to main app
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(
              selectedLanguage: widget.selectedLanguage,
            ),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
