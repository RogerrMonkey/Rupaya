import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Simple voice input service using native speech recognition
/// 
/// Uses platform's built-in speech-to-text (Google/Apple)
/// - Free
/// - No setup required
/// - Works offline on most devices
/// - Real-time results
class VoskVoiceService {
  // Singleton pattern
  static final VoskVoiceService _instance = VoskVoiceService._internal();
  factory VoskVoiceService() => _instance;
  VoskVoiceService._internal();

  // Speech recognition
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  // State
  bool _isInitialized = false;
  bool _isRecording = false;
  String _currentLanguage = 'en';
  String _recognizedText = '';
  
  // Stream controllers
  final StreamController<String> _partialTranscriptionController = StreamController<String>.broadcast();
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  String get currentLanguage => _currentLanguage;
  Stream<String> get partialTranscriptionStream => _partialTranscriptionController.stream;

  /// Initialize the voice service
  Future<bool> initialize({String language = 'en'}) async {
    try {
      debugPrint('🎤 Initializing voice service...');
      
      // Initialize speech recognition
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );
      
      if (!available) {
        debugPrint('❌ Speech recognition not available');
        return false;
      }
      
      // Initialize TTS
      await _tts.setLanguage(_getLanguageCode(language));
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      
      _currentLanguage = language;
      _isInitialized = true;
      
      debugPrint('✅ Voice service initialized');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing: $e');
      return false;
    }
  }

  /// Change language
  Future<bool> changeLanguage(String language) async {
    if (_currentLanguage == language) return true;
    
    try {
      debugPrint('🌐 Changing language to: $language');
      await _tts.setLanguage(_getLanguageCode(language));
      _currentLanguage = language;
      return true;
    } catch (e) {
      debugPrint('❌ Error changing language: $e');
      return false;
    }
  }

  /// Get language code
  String _getLanguageCode(String lang) {
    switch (lang) {
      case 'hi':
        return 'hi-IN';
      case 'mr':
        return 'mr-IN';
      default:
        return 'en-IN';
    }
  }

  /// Check microphone permission
  Future<bool> checkPermission() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) return true;
      
      final result = await Permission.microphone.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking permission: $e');
      return false;
    }
  }

  /// Start recording
  Future<bool> startRecording() async {
    if (_isRecording) return false;
    if (!_isInitialized) {
      debugPrint('⚠️ Service not initialized');
      return false;
    }
    
    try {
      debugPrint('🎙️ Starting recording...');
      
      // Reset state
      _recognizedText = '';
      
      // Start speech recognition with enhanced settings for better accuracy
      await _speech.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          _partialTranscriptionController.add(_recognizedText);
          debugPrint('📝 Recognized: $_recognizedText (confidence: ${result.confidence})');
        },
        localeId: _getLanguageCode(_currentLanguage),
        listenFor: const Duration(seconds: 60), // Increased from 30 to 60 seconds
        pauseFor: const Duration(seconds: 5), // Increased from 3 to 5 seconds for better sentence completion
        partialResults: true,
        cancelOnError: false, // Changed to false to handle errors gracefully
        listenMode: stt.ListenMode.dictation, // Changed to dictation for better long-form recognition
        onSoundLevelChange: (level) {
          // Monitor sound levels for better feedback
          if (level > 0) {
            debugPrint('🔊 Sound level: $level');
          }
        },
      );
      
      _isRecording = true;
      debugPrint('✅ Recording started');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording
  Future<Map<String, dynamic>> stopRecording() async {
    if (!_isRecording) {
      return {
        'success': false,
        'error': 'Not recording',
      };
    }
    
    try {
      debugPrint('⏹️ Stopping recording...');
      
      await _speech.stop();
      _isRecording = false;
      
      if (_recognizedText.isEmpty) {
        return {
          'success': false,
          'error': 'No speech detected',
        };
      }
      
      debugPrint('✅ Final text: "$_recognizedText"');
      
      return {
        'success': true,
        'text': _recognizedText,
        'language': _currentLanguage,
        'source': 'speech_to_text',
      };
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Speak text using TTS
  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('❌ Error speaking: $e');
    }
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _speech.stop();
      _isRecording = false;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await cancelRecording();
      await _partialTranscriptionController.close();
      _isInitialized = false;
      debugPrint('🗑️ Voice service disposed');
    } catch (e) {
      debugPrint('❌ Error disposing: $e');
    }
  }
}
