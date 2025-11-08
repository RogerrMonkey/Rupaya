import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String selectedLanguage;

  const RegistrationScreen({super.key, required this.selectedLanguage});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  String _pin = '';
  String _confirmPin = '';
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentStep = 0;
  int? _selectedIncomeDay;
  String? _selectedOccupation;

  // Common occupations list
  final List<String> _occupations = [
    'Shopkeeper',
    'Driver',
    'Teacher',
    'Doctor',
    'Engineer',
    'Accountant',
    'Farmer',
    'Mechanic',
    'Electrician',
    'Plumber',
    'Carpenter',
    'Cook/Chef',
    'Tailor',
    'Barber',
    'Construction Worker',
    'Factory Worker',
    'Office Worker',
    'Sales Person',
    'Security Guard',
    'Delivery Person',
    'Waiter/Waitress',
    'Housekeeper',
    'Student',
    'Business Owner',
    'Freelancer',
    'Retired',
    'Unemployed',
    'Other',
  ];

  // Language-specific text
  Map<String, Map<String, String>> get _texts => {
    'hi': {
      'title': 'रुपया में पंजीकरण करें',
      'subtitle': 'अपना खाता बनाएं',
      'name': 'पूरा नाम',
      'namePlaceholder': 'अपना नाम दर्ज करें',
      'phone': 'मोबाइल नंबर (10 अंक)',
      'phonePlaceholder': '9876543210',
      'occupation': 'व्यवसाय',
      'occupationPlaceholder': 'दुकानदार, ड्राइवर, आदि',
      'city': 'शहर (वैकल्पिक)',
      'cityPlaceholder': 'आपका शहर',
      'monthlyIncome': 'मासिक आय (वैकल्पिक)',
      'monthlyIncomePlaceholder': '₹ 25000',
      'incomeDay': 'वेतन दिन (वैकल्पिक)',
      'incomeDayPlaceholder': 'महीने का दिन चुनें',
      'pin': '4 अंकों का PIN बनाएं',
      'confirmPin': 'PIN की पुष्टि करें',
      'next': 'आगे',
      'register': 'पंजीकरण करें',
      'back': 'वापस',
      'alreadyHaveAccount': 'पहले से खाता है?',
      'loginHere': 'यहाँ लॉगिन करें',
      'pinMismatch': 'PIN मेल नहीं खाता',
      'fillAllFields': 'कृपया सभी आवश्यक फील्ड भरें',
    },
    'mr': {
      'title': 'रुपयामध्ये नोंदणी करा',
      'subtitle': 'तुमचे खाते तयार करा',
      'name': 'पूर्ण नाव',
      'namePlaceholder': 'तुमचे नाव टाका',
      'phone': 'मोबाइल नंबर (10 अंक)',
      'phonePlaceholder': '9876543210',
      'occupation': 'व्यवसाय',
      'occupationPlaceholder': 'दुकानदार, ड्रायव्हर, इत्यादी',
      'city': 'शहर (पर्यायी)',
      'cityPlaceholder': 'तुमचे शहर',
      'monthlyIncome': 'मासिक उत्पन्न (पर्यायी)',
      'monthlyIncomePlaceholder': '₹ 25000',
      'incomeDay': 'पगार दिवस (पर्यायी)',
      'incomeDayPlaceholder': 'महिन्याचा दिवस निवडा',
      'pin': '4 अंकी PIN बनवा',
      'confirmPin': 'PIN ची पुष्टी करा',
      'next': 'पुढे',
      'register': 'नोंदणी करा',
      'back': 'मागे',
      'alreadyHaveAccount': 'आधीच खाते आहे?',
      'loginHere': 'येथे लॉगिन करा',
      'pinMismatch': 'PIN जुळत नाही',
      'fillAllFields': 'कृपया सर्व आवश्यक फील्ड भरा',
    },
    'en': {
      'title': 'Register with Rupaya',
      'subtitle': 'Create your account',
      'name': 'Full Name',
      'namePlaceholder': 'Enter your name',
      'phone': 'Mobile Number (10 digits)',
      'phonePlaceholder': '9876543210',
      'occupation': 'Occupation',
      'occupationPlaceholder': 'Shopkeeper, Driver, etc.',
      'city': 'City (Optional)',
      'cityPlaceholder': 'Your city',
      'monthlyIncome': 'Monthly Income (Optional)',
      'monthlyIncomePlaceholder': '₹ 25000',
      'incomeDay': 'Salary Day (Optional)',
      'incomeDayPlaceholder': 'Select day of month',
      'pin': 'Create 4-digit PIN',
      'confirmPin': 'Confirm PIN',
      'next': 'Next',
      'register': 'Register',
      'back': 'Back',
      'alreadyHaveAccount': 'Already have an account?',
      'loginHere': 'Login here',
      'pinMismatch': 'PINs do not match',
      'fillAllFields': 'Please fill all required fields',
    },
  };

  String _getText(String key) {
    return _texts[widget.selectedLanguage]?[key] ?? _texts['en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(selectedLanguage: widget.selectedLanguage),
                ),
              );
            }
          },
        ),
        title: Text(
          _getText('title'),
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 2,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF46EC13)),
                ),
                const SizedBox(height: 32),

                Expanded(
                  child: _currentStep == 0 ? _buildBasicInfoStep() : _buildPinStep(),
                ),

                // Bottom buttons
                _buildBottomButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getText('subtitle'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),

          // Name field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: _getText('name'),
              hintText: _getText('namePlaceholder'),
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: _getText('phone'),
              hintText: _getText('phonePlaceholder'),
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              if (value.length != 10) {
                return 'Phone number must be 10 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Occupation dropdown
          DropdownButtonFormField<String>(
            value: _selectedOccupation,
            decoration: InputDecoration(
              labelText: _getText('occupation'),
              prefixIcon: const Icon(Icons.work),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
              ),
            ),
            items: _occupations.map((String occupation) {
              return DropdownMenuItem<String>(
                value: occupation,
                child: Text(occupation),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedOccupation = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Occupation is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // City field (optional)
          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: _getText('city'),
              hintText: _getText('cityPlaceholder'),
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Monthly Income field (optional)
          TextFormField(
            controller: _monthlyIncomeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _getText('monthlyIncome'),
              hintText: _getText('monthlyIncomePlaceholder'),
              prefixIcon: const Icon(Icons.currency_rupee),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
          const SizedBox(height: 16),

          // Income Day field (optional)
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: _getText('incomeDay'),
              hintText: _getText('incomeDayPlaceholder'),
              prefixIcon: const Icon(Icons.date_range),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
              ),
            ),
            items: List.generate(31, (index) => index + 1)
                .map((day) => DropdownMenuItem<int>(
                      value: day,
                      child: Text('Day $day'),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedIncomeDay = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPinStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.security,
            size: 80,
            color: Color(0xFF46EC13),
          ),
          const SizedBox(height: 32),

          Text(
            _getText('pin'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'This PIN will be used to login to your account',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // PIN input
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
              activeColor: const Color(0xFF46EC13),
              inactiveColor: Colors.grey.withOpacity(0.3),
              selectedColor: const Color(0xFF46EC13),
            ),
            onChanged: (value) {
              setState(() {
                _pin = value;
              });
            },
          ),
          const SizedBox(height: 32),

          Text(
            _getText('confirmPin'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // Confirm PIN input
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
              activeColor: const Color(0xFF46EC13),
              inactiveColor: Colors.grey.withOpacity(0.3),
              selectedColor: const Color(0xFF46EC13),
            ),
            onChanged: (value) {
              setState(() {
                _confirmPin = value;
              });
            },
          ),

          if (_pin.length == 4 && _confirmPin.length == 4 && _pin != _confirmPin)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _getText('pinMismatch'),
                style: const TextStyle(color: Colors.red),
              ),
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
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      children: [
        // Main action button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleButtonPress,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF46EC13),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                : Text(
                    _currentStep == 0 ? _getText('next') : _getText('register'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Login link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getText('alreadyHaveAccount'),
              style: const TextStyle(color: Colors.grey),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(selectedLanguage: widget.selectedLanguage),
                  ),
                );
              },
              child: Text(
                _getText('loginHere'),
                style: const TextStyle(
                  color: Color(0xFF46EC13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleButtonPress() {
    if (_currentStep == 0) {
      _nextStep();
    } else {
      _register();
    }
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _currentStep = 1;
        _errorMessage = '';
      });
    }
  }

  Future<void> _register() async {
    if (_pin.length != 4) {
      setState(() {
        _errorMessage = 'Please enter a 4-digit PIN';
      });
      return;
    }

    if (_pin != _confirmPin) {
      setState(() {
        _errorMessage = _getText('pinMismatch');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      double? monthlyIncomeValue;
      if (_monthlyIncomeController.text.trim().isNotEmpty) {
        monthlyIncomeValue = double.tryParse(_monthlyIncomeController.text.trim());
      }

      final result = await AuthService.register(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        pin: _pin,
        occupation: _selectedOccupation ?? 'Other',
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        monthlyIncome: monthlyIncomeValue,
        incomeDay: _selectedIncomeDay,
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
        _errorMessage = 'Registration failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _monthlyIncomeController.dispose();
    super.dispose();
  }
}
