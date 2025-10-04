import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'gamification_screen.dart';
import 'income_management_screen.dart';
import 'insights_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String selectedLanguage;

  const MainNavigationScreen({super.key, required this.selectedLanguage});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(selectedLanguage: widget.selectedLanguage),
      IncomeManagementScreen(selectedLanguage: widget.selectedLanguage),
      InsightsScreen(selectedLanguage: widget.selectedLanguage),
      GamificationScreen(selectedLanguage: widget.selectedLanguage),
      SettingsScreen(selectedLanguage: widget.selectedLanguage),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF46EC13),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: _getText('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet),
              label: _getText('income'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.insights),
              label: _getText('insights'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.emoji_events),
              label: _getText('achievements'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: _getText('settings'),
            ),
          ],
        ),
      ),
    );
  }

  String _getText(String key) {
    final texts = {
      'hi': {
        'home': 'होम',
        'income': 'आय',
        'insights': 'जानकारी',
        'achievements': 'उपलब्धियां',
        'settings': 'सेटिंग्स',
      },
      'mr': {
        'home': 'होम',
        'income': 'उत्पन्न',
        'insights': 'अंतर्दृष्टी',
        'achievements': 'यश',
        'settings': 'सेटिंग्ज',
      },
      'en': {
        'home': 'Home',
        'income': 'Income',
        'insights': 'Insights',
        'achievements': 'Achievements',
        'settings': 'Settings',
      },
    };

    return texts[widget.selectedLanguage]?[key] ?? texts['en']![key]!;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
