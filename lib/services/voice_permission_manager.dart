import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoicePermissionManager {
  static const String _voiceConsentKey = 'voice_input_consent_granted';
  static const String _voiceEnabledKey = 'voice_input_enabled';

  /// Check if user has granted consent for voice input
  static Future<bool> hasConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_voiceConsentKey) ?? false;
  }

  /// Check if voice input is enabled
  static Future<bool> isVoiceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_voiceEnabledKey) ?? true; // Default enabled
  }

  /// Set voice input enabled/disabled
  static Future<void> setVoiceEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceEnabledKey, enabled);
  }

  /// Save consent
  static Future<void> saveConsent(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceConsentKey, granted);
  }

  /// Request microphone permission with consent dialog
  static Future<bool> requestPermission(BuildContext context, String language) async {
    // Check if consent already granted
    bool consentGranted = await hasConsent();

    if (!consentGranted) {
      // Show consent dialog
      bool? consent = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildConsentDialog(context, language),
      );

      if (consent != true) {
        return false;
      }

      await saveConsent(true);
    }

    // Request microphone permission from OS
    PermissionStatus status = await Permission.microphone.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.microphone.request();
    }

    if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      await _showOpenSettingsDialog(context, language);
      return false;
    }

    return status.isGranted;
  }

  /// Build consent dialog
  static Widget _buildConsentDialog(BuildContext context, String language) {
    final texts = _getTexts(language);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.mic, color: Color(0xFF46EC13), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texts['consentTitle']!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texts['consentMessage']!,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF46EC13).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF46EC13).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.check_circle, texts['privacy1']!),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.check_circle, texts['privacy2']!),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.check_circle, texts['privacy3']!),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            texts['decline']!,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF46EC13),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            texts['accept']!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Build info row widget
  static Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF46EC13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  /// Show dialog to open app settings
  static Future<void> _showOpenSettingsDialog(
    BuildContext context,
    String language,
  ) async {
    final texts = _getTexts(language);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.settings, color: Color(0xFFF44336)),
            const SizedBox(width: 12),
            Expanded(child: Text(texts['permissionDenied']!)),
          ],
        ),
        content: Text(texts['openSettings']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(texts['cancel']!),
          ),
          ElevatedButton(
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF46EC13),
              foregroundColor: Colors.white,
            ),
            child: Text(texts['openSettingsBtn']!),
          ),
        ],
      ),
    );
  }

  /// Get localized texts
  static Map<String, String> _getTexts(String language) {
    final texts = {
      'en': {
        'consentTitle': 'Voice Input Permission',
        'consentMessage':
            'Rupaya uses your microphone to help you add income, expenses, and debts by voice. This makes tracking your finances faster and easier.',
        'privacy1': 'No audio is stored on our servers',
        'privacy2': 'Voice data is processed locally',
        'privacy3': 'You can disable this anytime in Settings',
        'accept': 'Allow',
        'decline': 'Not Now',
        'permissionDenied': 'Permission Required',
        'openSettings':
            'Microphone permission is required for voice input. Please enable it in app settings.',
        'openSettingsBtn': 'Open Settings',
        'cancel': 'Cancel',
      },
      'hi': {
        'consentTitle': 'आवाज इनपुट अनुमति',
        'consentMessage':
            'रुपया आपके माइक्रोफ़ोन का उपयोग आय, खर्च और कर्ज को आवाज से जोड़ने में मदद के लिए करता है। यह आपके वित्त को ट्रैक करना तेज़ और आसान बनाता है।',
        'privacy1': 'कोई ऑडियो हमारे सर्वर पर संग्रहीत नहीं है',
        'privacy2': 'आवाज डेटा स्थानीय रूप से संसाधित है',
        'privacy3': 'आप इसे सेटिंग्स में कभी भी अक्षम कर सकते हैं',
        'accept': 'अनुमति दें',
        'decline': 'अभी नहीं',
        'permissionDenied': 'अनुमति आवश्यक',
        'openSettings':
            'आवाज इनपुट के लिए माइक्रोफ़ोन अनुमति आवश्यक है। कृपया इसे ऐप सेटिंग्स में सक्षम करें।',
        'openSettingsBtn': 'सेटिंग्स खोलें',
        'cancel': 'रद्द करें',
      },
      'mr': {
        'consentTitle': 'आवाज इनपुट परवानगी',
        'consentMessage':
            'रुपया तुमच्या मायक्रोफोनचा वापर उत्पन्न, खर्च आणि कर्ज आवाजाने जोडण्यासाठी करतो। हे तुमचे आर्थिक ट्रॅक करणे जलद आणि सोपे बनवते।',
        'privacy1': 'कोणताही ऑडिओ आमच्या सर्व्हरवर संग्रहित नाही',
        'privacy2': 'आवाज डेटा स्थानिक पातळीवर प्रक्रिया केला जातो',
        'privacy3': 'तुम्ही हे सेटिंग्जमध्ये कधीही अक्षम करू शकता',
        'accept': 'परवानगी द्या',
        'decline': 'आता नाही',
        'permissionDenied': 'परवानगी आवश्यक',
        'openSettings':
            'आवाज इनपुटसाठी मायक्रोफोन परवानगी आवश्यक आहे. कृपया ऍप सेटिंग्जमध्ये सक्षम करा.',
        'openSettingsBtn': 'सेटिंग्ज उघडा',
        'cancel': 'रद्द करा',
      },
    };

    return texts[language] ?? texts['en']!;
  }

  /// Check and request permission if needed
  static Future<bool> checkAndRequestPermission(
    BuildContext context,
    String language,
  ) async {
    // Check if voice is enabled
    bool enabled = await isVoiceEnabled();
    if (!enabled) {
      return false;
    }

    // Check if we have permission
    PermissionStatus status = await Permission.microphone.status;

    if (status.isGranted) {
      return true;
    }

    // Request permission
    return await requestPermission(context, language);
  }
}
