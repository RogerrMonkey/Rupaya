import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class AuthService {
  static User? _currentUser;
  static final List<VoidCallback> _listeners = [];

  // Get current user
  static User? get currentUser => _currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _currentUser != null;

  // Add listener for user state changes
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  // Remove listener
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners
  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // Register a new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String phoneNumber,
    required String pin,
    required String occupation,
    String? city,
    double? monthlyIncome,
    int? incomeDay,
  }) async {
    try {
      // Validate PIN (must be 4 digits)
      if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
        return {
          'success': false,
          'message': 'PIN must be exactly 4 digits'
        };
      }

      // Validate phone number
      if (!_isValidPhoneNumber(phoneNumber)) {
        return {
          'success': false,
          'message': 'Please enter a valid 10-digit phone number'
        };
      }

      // Format phone number
      String formattedPhone = _formatPhoneNumber(phoneNumber);

      // Register user using SQLite
      final result = await DatabaseService.registerUser(
        name: name.trim(),
        phoneNumber: formattedPhone,
        pin: pin,
        occupation: occupation.trim(),
        city: city?.trim(),
        monthlyIncome: monthlyIncome,
        incomeDay: incomeDay,
      );

      if (result['success']) {
        _currentUser = result['user'];

        // Save login state
        await _saveLoginState();
        
        // Notify listeners
        _notifyListeners();

        return {
          'success': true,
          'message': result['message'],
          'user': _currentUser
        };
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}'
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String pin,
  }) async {
    try {
      // Validate PIN
      if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
        return {
          'success': false,
          'message': 'PIN must be exactly 4 digits'
        };
      }

      // Validate and format phone number
      if (!_isValidPhoneNumber(phoneNumber)) {
        return {
          'success': false,
          'message': 'Please enter a valid 10-digit phone number'
        };
      }

      String formattedPhone = _formatPhoneNumber(phoneNumber);

      // Login user using SQLite
      final result = await DatabaseService.loginUser(
        phoneNumber: formattedPhone,
        pin: pin,
      );

      if (result['success']) {
        _currentUser = result['user'];

        // Save login state
        await _saveLoginState();
        
        // Notify listeners
        _notifyListeners();

        return {
          'success': true,
          'message': result['message'],
          'user': _currentUser
        };
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}'
      };
    }
  }

  // Sign out
  static Future<void> signOut() async {
    _currentUser = null;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userPhone');
  }

  // Save login state to local storage
  static Future<void> _saveLoginState() async {
    if (_currentUser != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', _currentUser!.id ?? '');
      await prefs.setString('userName', _currentUser!.name);
      await prefs.setString('userPhone', _currentUser!.phoneNumber);
    }
  }

  // Load saved login state
  static Future<bool> loadSavedLoginState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      String? userId = prefs.getString('userId');

      if (userId != null && userId.isNotEmpty) {
        // Load user from database
        _currentUser = await DatabaseService.getUserById(userId);
        if (_currentUser != null) {
          _notifyListeners();
          return true;
        }
      }
    }

    return false;
  }

  // Validate phone number (10 digits starting with 6-9)
  static bool _isValidPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleanPhone.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone);
  }

  // Format phone number to +91 format
  static String _formatPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length == 10) {
      return '+91$cleanPhone';
    }
    return phone;
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? occupation,
    String? city,
  }) async {
    if (_currentUser == null) {
      return {
        'success': false,
        'message': 'Please login first'
      };
    }

    final result = await DatabaseService.updateUser(
      userId: _currentUser!.id!,
      name: name,
      occupation: occupation,
      city: city,
    );

    if (result['success']) {
      _currentUser = result['user'];
      await _saveLoginState();
    }

    return result;
  }

  // Logout user
  static Future<void> logout() async {
    try {
      // Clear current user
      _currentUser = null;

      // Clear saved login state (same keys as _saveLoginState)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userId');
      await prefs.remove('userName');
      await prefs.remove('userPhone');
      
      // Notify listeners
      _notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }
}
