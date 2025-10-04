import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? selectedLanguage;

  final List<Map<String, String>> languages = [
    {'name': 'हिंदी', 'code': 'hi'},
    {'name': 'मराठी', 'code': 'mr'},
    {'name': 'English', 'code': 'en'},
  ];

  Future<void> _saveLanguageAndProceed() async {
    if (selectedLanguage != null) {
      // Save selected language to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', selectedLanguage!);

      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(selectedLanguage: selectedLanguage!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6), // background-light from your design
      body: SafeArea(
        child: Column(
          children: [
            // Main content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Logo/Image placeholder
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: const Color(0xFF46EC13).withOpacity(0.1),
                        border: Border.all(
                          color: const Color(0xFF46EC13).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 80,
                        color: Color(0xFF46EC13),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // App Title
                    const Text(
                      'Rupaya',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Manage your money easily',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Language selection title
                    const Text(
                      'Select Language',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Language selection grid
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 12,
                          childAspectRatio: 6,
                        ),
                      itemCount: languages.length,
                      itemBuilder: (context, index) {
                        final language = languages[index];
                        final isSelected = selectedLanguage == language['code'];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedLanguage = language['code'];
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF46EC13).withOpacity(0.3)
                                  : const Color(0xFF46EC13).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF46EC13)
                                    : const Color(0xFF46EC13).withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                language['name']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Get Started Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedLanguage != null ? _saveLanguageAndProceed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF46EC13),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    disabledForegroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
