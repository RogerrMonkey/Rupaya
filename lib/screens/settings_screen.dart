import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/voice_permission_manager.dart';
import '../screens/splash_screen.dart';
import '../models/user.dart';

class SettingsScreen extends StatefulWidget {
  final String selectedLanguage;

  const SettingsScreen({super.key, required this.selectedLanguage});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _backupEnabled = false;
  bool _notificationsEnabled = true;
  bool _voiceInputEnabled = true;
  String _selectedLanguage = 'en';
  User? _currentUser;
  
  void _onUserStateChanged() {
    setState(() {
      _currentUser = AuthService.currentUser;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _currentUser = AuthService.currentUser;
    AuthService.addListener(_onUserStateChanged);
    _loadVoiceInputPreference();
  }

  Future<void> _loadVoiceInputPreference() async {
    final enabled = await VoicePermissionManager.isVoiceEnabled();
    setState(() {
      _voiceInputEnabled = enabled;
    });
  }
  
  @override
  void dispose() {
    AuthService.removeListener(_onUserStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _getText('settings'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF46EC13).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF46EC13),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser?.name ?? 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser?.phoneNumber ?? 'No phone number',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_currentUser?.occupation != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _currentUser!.occupation,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showEditProfileDialog,
                    icon: const Icon(Icons.edit, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Preferences Section
            Text(
              _getText('preferences'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            // Language Selection
            _buildSettingsCard(
              title: _getText('language'),
              subtitle: _getLanguageDisplayName(_selectedLanguage),
              icon: Icons.language,
              onTap: _showLanguageDialog,
            ),

            const SizedBox(height: 12),

            // Voice Input Toggle
            _buildToggleCard(
              title: _getText('voiceInput'),
              subtitle: _getText('voiceInputDesc'),
              icon: Icons.mic,
              value: _voiceInputEnabled,
              onChanged: (value) async {
                await VoicePermissionManager.setVoiceEnabled(value);
                setState(() => _voiceInputEnabled = value);
                
                // Show feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value 
                        ? _getText('voiceEnabled') 
                        : _getText('voiceDisabled'),
                    ),
                    backgroundColor: const Color(0xFF46EC13),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Notifications Toggle
            _buildToggleCard(
              title: _getText('notifications'),
              subtitle: _getText('notificationsDesc'),
              icon: Icons.notifications,
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
            ),

            const SizedBox(height: 24),

            // Backup & Security Section
            Text(
              _getText('backupSecurity'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            // Cloud Backup Toggle
            _buildToggleCard(
              title: _getText('cloudBackup'),
              subtitle: _getText('cloudBackupDesc'),
              icon: Icons.cloud_upload,
              value: _backupEnabled,
              onChanged: (value) => setState(() => _backupEnabled = value),
            ),

            const SizedBox(height: 12),

            // Export Data
            _buildSettingsCard(
              title: _getText('exportData'),
              subtitle: _getText('exportDataDesc'),
              icon: Icons.download,
              onTap: _exportData,
            ),

            const SizedBox(height: 12),

            // Import Data
            _buildSettingsCard(
              title: _getText('importData'),
              subtitle: _getText('importDataDesc'),
              icon: Icons.upload,
              onTap: _importData,
            ),

            const SizedBox(height: 24),

            // Support Section
            Text(
              _getText('support'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            // Help & FAQ
            _buildSettingsCard(
              title: _getText('help'),
              subtitle: _getText('helpDesc'),
              icon: Icons.help_outline,
              onTap: () => _showHelpDialog(),
            ),

            const SizedBox(height: 12),

            // Privacy Policy
            _buildSettingsCard(
              title: _getText('privacy'),
              subtitle: _getText('privacyDesc'),
              icon: Icons.privacy_tip_outlined,
              onTap: () => _showPrivacyDialog(),
            ),

            const SizedBox(height: 12),

            // About App
            _buildSettingsCard(
              title: _getText('about'),
              subtitle: _getText('aboutDesc'),
              icon: Icons.info_outline,
              onTap: () => _showAboutDialog(),
            ),

            const SizedBox(height: 24),

            // Danger Zone
            Text(
              _getText('dangerZone'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF44336),
              ),
            ),

            const SizedBox(height: 16),

            // Clear All Data
            _buildSettingsCard(
              title: _getText('clearData'),
              subtitle: _getText('clearDataDesc'),
              icon: Icons.delete_forever,
              onTap: _showClearDataDialog,
              isDestructive: true,
            ),

            const SizedBox(height: 12),

            // Logout
            _buildSettingsCard(
              title: _getText('logout'),
              subtitle: _getText('logoutDesc'),
              icon: Icons.logout,
              onTap: _showLogoutDialog,
              isDestructive: true,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isDestructive ? const Color(0xFFF44336) : const Color(0xFF46EC13))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? const Color(0xFFF44336) : const Color(0xFF46EC13),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? const Color(0xFFF44336) : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF46EC13).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF46EC13),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF46EC13),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getText('selectLanguage')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('hi', 'हिंदी'),
            _buildLanguageOption('mr', 'मराठी'),
            _buildLanguageOption('en', 'English'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('cancel')),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name) {
    return RadioListTile<String>(
      value: code,
      groupValue: _selectedLanguage,
      onChanged: (value) {
        setState(() {
          _selectedLanguage = value!;
        });
        Navigator.pop(context);
      },
      title: Text(name),
      activeColor: const Color(0xFF46EC13),
    );
  }

  void _exportData() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF46EC13)),
      ),
    );

    // Simulate export
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getText('exportSuccess')),
        backgroundColor: const Color(0xFF46EC13),
      ),
    );
  }

  void _importData() {
    // TODO: Implement import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getText('importComingSoon')),
        backgroundColor: const Color(0xFF46EC13),
      ),
    );
  }

  void _showEditProfileDialog() {
    if (_currentUser == null) return;

    final nameController = TextEditingController(text: _currentUser!.name);
    final occupationController = TextEditingController(text: _currentUser!.occupation);
    final cityController = TextEditingController(text: _currentUser?.city ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: occupationController,
                decoration: const InputDecoration(
                  labelText: 'Occupation',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'City (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final occupation = occupationController.text.trim();
              final city = cityController.text.trim();

              if (name.isEmpty || occupation.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Name and occupation are required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              // Update profile
              final result = await AuthService.updateProfile(
                name: name,
                occupation: occupation,
                city: city.isEmpty ? null : city,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success'] 
                        ? const Color(0xFF46EC13) 
                        : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getText('help')),
        content: Text(_getText('helpContent')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('ok')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getText('privacy')),
        content: Text(_getText('privacyContent')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('ok')),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getText('about')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_rounded,
              size: 64,
              color: Color(0xFF46EC13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rupaya',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(_getText('aboutContent')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('ok')),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _getText('clearDataTitle'),
          style: const TextStyle(color: Color(0xFFF44336)),
        ),
        content: Text(_getText('clearDataWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Clear all data
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_getText('dataCleared')),
                  backgroundColor: const Color(0xFFF44336),
                ),
              );
            },
            child: Text(
              _getText('clearData'),
              style: const TextStyle(color: Color(0xFFF44336)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _getText('logoutTitle'),
          style: const TextStyle(color: Color(0xFFF44336)),
        ),
        content: Text(_getText('logoutWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Perform logout
              await AuthService.logout();
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_getText('logoutSuccess')),
                  backgroundColor: const Color(0xFF46EC13),
                ),
              );
              
              // Navigate to splash screen (which will redirect to login)
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              _getText('logout'),
              style: const TextStyle(color: Color(0xFFF44336)),
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      case 'en':
        return 'English';
      default:
        return 'English';
    }
  }

  String _getText(String key) {
    final texts = {
      'hi': {
        'settings': 'सेटिंग्स',
        'preferences': 'प्राथमिकताएं',
        'language': 'भाषा',
        'voiceInput': 'आवाज इनपुट',
        'voiceInputDesc': 'बोलकर खर्च और कर्ज जोड़ें',
        'voiceEnabled': 'आवाज इनपुट सक्षम किया गया',
        'voiceDisabled': 'आवाज इनपुट अक्षम किया गया',
        'notifications': 'सूचनाएं',
        'notificationsDesc': 'खर्च और कर्ज की याददिलाने',
        'backupSecurity': 'बैकअप और सुरक्षा',
        'cloudBackup': 'क्लाउड बैकअप',
        'cloudBackupDesc': 'Firebase में डेटा सुरक्षित रखें',
        'exportData': 'डेटा निर्यात करें',
        'exportDataDesc': 'अपना डेटा फाइल में सेव करें',
        'importData': 'डेटा आयात करें',
        'importDataDesc': 'फाइल से डेटा लोड करें',
        'support': 'सहायता',
        'help': 'मदद',
        'helpDesc': 'ऐप का इस्तेमाल कैसे करें',
        'privacy': 'प्राइवेसी नीति',
        'privacyDesc': 'आपका डेटा कैसे सुरक्षित है',
        'about': 'ऐप के बारे में',
        'aboutDesc': 'रुपया वर्जन 1.0.0',
        'dangerZone': 'खतरनाक क्षेत्र',
        'clearData': 'सारा डेटा साफ करें',
        'clearDataDesc': 'सभी खर्च और कर्ज डिलीट करें',
        'selectLanguage': 'भाषा चुनें',
        'cancel': 'रद्द करें',
        'ok': 'ठीक है',
        'exportSuccess': 'डेटा सफलतापूर्वक निर्यात हुआ',
        'importComingSoon': 'आयात सुविधा जल्दी आएगी',
        'helpContent': 'रुपया का इस्तेमाल करना आसान है:\n\n1. + बटन दबाकर खर्च जोड़ें\n2. आवाज से भी जोड़ सकते हैं\n3. कर्ज ट्रैक करें\n4. AI से सलाह लें',
        'privacyContent': 'आपका डेटा सुरक्षित है:\n\n• सब कुछ आपके फोन में रहता है\n• कोई डेटा शेयर नहीं होता\n• बैकअप वैकल्पिक है\n• आप कभी भी डिलीट कर सकते हैं',
        'aboutContent': 'आपका पॉकेट साथी - पैसे का आसान हिसाब',
        'clearDataTitle': 'सारा डेटा साफ करें?',
        'clearDataWarning': 'यह क्रिया वापस नहीं की जा सकती। सभी खर्च, कर्ज और सेटिंग्स डिलीट हो जाएंगे।',
        'dataCleared': 'सारा डेटा साफ हो गया',
      },
      'mr': {
        'settings': 'सेटिंग्ज',
        'preferences': 'प्राधान्ये',
        'language': 'भाषा',
        'voiceInput': 'आवाज इनपुट',
        'voiceInputDesc': 'बोलून खर्च आणि कर्ज जोडा',
        'voiceEnabled': 'आवाज इनपुट सक्षम केले',
        'voiceDisabled': 'आवाज इनपुट अक्षम केले',
        'notifications': 'सूचना',
        'notificationsDesc': 'खर्च आणि कर्जाच्या आठवणी',
        'backupSecurity': 'बॅकअप आणि सुरक्षा',
        'cloudBackup': 'क्लाउड बॅकअप',
        'cloudBackupDesc': 'Firebase मध्ये डेटा सुरक्षित ठेवा',
        'exportData': 'डेटा निर्यात करा',
        'exportDataDesc': 'तुमचा डेटा फाइलमध्ये सेव्ह करा',
        'importData': 'डेटा आयात करा',
        'importDataDesc': 'फाइलमधून डेटा लोड करा',
        'support': 'सहाय्य',
        'help': 'मदत',
        'helpDesc': 'अॅप कसा वापरावा',
        'privacy': 'प्रायव्हसी धोरण',
        'privacyDesc': 'तुमचा डेटा कसा सुरक्षित आहे',
        'about': 'अॅपबद्दल',
        'aboutDesc': 'रुपया आवृत्ती 1.0.0',
        'dangerZone': 'धोकादायक क्षेत्र',
        'clearData': 'सर्व डेटा साफ करा',
        'clearDataDesc': 'सर्व खर्च आणि कर्ज डिलीट करा',
        'selectLanguage': 'भाषा निवडा',
        'cancel': 'रद्द करा',
        'ok': 'ठीक आहे',
        'exportSuccess': 'डेटा यशस्वीरित्या निर्यात झाला',
        'importComingSoon': 'आयात सुविधा लवकरच येईल',
        'helpContent': 'रुपया वापरणे सोपे आहे:\n\n1. + बटन दाबून खर्च जोडा\n2. आवाजानेही जोडू शकता\n3. कर्ज ट्रॅक करा\n4. AI कडून सल्ला घ्या',
        'privacyContent': 'तुमचा डेटा सुरक्षित आहे:\n\n• सर्व काही तुमच्या फोनमध्ये राहते\n• कोणताही डेटा शेअर होत नाही\n• बॅकअप पर्यायी आहे\n• तुम्ही कधीही डिलीट करू शकता',
        'aboutContent': 'तुमचा पॉकेट साथी - पैशाचे सोपे हिशेब',
        'clearDataTitle': 'सर्व डेटा साफ करायचा?',
        'clearDataWarning': 'ही क्रिया परत केली जाऊ शकत नाही. सर्व खर्च, कर्ज आणि सेटिंग्ज डिलीट होतील.',
        'dataCleared': 'सर्व डेटा साफ झाला',
      },
      'en': {
        'settings': 'Settings',
        'preferences': 'Preferences',
        'language': 'Language',
        'voiceInput': 'Voice Input',
        'voiceInputDesc': 'Add expenses and debts by speaking',
        'voiceEnabled': 'Voice input enabled',
        'voiceDisabled': 'Voice input disabled',
        'notifications': 'Notifications',
        'notificationsDesc': 'Expense and debt reminders',
        'backupSecurity': 'Backup & Security',
        'cloudBackup': 'Cloud Backup',
        'cloudBackupDesc': 'Keep your data safe in Firebase',
        'exportData': 'Export Data',
        'exportDataDesc': 'Save your data to a file',
        'importData': 'Import Data',
        'importDataDesc': 'Load data from a file',
        'support': 'Support',
        'help': 'Help',
        'helpDesc': 'How to use the app',
        'privacy': 'Privacy Policy',
        'privacyDesc': 'How your data is protected',
        'about': 'About App',
        'aboutDesc': 'Rupaya version 1.0.0',
        'dangerZone': 'Danger Zone',
        'clearData': 'Clear All Data',
        'clearDataDesc': 'Delete all expenses and debts',
        'logout': 'Logout',
        'logoutDesc': 'Sign out of your account',
        'selectLanguage': 'Select Language',
        'cancel': 'Cancel',
        'ok': 'OK',
        'exportSuccess': 'Data exported successfully',
        'importComingSoon': 'Import feature coming soon',
        'helpContent': 'Using Rupaya is easy:\n\n1. Press + button to add expenses\n2. You can also add by voice\n3. Track your debts\n4. Get advice from AI',
        'privacyContent': 'Your data is secure:\n\n• Everything stays on your phone\n• No data is shared\n• Backup is optional\n• You can delete anytime',
        'aboutContent': 'Your Pocket Saathi - Easy money management',
        'clearDataTitle': 'Clear All Data?',
        'clearDataWarning': 'This action cannot be undone. All expenses, debts and settings will be deleted.',
        'dataCleared': 'All data cleared',
        'logoutTitle': 'Logout?',
        'logoutWarning': 'Are you sure you want to sign out?',
        'logoutSuccess': 'Logged out successfully',
      },
    };

    return texts[widget.selectedLanguage]?[key] ?? texts['en']![key]!;
  }
}
