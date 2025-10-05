import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/vosk_voice_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/debt.dart';

/// Beautiful animated voice input dialog with Vosk + Whisper integration
/// 
/// Features:
/// - Pulsing microphone animation
/// - Sound wave visualization
/// - Real-time transcription display
/// - Language selector dropdown
/// - Smooth state transitions
/// - Error handling with user-friendly messages
class VoiceInputDialogV2 extends StatefulWidget {
  final String initialLanguage;
  final Function(bool success)? onComplete;

  const VoiceInputDialogV2({
    super.key,
    this.initialLanguage = 'en',
    this.onComplete,
  });

  @override
  State<VoiceInputDialogV2> createState() => _VoiceInputDialogV2State();
}

class _VoiceInputDialogV2State extends State<VoiceInputDialogV2>
    with TickerProviderStateMixin {
  final VoskVoiceService _voiceService = VoskVoiceService();
  
  // State variables
  bool _isInitializing = true;
  bool _isListening = false;
  bool _isProcessing = false;
  String _selectedLanguage = 'en';
  String _transcriptionText = '';
  String _statusMessage = '';
  String _errorMessage = '';
  // Confidence not used with whisper.cpp (always high quality)
  String _source = '';
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _glowController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Audio level for wave animation
  double _audioLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;
    
    // Initialize animations
    _setupAnimations();
    
    // Initialize voice service
    _initializeVoiceService();
  }

  void _setupAnimations() {
    // Pulse animation for microphone (slower, smoother)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Glow animation (breathing effect)
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // Wave animation for sound visualization
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Slide-up entrance animation for modal
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    // Start entrance animation
    _slideController.forward();
  }

  Future<void> _initializeVoiceService() async {
    setState(() {
      _isInitializing = true;
      _statusMessage = _getText('initializing');
    });
    
    try {
      // Check permission
      final hasPermission = await _voiceService.checkPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = _getText('permissionDenied');
          _isInitializing = false;
        });
        return;
      }
      
      // Initialize service
      final success = await _voiceService.initialize(language: _selectedLanguage);
      
      if (success) {
        setState(() {
          _isInitializing = false;
          _statusMessage = _getText('readyToRecord');
        });
      } else {
        setState(() {
          _errorMessage = _getText('initializationFailed');
          _isInitializing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getText('error') + ': $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _startListening() async {
    if (_isListening || _isProcessing) return;
    
    setState(() {
      _isListening = true;
      _transcriptionText = '';
      _statusMessage = _getText('listening');
      _errorMessage = '';
      // No confidence tracking needed
    });
    
    // Start animations
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    
    // Start recording
    final success = await _voiceService.startRecording();
    
    if (!success) {
      setState(() {
        _errorMessage = _getText('recordingFailed');
        _isListening = false;
      });
      _stopAnimations();
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    
    setState(() {
      _isListening = false;
      _isProcessing = true;
      _statusMessage = _getText('processing');
    });
    
    // Stop animations
    _stopAnimations();
    
    // Stop recording and get transcription
    final result = await _voiceService.stopRecording();
    
    if (result['success']) {
      final text = result['text'] ?? '';
      final source = result['source'] ?? 'whisper_cpp';
      
      setState(() {
        _transcriptionText = text;
        _source = source;
        _isProcessing = false;
      });
      
      // If we have text, process it
      if (text.isNotEmpty) {
        await _processTranscription(text);
      } else {
        setState(() {
          _statusMessage = _getText('noSpeechDetected');
          _errorMessage = _getText('tryAgain');
        });
      }
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = result['error'] ?? _getText('processingFailed');
        _statusMessage = '';
      });
    }
  }

  Future<void> _processTranscription(String text) async {
    setState(() {
      _statusMessage = _getText('creatingTransaction');
    });
    
    try {
      // Parse and create transaction (reusing existing NLP logic)
      final parsed = _parseVoiceInput(text.toLowerCase(), _selectedLanguage);
      
      if (parsed['type'] == null) {
        setState(() {
          _statusMessage = _getText('couldNotUnderstand');
          _errorMessage = _getText('tryAgain');
        });
        return;
      }
      
      // Create transaction
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = _getText('userNotLoggedIn');
        });
        return;
      }
      
      Map<String, dynamic> result;
      
      switch (parsed['type']) {
        case 'income':
          result = await _createIncome(parsed, currentUser.id!);
          break;
        case 'expense':
          result = await _createExpense(parsed, currentUser.id!);
          break;
        case 'debt_i_owe':
        case 'debt_owed_to_me':
          result = await _createDebt(parsed, currentUser.id!);
          break;
        default:
          // This should never happen as _detectTransactionType always returns a valid type
          debugPrint('Unknown transaction type: ${parsed['type']}');
          debugPrint('Parsed data: $parsed');
          result = {'success': false, 'message': 'Unknown transaction type: ${parsed['type']}'};
      }
      
      if (result['success']) {
        setState(() {
          _statusMessage = _getText('success');
        });
        
        // Speak success message
        await _voiceService.speak(_getText('transactionCreated'));
        
        // Wait a bit then close
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          widget.onComplete?.call(true);
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? _getText('failed');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getText('error') + ': $e';
      });
    }
  }

  void _stopAnimations() {
    _pulseController.stop();
    _glowController.stop();
    _waveController.stop();
  }

  Future<void> _changeLanguage(String newLanguage) async {
    if (newLanguage == _selectedLanguage) return;
    
    setState(() {
      _isInitializing = true;
      _statusMessage = _getText('switchingLanguage');
    });
    
    final success = await _voiceService.changeLanguage(newLanguage);
    
    if (success) {
      setState(() {
        _selectedLanguage = newLanguage;
        _isInitializing = false;
        _statusMessage = _getText('readyToRecord');
      });
    } else {
      setState(() {
        _isInitializing = false;
        _errorMessage = _getText('languageChangeFailed');
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.black.withOpacity(0.5),
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 650),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFF0FFF4), // Light green tint
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF46EC13).withOpacity(0.3),
                  blurRadius: 50,
                  spreadRadius: 5,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  // Main content with solid background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          const Color(0xFFF8FFF9),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header
                        _buildHeader(),
                        
                        // Main content area
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                
                                // Microphone with animation
                                _buildMicrophoneArea(),
                                
                                const SizedBox(height: 30),
                                
                                // Transcription display
                                _buildTranscriptionCard(),
                                
                                const SizedBox(height: 20),
                                
                                // Status and error messages
                                _buildStatusArea(),
                                
                                const SizedBox(height: 20),
                                
                                // Example phrases
                                if (!_isListening && !_isProcessing && _transcriptionText.isEmpty)
                                  _buildExamplePhrases(),
                                
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Loading overlay with solid background
                  if (_isInitializing)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF46EC13)),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _statusMessage,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF0FFF4),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF46EC13).withOpacity(0.1),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Animated icon with gradient background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF46EC13).withOpacity(0.2),
                  const Color(0xFF46EC13).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.mic_rounded,
              color: Color(0xFF46EC13),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getText('voiceInput'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _getText('tapToSpeak'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded),
            color: Colors.grey[600],
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF46EC13).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF46EC13).withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF46EC13),
          ),
          items: const [
            DropdownMenuItem(value: 'en', child: Text('🇮🇳 EN')),
            DropdownMenuItem(value: 'hi', child: Text('🇮🇳 HI')),
            DropdownMenuItem(value: 'mr', child: Text('🇮🇳 MR')),
          ],
          onChanged: _isListening || _isProcessing
              ? null
              : (value) {
                  if (value != null) {
                    _changeLanguage(value);
                  }
                },
        ),
      ),
    );
  }

  Widget _buildMicrophoneArea() {
    return GestureDetector(
      onTap: _isInitializing || _isProcessing
          ? null
          : (_isListening ? _stopListening : _startListening),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
        builder: (context, child) {
          return Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isListening
                    ? [
                        const Color(0xFF46EC13),
                        const Color(0xFF2E7D32),
                      ]
                    : [
                        const Color(0xFFE8F5E9),
                        const Color(0xFFC8E6C9),
                      ],
              ),
              boxShadow: [
                if (_isListening) ...[
                  BoxShadow(
                    color: const Color(0xFF46EC13).withOpacity(_glowAnimation.value * 0.5),
                    blurRadius: 50 * _glowAnimation.value,
                    spreadRadius: 15 * _glowAnimation.value,
                  ),
                  BoxShadow(
                    color: const Color(0xFF46EC13).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ] else ...[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ],
            ),
            child: Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: Center(
                child: Icon(
                  _isListening
                      ? Icons.mic_rounded
                      : _isProcessing
                          ? Icons.hourglass_empty_rounded
                          : Icons.mic_none_rounded,
                  size: 80,
                  color: _isListening ? Colors.white : const Color(0xFF46EC13),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranscriptionCard() {
    if (_transcriptionText.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF5F5F5),
              const Color(0xFFEEEEEE),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.text_fields_rounded,
                color: Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _getText('tapToSpeak'),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF46EC13).withOpacity(0.12),
            const Color(0xFF46EC13).withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF46EC13).withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF46EC13).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF46EC13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getText('transcribed'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$_transcriptionText"',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusArea() {
    if (_statusMessage.isEmpty && _errorMessage.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        if (_statusMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF46EC13).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (_isProcessing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF46EC13)),
                    ),
                  )
                else
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF46EC13), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExamplePhrases() {
    final examples = _getExamplePhrases(_selectedLanguage);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getText('examples'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: examples.map((example) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF46EC13).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF46EC13).withOpacity(0.2),
                ),
              ),
              child: Text(
                example,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF46EC13).withOpacity(0.1),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: OutlinedButton(
              onPressed: _isListening || _isProcessing
                  ? null
                  : () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: Colors.grey[400]!, width: 1.5),
              ),
              child: Text(
                _getText('cancel'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Record/Stop button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isInitializing || _isProcessing
                  ? null
                  : (_isListening ? _stopListening : _startListening),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? Colors.red : const Color(0xFF46EC13),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: _isListening
                    ? Colors.red.withOpacity(0.4)
                    : const Color(0xFF46EC13).withOpacity(0.4),
              ),
              icon: Icon(
                _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 24,
              ),
              label: Text(
                _isListening ? _getText('stop') : _getText('record'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ENHANCED NLP METHODS - Ultra-accurate with JSON-based parsing
  // ============================================================================

  /// Main parser - converts voice input to structured JSON matching DB schema
  Map<String, dynamic> _parseVoiceInput(String text, String language) {
    // Step 0: Advanced text preprocessing for better recognition
    final preprocessedText = _preprocessText(text);
    final normalizedText = preprocessedText.toLowerCase().trim();
    
    // Step 1: Detect transaction type with high accuracy + fuzzy matching
    final transactionType = _detectTransactionType(normalizedText, language) ?? 'expense';
    
    // Step 2: Extract amount with multiple patterns + fuzzy number recognition
    final amount = _extractAmount(normalizedText, language);
    
    // Step 3: Build structured JSON based on type
    Map<String, dynamic> result = {
      'type': transactionType,
      'amount': amount,
      'originalText': text,
    };

    switch (transactionType) {
      case 'expense':
        result.addAll(_parseExpenseDetails(normalizedText, language));
        break;
      case 'income':
        result.addAll(_parseIncomeDetails(normalizedText, language));
        break;
      case 'debt_i_owe':
      case 'debt_owed_to_me':
        result.addAll(_parseDebtDetails(normalizedText, language, transactionType));
        break;
      default:
        // Fallback to expense if unknown type
        result.addAll(_parseExpenseDetails(normalizedText, language));
        result['type'] = 'expense';
    }

    return result;
  }

  /// Advanced text preprocessing to fix common speech recognition errors
  String _preprocessText(String text) {
    String processed = text;
    
    // ===== COMMON ERRORS - ALL LANGUAGES =====
    final commonErrors = {
      // ===== ENGLISH HELPER WORDS & PREPOSITIONS =====
      // Prepositions & connectors
      'four': 'for', 'fore': 'for', 'too': 'to', 'two': 'to',
      'off': 'of', 'form': 'from', 'forme': 'from',
      'inn': 'in', 'on': 'on', 'at': 'at', 'bye': 'by', 'buy': 'by',
      'with': 'with', 'width': 'with', 'wit': 'with',
      'than': 'then', 'den': 'then',
      
      // Action words
      'give': 'give', 'giv': 'give', 'gave': 'gave', 'gay': 'gave',
      'take': 'take', 'tak': 'take', 'took': 'took', 'tuk': 'took',
      'lend': 'lend', 'land': 'lend', 'lent': 'lent', 'land': 'lent',
      'borrow': 'borrow', 'baro': 'borrow', 'borrow': 'borrow',
      'pay': 'pay', 'paid': 'paid', 'payed': 'paid',
      'get': 'get', 'got': 'got', 'gat': 'got',
      'spend': 'spend', 'spent': 'spent', 'spend': 'spent',
      
      // ===== NUMBER CORRECTIONS - ENGLISH =====
      'rupees': 'rs', 'rupee': 'rs', 'rupaye': 'rs', 'rupaiya': 'rs', 'rupaya': 'rs',
      'dollars': 'rs', 'dollar': 'rs', 'bucks': 'rs', 'buck': 'rs',
      'hundred': 'hundred', 'hundread': 'hundred', 'hunderd': 'hundred',
      'thousand': 'thousand', 'tousand': 'thousand', 'thousand': 'thousand',
      
      // Number word corrections
      'pain': 'paanch', 'panch': 'paanch', // five
      'so': 'sau', 'sow': 'sau', // hundred
      'teen': 'teen', 'tin': 'teen', // three/teen
      'char': 'char', 'chaar': 'char', // four
      
      // ===== COMMON MISHEARD WORDS =====
      'would': 'food', 'wood': 'food', 'good': 'food', 'hood': 'food',
      'but': 'bought', 'bot': 'bought', 'boat': 'bought',
      'pain': 'paid', 'pane': 'paid',
      'spend': 'spent', 'spending': 'spent',
      
      // ===== TRANSACTION TYPE CORRECTIONS =====
      'expense': 'spent', 'expend': 'spent', 'expanding': 'spent',
      'expand': 'spent', 'expanse': 'spent',
      
      // ===== CATEGORY CORRECTIONS =====
      // Food related
      'would': 'food', 'wood': 'food', 'foot': 'food',
      'eat': 'eat', 'ate': 'ate', 'eaten': 'eaten',
      'launch': 'lunch', 'lanch': 'lunch',
      'diner': 'dinner', 'dinner': 'dinner',
      
      // Transport related
      'travail': 'travel', 'travell': 'travel',
      'bus': 'bus', 'bass': 'bus', 'buss': 'bus',
      'tax': 'taxi', 'taxee': 'taxi',
      'metro': 'metro', 'metrо': 'metro',
      
      // Shopping related
      'shoping': 'shopping', 'shop': 'shopping',
      'cloths': 'clothes', 'close': 'clothes',
      
      // ===== HINDI CORRECTIONS =====
      // Numbers
      'pain': 'paanch', 'panch': 'paanch', 'punch': 'paanch', // 5
      'so': 'sau', 'sow': 'sau', 'sou': 'sau', // 100
      'tin': 'teen', 'tine': 'teen', // 3
      'chaar': 'char', 'cher': 'char', // 4
      'das': 'das', 'dass': 'das', 'dus': 'das', // 10
      
      // Prepositions & helpers (Hindi)
      'ko': 'ko', 'koh': 'ko', 'kho': 'ko', // to
      'se': 'se', 'say': 'se', 'sae': 'se', // from/by
      'ne': 'ne', 'nay': 'ne', 'nae': 'ne', // by/has
      'ke': 'ke', 'kay': 'ke', 'kae': 'ke', // of
      'ka': 'ka', 'kaa': 'ka', 'kah': 'ka', // of
      'ki': 'ki', 'kee': 'ki', 'kih': 'ki', // of
      'me': 'me', 'mai': 'me', 'mein': 'me', // in
      'par': 'par', 'per': 'par', 'pur': 'par', // on/at
      
      // Action words (Hindi)
      'diya': 'diya', 'dia': 'diya', 'dya': 'diya', // gave
      'liya': 'liya', 'lia': 'liya', 'lya': 'liya', // took
      'kiya': 'kiya', 'kia': 'kiya', 'kya': 'kiya', // did
      'khaya': 'khaya', 'kaya': 'khaya', 'khya': 'khaya', // ate
      
      // Food (Hindi)
      'khana': 'khana', 'kana': 'khana', 'khaana': 'khana',
      'chai': 'chai', 'chay': 'chai', 'cha': 'chai',
      'pani': 'pani', 'paani': 'pani', 'paane': 'pani',
      
      // Money (Hindi)
      'paise': 'paise', 'paise': 'paise', 'paisa': 'paise',
      'rupee': 'rupaye', 'rupay': 'rupaye', 'rupay': 'rupaye',
      
      // ===== MARATHI CORRECTIONS =====
      // Numbers
      'paach': 'paanch', 'panch': 'paanch', // 5
      'shambhar': 'shambhar', 'shambar': 'shambhar', // 100
      'teen': 'teen', 'tin': 'teen', // 3
      'char': 'char', 'chaar': 'char', // 4
      
      // Prepositions & helpers (Marathi)
      'la': 'la', 'laa': 'la', 'lah': 'la', // to
      'ne': 'ne', 'nay': 'ne', 'nae': 'ne', // by/has
      'pasun': 'pasun', 'pasoon': 'pasun', // from
      'sathi': 'sathi', 'saathi': 'sathi', 'sathee': 'sathi', // for
      'madhye': 'madhye', 'madhe': 'madhye', // in
      'var': 'var', 'vaar': 'var', 'war': 'var', // on
      
      // Action words (Marathi)
      'dila': 'dila', 'dela': 'dila', 'dyla': 'dila', // gave
      'ghetla': 'ghetla', 'ghetle': 'ghetla', 'ghyatla': 'ghetla', // took
      'kela': 'kela', 'kele': 'kela', 'kyla': 'kela', // did
      'khalla': 'khalla', 'khalle': 'khalla', 'khalay': 'khalla', // ate
      
      // Food (Marathi)
      'jevan': 'jevan', 'jewan': 'jevan', 'jewaan': 'jevan',
      'cha': 'cha', 'chai': 'cha', 'chaa': 'cha',
      'pani': 'pani', 'paani': 'pani', 'pane': 'pani',
      
      // ===== REMOVE FILLER WORDS =====
      'um': '', 'umm': '', 'ummm': '',
      'uh': '', 'uhh': '', 'uhhh': '',
      'like': '', 'you know': '', 'i mean': '',
      'sort of': '', 'kind of': '', 'kinda': '', 'sorta': '',
      'basically': '', 'actually': '', 'literally': '',
      'just': '', 'really': '', 'very': '',
      
      // Hindi fillers
      'haan': '', 'han': '', 'ha': '',
      'toh': '', 'to': '', 'matlab': '',
      'kya': '', 'kyaa': '', 'kyu': '',
      'bas': '', 'waisa': '', 'aise': '',
      
      // Marathi fillers
      'ho': '', 'haan': '', 'are': '',
      'mhanje': '', 'asa': '', 'ase': '',
      
      // ===== EXTRA HELPER WORDS =====
      // English
      'towards': 'to', 'toward': 'to',
      'onto': 'on', 'into': 'in',
      'upon': 'on', 'above': 'on',
      'below': 'under', 'beneath': 'under',
      'among': 'with', 'amongst': 'with',
      'between': 'between', 'betwean': 'between',
      'during': 'during', 'while': 'during',
      'after': 'after', 'before': 'before',
      'until': 'until', 'till': 'until',
      
      // More action words
      'receive': 'received', 'recieve': 'received',
      'purchase': 'purchased', 'purcase': 'purchased',
      'acquire': 'acquired', 'aquire': 'acquired',
      'obtain': 'obtained', 'obtaine': 'obtained',
      
      // Hindi helpers
      'ke liye': 'ko', 'keliye': 'ko', 'keliye': 'ko',
      'dwara': 'se', 'dwaara': 'se', 'd': 'se',
      'taraf': 'ko', 'taraph': 'ko', 'tarraf': 'ko',
      
      // Marathi helpers
      'karita': 'sathi', 'karitan': 'sathi',
      'kadun': 'pasun', 'kadhun': 'pasun',
      'towar': 'la', 'taraf': 'la',
    };
    
    // Apply corrections
    for (var entry in commonErrors.entries) {
      // Use word boundary regex for more accurate replacements
      processed = processed.replaceAll(
        RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false),
        entry.value,
      );
    }
    
    // Remove extra whitespace
    processed = processed.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return processed;
  }

  /// Fuzzy string matching to handle typos and misheard words
  bool _fuzzyMatch(String text, String keyword, {double threshold = 0.7}) {
    if (text.contains(keyword)) return true;
    
    // Calculate Levenshtein distance for fuzzy matching
    final distance = _levenshteinDistance(text, keyword);
    final maxLength = math.max(text.length, keyword.length);
    final similarity = 1 - (distance / maxLength);
    
    return similarity >= threshold;
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        final cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = math.min(
          math.min(v1[j] + 1, v0[j + 1] + 1),
          v0[j] + cost,
        );
      }
      final temp = v0;
      v0 = v1;
      v1 = temp;
    }

    return v0[s2.length];
  }

  /// Enhanced amount extraction with multiple patterns and number word support
  double? _extractAmount(String text, String language) {
    // Pattern 1: Direct numbers (500, 1000, 50.50)
    final directNumberRegex = RegExp(r'\d+\.?\d*');
    final matches = directNumberRegex.allMatches(text);
    
    if (matches.isNotEmpty) {
      // Get the largest number (usually the amount)
      double? maxAmount;
      for (var match in matches) {
        final num = double.tryParse(match.group(0)!);
        if (num != null && (maxAmount == null || num > maxAmount)) {
          maxAmount = num;
        }
      }
      if (maxAmount != null) return maxAmount;
    }

    // Pattern 2: Written numbers with multipliers
    // Examples: "five hundred", "teen sau", "paanch hazaar"
    final numberWords = _getNumberWords(language);
    final multipliers = _getMultipliers(language);
    
    double baseNumber = 0;
    double total = 0;
    
    final words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      final word = words[i].toLowerCase();
      
      if (numberWords.containsKey(word)) {
        baseNumber = numberWords[word]!;
      } else if (multipliers.containsKey(word)) {
        if (baseNumber > 0) {
          total += baseNumber * multipliers[word]!;
          baseNumber = 0;
        } else {
          total += multipliers[word]!;
        }
      }
    }
    
    total += baseNumber;
    return total > 0 ? total : null;
  }

  Map<String, double> _getNumberWords(String language) {
    final common = {
      // English
      'one': 1.0, 'two': 2.0, 'three': 3.0, 'four': 4.0, 'five': 5.0,
      'six': 6.0, 'seven': 7.0, 'eight': 8.0, 'nine': 9.0, 'ten': 10.0,
      'eleven': 11.0, 'twelve': 12.0, 'thirteen': 13.0, 'fourteen': 14.0, 'fifteen': 15.0,
      'sixteen': 16.0, 'seventeen': 17.0, 'eighteen': 18.0, 'nineteen': 19.0, 'twenty': 20.0,
      'thirty': 30.0, 'forty': 40.0, 'fifty': 50.0, 'sixty': 60.0, 'seventy': 70.0,
      'eighty': 80.0, 'ninety': 90.0,
    };

    if (language == 'hi' || language == 'mr') {
      return {
        ...common,
        // Hindi/Marathi numbers
        'ek': 1.0, 'do': 2.0, 'teen': 3.0, 'char': 4.0, 'paanch': 5.0, 'panch': 5.0,
        'chhe': 6.0, 'saat': 7.0, 'aath': 8.0, 'nau': 9.0, 'das': 10.0,
        'gyarah': 11.0, 'barah': 12.0, 'terah': 13.0, 'chaudah': 14.0, 'pandrah': 15.0,
        'solah': 16.0, 'satrah': 17.0, 'atharah': 18.0, 'unnis': 19.0, 'bees': 20.0,
        'tees': 30.0, 'chalis': 40.0, 'pachas': 50.0, 'saath': 60.0, 'sattar': 70.0,
        'assi': 80.0, 'nabbe': 90.0,
      };
    }
    
    return common;
  }

  Map<String, double> _getMultipliers(String language) {
    return {
      'hundred': 100.0, 'thousand': 1000.0, 'lakh': 100000.0, 'crore': 10000000.0,
      'sau': 100.0, 'shambhar': 100.0, 'hazaar': 1000.0, 'hajar': 1000.0,
      'lakh': 100000.0, 'karod': 10000000.0, 'crore': 10000000.0,
      'k': 1000.0, 'thousand': 1000.0,
    };
  }

  /// Enhanced transaction type detection with more patterns
  String _detectTransactionType(String text, String language) {
    // Expanded keyword sets for better accuracy
    final patterns = _getTransactionPatterns(language);
    
    // CRITICAL: Check income FIRST for gift/salary/bonus keywords
    // These are very specific and should not be confused with debts
    final incomeStrongIndicators = [
      'gift', 'gifted', 'salary', 'bonus', 'earned', 'received payment',
      'credited', 'won', 'prize', 'refund', 'cashback', 'dividend',
      'upahaar', 'inam', 'tankha', 'kamaaya', 'kamaya', 'milaa',
      'bhev', 'paagar', 'inam', 'kamavale', 'prapt'
    ];
    
    for (var indicator in incomeStrongIndicators) {
      if (text.contains(indicator)) {
        // Double-check it's not a debt by looking for debt-specific context
        if (!text.contains('loan') && !text.contains('udhaar') && 
            !text.contains('owe') && !text.contains('borrow') &&
            !text.contains('karz') && !text.contains('qarz') &&
            !text.contains('pharaki')) {
          return 'income';
        }
      }
    }
    
    // Check for very specific debt patterns with context
    // debt_owed_to_me (I lent to someone)
    final lentPatterns = [
      'lent', 'lend', 'gave loan', 'loaned to', 'udhaar diya',
      'karz diya', 'loan diya', 'owes me', 'owe me', 'pharaki dili'
    ];
    for (var pattern in lentPatterns) {
      if (text.contains(pattern)) return 'debt_owed_to_me';
    }
    
    // debt_i_owe (I borrowed from someone)
    final borrowedPatterns = [
      'borrowed', 'borrow', 'took loan', 'got loan', 'owe to',
      'udhaar liya', 'karz liya', 'loan liya', 'pharaki gheyali',
      'have to pay', 'need to pay', 'should pay'
    ];
    for (var pattern in borrowedPatterns) {
      if (text.contains(pattern)) return 'debt_i_owe';
    }
    
    // Then check general income patterns
    for (var pattern in patterns['income']!) {
      if (text.contains(pattern)) {
        // Make sure it's not actually an expense
        if (!text.contains('spent') && !text.contains('bought') && 
            !text.contains('kharch') && !text.contains('kharida') &&
            !text.contains('paid for')) {
          return 'income';
        }
      }
    }
    
    // Finally expense (most common, check last)
    for (var pattern in patterns['expense']!) {
      if (text.contains(pattern)) return 'expense';
    }

    // Default to expense if amount is detected (most common case)
    return 'expense';
  }

  Map<String, List<String>> _getTransactionPatterns(String language) {
    if (language == 'hi') {
      return {
        'income': [
          // Earning
          'kamaaya', 'kamaaye', 'kamaya', 'kamayi', 'kamaate', 'kamaunga', 'kamaaonga',
          'milaa', 'mila', 'mile', 'milega', 'milenge', 'mil gaya', 'mil gayi',
          'aaya', 'aayi', 'aayega', 'aayenge', 'aa gaya', 'aa gayi',
          'paaya', 'paye', 'paa gaya', 'mila', 'prapt', 'prapt hua',
          
          // Salary & Income - STRONG INDICATORS
          'salary', 'tankha', 'vetann', 'maasik', 'monthly',
          'income', 'aay', 'aamdani', 'kamaayi',
          'bonus', 'incentive', 'commission', 'dalali',
          
          // Gifts - VERY STRONG INDICATORS
          'upahaar', 'tohfa', 'tohfaa', 'gift', 'inam', 'inaam',
          'upahaar mila', 'gift mila', 'inam mila',
          
          // Payment received
          'payment mila', 'paisa aaya', 'paise aaye', 'payment aayi',
          'credited', 'credit hua', 'account me aaya',
          
          // From family (income context)
          'papa se', 'mummy se', 'dad se', 'mom se', 'ma se',
          'bhai se', 'behan se', 'dost se', 'rishtedaar se',
        ],
        'expense': [
          // Spending
          'kharch', 'kharcha', 'kharch kiya', 'kharcha kiya', 'kharchaa',
          'lagaya', 'lagaye', 'laga diya', 'lagaa diye',
          'diya', 'di', 'de diya', 'de di', 'diye', 'debit',
          
          // Buying
          'kharida', 'kharide', 'khareed', 'khareeda', 'khareedaa',
          'liya', 'li', 'le liya', 'le li', 'liye', 'leta',
          'buy', 'bought', 'purchase', 'kharidari',
          
          // Paying
          'paid', 'pay kiya', 'payment kiya', 'ada kiya',
          'bhugtan', 'chukaya', 'chukaayi',
          
          // Using money
          'spent', 'used', 'use kiya', 'istemal',
          'gawa diya', 'waste kiya', 'barbad',
        ],
        'debt_i_owe': [
          // Borrowing - specific patterns only
          'udhaar liya', 'udhaar le liya', 'udhar liya', 'karz liya',
          'borrowed', 'loan liya', 'qarz liya', 'qarz le liya',
          'maanga', 'maangaa', 'maang liya', 'maang ke liya',
          
          // Giving (when I owe)
          'dena hai', 'dene hai', 'deni hai', 'wapas karna hai',
          'chukana hai', 'ada karna hai', 'return karna hai',
          'main dene wala hu', 'main denaa hu',
          
          // Borrowed from (complete phrases)
          'se udhaar liya', 'se karz liya', 'se loan liya',
          'se maang liya', 'se maanga',
        ],
        'debt_owed_to_me': [
          // Lending - specific patterns only
          'udhaar diya', 'udhar diya', 'karz diya', 'qarz diya',
          'lent', 'loan diya', 'diya hua hai', 'de diya',
          
          // Getting back
          'lena hai', 'lene hai', 'leni hai', 'wapas lena hai',
          'milna hai', 'milne hai', 'milega', 'return milega',
          'mujhe lena hai', 'mujhe milna hai',
          
          // Gave to (complete phrases)
          'ko diya', 'ko diye', 'ko loan diya', 'ko udhaar diya',
          'ko karz diya', 'ko de diya',
        ],
      };
    } else if (language == 'mr') {
      return {
        'income': [
          // Earning
          'kamavale', 'kamavla', 'kamavli', 'kamavto', 'kamavtay',
          'milala', 'milale', 'mila', 'milel', 'milanar',
          'aala', 'aali', 'yeil', 'yet ahe',
          'prapt', 'prapt jhala', 'prapt zala',
          
          // Salary - STRONG INDICATORS
          'salary', 'paagar', 'vetann', 'mahinya',
          'income', 'utrpan', 'kamaayi',
          'bonus', 'incentive', 'commission',
          
          // Gifts - VERY STRONG INDICATORS
          'bhev', 'bhetvastu', 'inam', 'gift', 'tohfa',
          'bhev mila', 'gift mila', 'inam mila',
          
          // Payment
          'payment', 'paisa', 'rupaye', 'credited',
          
          // From family (income context)
          'baba pasun', 'aai pasun', 'dad pasun', 'mom pasun',
          'bhai pasun', 'bahin pasun', 'mitra pasun',
        ],
        'expense': [
          // Spending
          'kharch', 'kharcha', 'kharch kela', 'kharchale',
          'lavla', 'lavle', 'lavli', 'lavto',
          'dila', 'dili', 'dile', 'debit',
          
          // Buying
          'kharidla', 'kharidli', 'kharidlay', 'khareedle',
          'ghetla', 'ghetli', 'ghetle', 'gheyala',
          'buy', 'bought', 'purchase',
          
          // Paying
          'paid', 'payment', 'bhugtan kela',
          'ada kela', 'chukavla',
          
          // Using
          'spent', 'use kela', 'vapaar',
        ],
        'debt_i_owe': [
          // Borrowing - specific patterns only
          'pharaki gheyali', 'pharaki ghetle', 'pharaki ghetla',
          'karz gheyla', 'karz ghetla', 'qarz ghetla',
          'borrowed', 'loan ghetla', 'loan ghetle',
          'maangitla', 'maagitla', 'maang ghetla',
          
          // Giving back
          'dyaycha ahe', 'dyacha ahe', 'kadhaycha ahe',
          'return karaycha', 'phir karaycha', 'main dyaycha',
          
          // Borrowed from (complete phrases)
          'pasun pharaki ghetla', 'pasun karz ghetla', 'pasun loan ghetla',
          'kadun ghetla', 'kadun ghetle',
        ],
        'debt_owed_to_me': [
          // Lending - specific patterns only
          'pharaki dili', 'pharaki dila', 'pharaki dile',
          'karz dila', 'qarz dila', 'loan dila',
          'lent', 'dila ahe', 'de dila',
          
          // Getting back
          'ghyaycha ahe', 'ghyacha ahe', 'milaych ahe',
          'return milanar', 'phir milanar', 'mala ghyaycha',
          
          // Gave to (complete phrases)
          'la dila', 'la dili', 'la loan dila', 'la pharaki dila',
          'la karz dila', 'la de dila',
        ],
      };
    } else {
      return {
        'income': [
          // Earning verbs
          'earned', 'earn', 'earning', 'earns', 'income', 'incoming',
          'received', 'receive', 'receiving', 'receives', 
          'got', 'get', 'getting', 'gets',
          'made', 'make', 'making', 'makes',
          
          // Salary & Payment
          'salary', 'salaries', 'wage', 'wages', 'pay', 'paid', 'payment received',
          'credited', 'credit', 'deposit', 'deposited',
          
          // Types - STRONG INDICATORS
          'bonus', 'bonuses', 'incentive', 'commission', 'tip', 'tips',
          'profit', 'profits', 'gain', 'gains', 'revenue',
          'dividend', 'dividends', 'interest', 'interest earned',
          'refund', 'refunded', 'cashback', 'reward', 'rewards',
          
          // Gifts - VERY STRONG INDICATORS
          'gift', 'gifted', 'gift from', 'received gift', 'got gift',
          'prize', 'won', 'winning', 'award', 'awarded',
          
          // Source indicators (when it's income)
          'from dad', 'from mom', 'from parent', 'from family',
          'from friend', 'from relative', 'from uncle', 'from aunt',
          'from brother', 'from sister', 'from grandpa', 'from grandma',
        ],
        'expense': [
          // Spending verbs
          'spent', 'spend', 'spending', 'spends', 'expense', 'expenses',
          'paid', 'pay', 'paying', 'pays', 'payment', 'payments',
          'bought', 'buy', 'buying', 'buys', 'purchase', 'purchased', 'purchasing',
          'ordered', 'order', 'ordering', 'orders',
          'got', 'get', 'getting', 'took', 'take', 'taking',
          
          // Cost terms
          'cost', 'costs', 'costed', 'price', 'priced',
          'bill', 'billed', 'charge', 'charged', 'charges',
          'fee', 'fees', 'fare', 'fares',
          
          // Money movement
          'gave', 'give', 'giving', 'given',
          'debited', 'debit', 'withdrawn', 'withdraw',
          'used', 'use', 'using', 'utilized',
        ],
        'debt_i_owe': [
          // Borrowing - very specific patterns only
          'owe', 'owes', 'owed', 'owing', 'i owe',
          'borrowed', 'borrow', 'borrowing', 'borrows', 'borrowed from',
          'took loan', 'take loan', 'taken loan', 'taking loan', 'got loan',
          
          // Complete phrases only (not just "from")
          'loan from', 'borrowed from', 'took from', 'got from',
          
          // Specific debt phrases
          'gave to', 'give to', 'given to', 'giving to',
          'paid to', 'pay to', 'payment to',
          
          // Debt description
          'have to pay', 'need to pay', 'should pay', 'must pay',
          'have to return', 'need to return', 'should return',
          'in debt', 'indebted', 'liability', 'i have to give',
        ],
        'debt_owed_to_me': [
          // Lending - very specific patterns only
          'owes me', 'owe me', 'owed me', 'owing me',
          'lent', 'lend', 'lending', 'lends', 'lent to',
          'gave loan', 'give loan', 'given loan', 'giving loan',
          'loaned', 'loan to', 'loaned to',
          
          // Complete phrases only
          'borrowed from me', 'borrow from me', 'took from me',
          'took loan from me', 'loan from me', 'got loan from me',
          
          // Debt description
          'has to pay me', 'has to return', 'should pay me', 'should return',
          'will pay me', 'will return', 'promised to pay',
          'receivable', 'to receive', 'will receive', 'they owe',
        ],
      };
    }
  }

  /// Parse expense-specific details with smart category inference
  Map<String, dynamic> _parseExpenseDetails(String text, String language) {
    return {
      'category': _extractCategoryWithInference(text, language),
      'description': _cleanDescription(text),
    };
  }

  /// Enhanced category extraction with vague input handling + fuzzy matching
  String _extractCategoryWithInference(String text, String language) {
    final categoryMap = _getCategoryKeywords(language);
    final synonymMap = _getCategorySynonyms();
    
    // Step 1: Direct keyword matching
    for (var entry in categoryMap.entries) {
      for (var keyword in entry.value) {
        if (text.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }

    // Step 2: Fuzzy matching for misheard/typo keywords
    for (var entry in categoryMap.entries) {
      for (var keyword in entry.value) {
        final words = text.split(' ');
        for (var word in words) {
          if (word.length > 3 && _fuzzyMatch(word, keyword, threshold: 0.75)) {
            return entry.key;
          }
        }
      }
    }

    // Step 3: Synonym matching
    for (var entry in synonymMap.entries) {
      for (var synonym in entry.value) {
        if (text.contains(synonym.toLowerCase())) {
          return entry.key;
        }
      }
    }

    // Step 4: Contextual inference for vague inputs
    return _inferCategoryFromContext(text, language);
  }

  /// Get synonym mappings for better category detection
  Map<String, List<String>> _getCategorySynonyms() {
    return {
      'food': [
        'ordered', 'ate', 'eating', 'consumed', 'tasted', 'dined',
        'hungry', 'thirsty', 'delicious', 'yummy', 'tasty',
        'breakfast', 'brunch', 'lunch', 'dinner', 'supper',
        'appetizer', 'dessert', 'main course',
      ],
      'transport': [
        'travelled', 'traveling', 'commute', 'commuting', 'ride', 'riding',
        'drove', 'driving', 'flew', 'flying', 'booked',
        'journey', 'trip', 'distance',
      ],
      'shopping': [
        'purchased', 'buying', 'got', 'ordered online', 'delivery',
        'cart', 'checkout', 'payment', 'shipped',
      ],
      'entertainment': [
        'watched', 'watching', 'enjoyed', 'fun', 'relaxed',
        'weekend', 'holiday', 'celebrate', 'celebrating',
      ],
      'health': [
        'sick', 'ill', 'pain', 'ache', 'appointment',
        'prescription', 'diagnosed', 'therapy',
      ],
      'bills': [
        'due', 'payment', 'monthly', 'quarterly', 'annual',
        'service', 'utility', 'provider',
      ],
      'education': [
        'learning', 'studying', 'exam', 'test', 'homework',
        'assignment', 'project', 'research',
      ],
    };
  }

  Map<String, List<String>> _getCategoryKeywords(String language) {
    final base = {
      'food': [
        // ===== ENGLISH - EXTENSIVE =====
        // General eating terms
        'food', 'eat', 'ate', 'eaten', 'eating', 'eats', 'meal', 'meals', 'dining', 'dine', 'dined',
        'lunch', 'dinner', 'breakfast', 'brunch', 'supper', 'snack', 'snacks', 'snacking',
        'bite', 'bites', 'feast', 'buffet', 'course', 'appetizer', 'starter', 'main', 'dessert',
        'hungry', 'hunger', 'thirsty', 'thirst', 'crave', 'craving',
        
        // Venues
        'restaurant', 'cafe', 'cafeteria', 'canteen', 'mess', 'dhaba', 'hotel', 'eatery',
        'joint', 'outlet', 'stall', 'cart', 'vendor', 'street food', 'food court',
        'bakery', 'confectionery', 'sweet shop', 'juice bar', 'bar', 'pub', 'lounge',
        
        // Beverages - Hot
        'coffee', 'cappuccino', 'latte', 'espresso', 'americano', 'mocha', 'macchiato',
        'tea', 'green tea', 'black tea', 'chai', 'masala chai', 'lemon tea', 'iced tea',
        'hot chocolate', 'cocoa', 'soup', 'broth',
        
        // Beverages - Cold
        'drink', 'drinks', 'beverage', 'beverages', 'water', 'mineral water', 'soda water',
        'juice', 'fresh juice', 'orange juice', 'apple juice', 'mango juice', 'pomegranate',
        'smoothie', 'milkshake', 'shake', 'lassi', 'buttermilk', 'chaas',
        'soda', 'cola', 'pepsi', 'coke', 'sprite', 'fanta', 'limca', 'thums up',
        'energy drink', 'red bull', 'monster', 'gatorade',
        
        // Alcoholic
        'beer', 'wine', 'alcohol', 'whiskey', 'vodka', 'rum', 'gin', 'brandy', 'scotch',
        'cocktail', 'mocktail', 'champagne', 'sangria', 'tequila', 'shots',
        
        // Indian Main Dishes
        'biryani', 'pulao', 'fried rice', 'rice', 'jeera rice', 'lemon rice',
        'dal', 'daal', 'tadka', 'rajma', 'chole', 'chana', 'sambar',
        'curry', 'gravy', 'masala', 'korma', 'tikka', 'tandoori', 'butter chicken',
        'paneer', 'palak paneer', 'shahi paneer', 'paneer tikka', 'kadai paneer',
        'roti', 'chapati', 'naan', 'paratha', 'kulcha', 'puri', 'bhatura',
        'dosa', 'idli', 'vada', 'uttapam', 'appam', 'pongal',
        
        // Indian Snacks
        'samosa', 'pakora', 'bhaji', 'kachori', 'vada pav', 'pav bhaji', 'chaat',
        'golgappa', 'pani puri', 'bhel puri', 'sev puri', 'dahi puri',
        'aloo tikki', 'cutlet', 'patty', 'rolls', 'spring roll',
        'momos', 'dimsum', 'dumplings', 'wontons',
        
        // Fast Food & International
        'pizza', 'margherita', 'pepperoni', 'cheesy', 'thin crust', 'stuffed crust',
        'burger', 'cheeseburger', 'veggie burger', 'chicken burger', 'beef burger',
        'sandwich', 'club sandwich', 'grilled sandwich', 'toast', 'sub',
        'fries', 'french fries', 'wedges', 'nuggets', 'popcorn chicken',
        'pasta', 'spaghetti', 'macaroni', 'penne', 'alfredo', 'arrabiata',
        'noodles', 'chowmein', 'hakka', 'schezwan', 'manchurian',
        'fried chicken', 'grilled chicken', 'roast chicken', 'chicken wings',
        'taco', 'burrito', 'quesadilla', 'nachos', 'wrap', 'kebab', 'shawarma',
        
        // Proteins
        'chicken', 'mutton', 'lamb', 'goat', 'beef', 'pork', 'fish', 'prawn', 'shrimp',
        'egg', 'eggs', 'omelette', 'scrambled', 'boiled egg', 'fried egg', 'poached',
        'meat', 'seafood', 'crab', 'lobster', 'salmon', 'tuna',
        
        // Vegetables & Fruits
        'vegetables', 'veggies', 'salad', 'fruits', 'fresh',
        'potato', 'aloo', 'tomato', 'tamatar', 'onion', 'pyaz', 'garlic', 'ginger',
        'carrot', 'beans', 'peas', 'capsicum', 'brinjal', 'cauliflower', 'cabbage',
        'spinach', 'palak', 'methi', 'bhindi', 'okra', 'cucumber', 'radish',
        'apple', 'banana', 'orange', 'mango', 'grapes', 'watermelon', 'papaya',
        'strawberry', 'pineapple', 'kiwi', 'pomegranate', 'lychee', 'guava',
        
        // Dairy & Bakery
        'milk', 'dudh', 'cream', 'butter', 'ghee', 'cheese', 'cheddar', 'mozzarella',
        'yogurt', 'curd', 'dahi', 'raita', 'paneer', 'cottage cheese',
        'bread', 'brown bread', 'white bread', 'bun', 'pav', 'croissant', 'baguette',
        'cake', 'pastry', 'cupcake', 'muffin', 'brownie', 'donut', 'eclair',
        'cookies', 'biscuits', 'crackers', 'wafers', 'rusks',
        
        // Sweets & Desserts
        'sweet', 'sweets', 'mithai', 'dessert', 'desserts',
        'ice cream', 'gelato', 'kulfi', 'sundae', 'cone', 'scoop',
        'chocolate', 'candy', 'toffee', 'lollipop', 'gum', 'mint',
        'gulab jamun', 'rasgulla', 'jalebi', 'ladoo', 'barfi', 'halwa',
        'kheer', 'payasam', 'pudding', 'custard', 'mousse', 'tiramisu',
        
        // Snacks & Munchies
        'chips', 'wafers', 'namkeen', 'mixture', 'sev', 'bhujia',
        'popcorn', 'corn', 'peanuts', 'cashew', 'almonds', 'nuts',
        'crackers', 'rusk', 'toast', 'breadsticks',
        
        // Groceries & Staples
        'grocery', 'groceries', 'ration', 'provisions', 'staples',
        'rice', 'wheat', 'flour', 'atta', 'maida', 'besan',
        'oil', 'cooking oil', 'mustard oil', 'olive oil', 'coconut oil',
        'salt', 'sugar', 'jaggery', 'gur', 'honey', 'spices', 'masala',
        
        // ===== HINDI - EXTENSIVE =====
        // General
        'khana', 'khaana', 'bhojan', 'aahar', 'khaya', 'khai', 'khate', 'khati',
        'nashta', 'naashta', 'breakfast', 'subah ka khana',
        'dopahar ka khana', 'raat ka khana', 'khane', 'khao', 'khaenge',
        'peena', 'piya', 'piye', 'piyenge', 'pite', 'pi',
        
        // Beverages
        'chai', 'chay', 'cha', 'coffee', 'kafi', 'paani', 'pani', 'jal',
        'dudh', 'doodh', 'lassi', 'chaas', 'sharbat', 'juice', 'rus',
        'thanda', 'garam', 'thandaa pani', 'garam pani',
        
        // Main Food
        'roti', 'chapati', 'phulka', 'paratha', 'puri', 'bhatura',
        'chawal', 'bhat', 'pulao', 'biryani', 'khichdi',
        'daal', 'dal', 'rajma', 'chole', 'chana', 'kadhi',
        'sabzi', 'subzi', 'tarkari', 'bhaji', 'bhujia',
        'paneer', 'matar', 'aloo', 'gobi', 'baingan',
        
        // Snacks
        'namkeen', 'chivda', 'mixture', 'sev', 'gathiya',
        'samosa', 'kachori', 'pakoda', 'pakora', 'bhajiya',
        'vada', 'vadapav', 'pavbhaji', 'misal', 'poha',
        'chaat', 'golgappa', 'panipuri', 'bhelpuri', 'dahipuri',
        
        // Sweets
        'mithai', 'meetha', 'dessert', 'sweet',
        'gulab jamun', 'rasgulla', 'jalebi', 'laddu', 'ladoo',
        'barfi', 'burfi', 'halwa', 'halva', 'kheer', 'sewai',
        'peda', 'kalakand', 'mysore pak', 'gajar halwa',
        
        // Street Food
        'momos', 'roll', 'frankie', 'tikki', 'cutlet',
        'chowmein', 'manchurian', 'fried rice',
        
        // Vegetables (Hindi)
        'tamatar', 'pyaz', 'pyaaz', 'lehsun', 'adrak',
        'gajar', 'matar', 'sem', 'shimla mirch', 'baingan',
        'phool gobi', 'patta gobi', 'palak', 'methi', 'bhindi',
        
        // Fruits (Hindi)
        'phal', 'seb', 'kela', 'santara', 'aam', 'angoor',
        'tarbooj', 'papita', 'ananas', 'nashpati', 'amrud',
        
        // ===== MARATHI - EXTENSIVE =====
        // General
        'jevan', 'jewan', 'khaanya', 'khanya', 'khalle', 'khalli',
        'nashta', 'snacks', 'khayala', 'khayachi',
        'pinya', 'pinyala', 'piyala', 'pili',
        
        // Beverages
        'cha', 'chai', 'kafi', 'pani', 'paani', 'jal',
        'dudh', 'doodh', 'takk', 'taak', 'sarbat',
        
        // Main Food
        'bhat', 'bhaat', 'tandool', 'pulao', 'biryani',
        'dal', 'varan', 'aamti', 'katachi amti',
        'bhaji', 'bhajji', 'patal bhaji', 'zunka',
        'roti', 'chapati', 'poli', 'bhakri', 'puran poli',
        
        // Snacks
        'vada', 'batata vada', 'misal pav', 'pav bhaji',
        'poha', 'pohay', 'upma', 'uppit', 'shira',
        'kachori', 'samosa', 'pakoda', 'bhajiya',
        'chakli', 'chivda', 'mixture', 'shev',
        
        // Sweets
        'goad', 'modak', 'puran poli', 'shrikhand', 'basundi',
        'gulab jamun', 'jalebi', 'ladoo', 'barfi',
        'kheer', 'payasam', 'halwa',
        
        // Vegetables (Marathi)
        'tomato', 'kanda', 'lasun', 'ale', 'gajar',
        'vatana', 'beans', 'capsicum', 'vangi', 'kobichi',
        'palak', 'methi', 'bhendi', 'kakdi', 'mula',
        
        // Fruits (Marathi)
        'phal', 'safarchand', 'keli', 'santra', 'amba', 'draksh',
        'kalingar', 'papai', 'peru', 'jambul',
        
        // ===== COMMON BRANDS & CHAINS =====
        'mcdonalds', 'mcd', 'kfc', 'dominos', 'pizza hut', 'subway', 'burger king',
        'starbucks', 'cafe coffee day', 'ccd', 'barista', 'costa coffee',
        'haldirams', 'bikanervala', 'sagar ratna', 'saravana bhavan',
        'swiggy', 'zomato', 'uber eats', 'dunzo', 'fresh menu',
        'baskin robbins', 'naturals', 'amul', 'mother dairy',
        'britannia', 'parle', 'nestle', 'cadbury', 'kitkat',
      ],
      'transport': [
        // ===== ENGLISH - EXTENSIVE =====
        // General terms
        'travel', 'traveling', 'travelled', 'traveling', 'trip', 'journey', 'commute',
        'transport', 'transportation', 'conveyance', 'ride', 'riding', 'drove', 'drive',
        'went', 'going', 'go', 'come', 'coming', 'came', 'return', 'returning',
        'pickup', 'drop', 'dropoff', 'departure', 'arrival',
        
        // Public Transport
        'bus', 'minibus', 'shuttle', 'coach', 'double decker', 'public bus', 'local bus',
        'train', 'railway', 'metro', 'subway', 'monorail', 'tram', 'local train', 'express',
        'station', 'platform', 'terminal', 'depot', 'stand',
        
        // Auto/Taxi
        'taxi', 'cab', 'auto', 'rickshaw', 'autorickshaw', 'three wheeler', 'tuk tuk',
        'uber', 'ola', 'rapido', 'meru', 'cool cab', 'careem',
        
        // Private Vehicles
        'car', 'vehicle', 'automobile', 'sedan', 'suv', 'hatchback',
        'bike', 'motorcycle', 'motorbike', 'two wheeler', 'scooter', 'scooty',
        'cycle', 'bicycle', 'cycling',
        
        // Air Travel
        'flight', 'airplane', 'plane', 'aircraft', 'air travel', 'flying', 'flew',
        'airport', 'domestic', 'international', 'airways', 'airlines',
        'indigo', 'spicejet', 'air india', 'vistara', 'go air',
        
        // Other Transport
        'ship', 'boat', 'ferry', 'cruise', 'yacht',
        'ambulance', 'emergency',
        
        // Fuel & Maintenance
        'petrol', 'diesel', 'fuel', 'gas', 'cng', 'lpg', 'electric',
        'refuel', 'refueling', 'tank', 'full tank', 'liter', 'litre',
        'oil', 'engine oil', 'lubricant', 'coolant',
        'service', 'servicing', 'maintenance', 'repair', 'garage', 'workshop',
        'puncture', 'tyre', 'tire', 'wheel', 'brake', 'clutch',
        
        // Charges & Fees
        'fare', 'ticket', 'booking', 'reservation', 'seat',
        'toll', 'toll tax', 'highway', 'expressway',
        'parking', 'parking fee', 'valet', 'lot',
        'pass', 'monthly pass', 'season ticket', 'smart card',
        
        // ===== HINDI - EXTENSIVE =====
        // General
        'yatra', 'safar', 'pravas', 'chalana', 'chalna', 'chala', 'chale', 'chali',
        'jaana', 'jana', 'gaya', 'gayi', 'jaye', 'jayenge',
        'aana', 'aaya', 'aayi', 'aayenge', 'wapas', 'lautna',
        'sawari', 'sawaari', 'transport',
        
        // Vehicles
        'gaadi', 'gadi', 'gari', 'vehicle', 'vahaan',
        'bus', 'bas', 'local bus', 'private bus',
        'train', 'rel', 'rail', 'gaddi', 'metro',
        'auto', 'rikshaw', 'rickshaw', 'thela',
        'taxi', 'cab', 'uber', 'ola',
        'car', 'kaar', 'gaadi', 'motor',
        'bike', 'motorcycle', 'bullet', 'activa',
        'cycle', 'saikal', 'bicycle',
        'flight', 'hawai jahaj', 'viman', 'plane',
        
        // Fuel
        'petrol', 'diesel', 'tel', 'fuel', 'cng',
        'bharwana', 'tank full', 'full karwana',
        
        // Charges
        'kiraya', 'kiraaya', 'bhada', 'ticket',
        'parking', 'toll', 'service charge',
        
        // ===== MARATHI - EXTENSIVE =====
        // General
        'pravas', 'pravasa', 'safar', 'mandali',
        'janya', 'gelo', 'geli', 'jayacha', 'jayachi',
        'yena', 'ala', 'ali', 'yayacha', 'yayachi',
        'sawari', 'vahan',
        
        // Vehicles
        'gaadi', 'gadi', 'vehicle',
        'bus', 'local', 'st bus',
        'train', 'rel', 'rail', 'local train', 'metro',
        'rickshaw', 'rikshaw', 'auto',
        'taxi', 'cab', 'uber', 'ola',
        'car', 'motor', 'gaadi',
        'bike', 'motorcycle', 'dhu dhu',
        'cycle', 'saikal',
        'flight', 'vimaan', 'hawai',
        
        // Fuel
        'petrol', 'diesel', 'tel', 'fuel',
        'bharna', 'full tank',
        
        // Charges
        'bhade', 'bhada', 'kiraya', 'ticket',
        'parking', 'toll',
        
        // ===== BRANDS & SERVICES =====
        'uber', 'ola', 'rapido', 'bounce', 'vogo', 'yulu',
        'meru', 'mega cabs', 'easy cabs', 'quick ride',
        'indian railways', 'irctc', 'dmrc', 'bmtc', 'best', 'msrtc',
        'makemytrip', 'goibibo', 'cleartrip', 'yatra', 'ixigo',
      ],
      'shopping': [
        // ===== ENGLISH - EXTENSIVE =====
        // General
        'shopping', 'shop', 'shopped', 'bought', 'buy', 'buying', 'purchase', 'purchased',
        'order', 'ordered', 'ordering', 'delivery', 'delivered', 'shipping', 'shipped',
        'store', 'mall', 'market', 'bazaar', 'outlet', 'showroom', 'boutique',
        'online', 'offline', 'retail', 'wholesale', 'sale', 'discount', 'offer',
        'cart', 'checkout', 'payment', 'paid', 'bill',
        
        // Clothing & Fashion
        'clothes', 'clothing', 'apparel', 'garment', 'wear', 'outfit', 'fashion',
        'dress', 'gown', 'frock', 'skirt', 'top', 'blouse', 'kurti', 'kurta',
        'shirt', 'tshirt', 't-shirt', 'polo', 'formal', 'casual',
        'pant', 'pants', 'jeans', 'trousers', 'chinos', 'leggings', 'palazzo',
        'shorts', 'capri', 'joggers', 'track pants',
        'saree', 'sari', 'lehnga', 'salwar', 'churidar', 'dupatta', 'stole',
        'jacket', 'blazer', 'coat', 'sweater', 'hoodie', 'sweatshirt', 'cardigan',
        'inner wear', 'undergarments', 'lingerie', 'bra', 'panty', 'vest',
        'nightwear', 'pajama', 'nightdress', 'gown',
        
        // Footwear
        'shoes', 'footwear', 'sneakers', 'sports shoes', 'running shoes',
        'sandals', 'slippers', 'floaters', 'flip flops', 'chappals',
        'formal shoes', 'loafers', 'boots', 'heels', 'stilettos', 'wedges',
        'jutis', 'kolhapuri',
        
        // Accessories
        'accessories', 'bag', 'handbag', 'purse', 'clutch', 'sling bag', 'backpack',
        'wallet', 'belt', 'watch', 'smartwatch', 'bracelet', 'chain', 'necklace',
        'earrings', 'ring', 'bangles', 'jewelry', 'jewellery', 'ornaments',
        'sunglasses', 'goggles', 'specs', 'spectacles', 'frames',
        'hat', 'cap', 'scarf', 'tie', 'bowtie',
        
        // Electronics & Gadgets
        'electronics', 'gadgets', 'device', 'appliance',
        'mobile', 'phone', 'smartphone', 'iphone', 'samsung', 'oneplus', 'realme',
        'laptop', 'notebook', 'macbook', 'dell', 'hp', 'lenovo', 'asus',
        'computer', 'pc', 'desktop', 'monitor', 'keyboard', 'mouse', 'webcam',
        'tablet', 'ipad', 'tab', 'kindle', 'ereader',
        'headphones', 'earphones', 'earbuds', 'airpods', 'boat', 'jbl',
        'speaker', 'bluetooth speaker', 'soundbar', 'home theatre',
        'charger', 'adapter', 'cable', 'usb', 'type c', 'lightning',
        'powerbank', 'battery', 'memory card', 'pendrive', 'hard disk', 'ssd',
        'camera', 'dslr', 'gopro', 'action camera', 'tripod',
        'tv', 'television', 'smart tv', 'led', 'oled', 'qled',
        'ac', 'air conditioner', 'cooler', 'fan', 'heater',
        'refrigerator', 'fridge', 'washing machine', 'microwave', 'oven',
        
        // Home & Living
        'furniture', 'sofa', 'bed', 'mattress', 'pillow', 'cushion',
        'table', 'chair', 'desk', 'shelf', 'rack', 'cabinet', 'wardrobe',
        'curtain', 'blinds', 'carpet', 'rug', 'mat',
        'bedsheet', 'blanket', 'quilt', 'towel', 'napkin',
        'utensils', 'crockery', 'cutlery', 'plates', 'bowl', 'glass', 'cup',
        'decor', 'decoration', 'painting', 'frame', 'vase', 'showpiece',
        
        // Books & Stationery
        'books', 'book', 'novel', 'magazine', 'newspaper', 'comics',
        'stationery', 'pen', 'pencil', 'eraser', 'sharpener', 'ruler',
        'notebook', 'register', 'diary', 'planner', 'calendar',
        'colors', 'crayons', 'markers', 'sketch', 'drawing',
        
        // Sports & Fitness
        'sports', 'fitness', 'gym equipment', 'weights', 'dumbbell',
        'cricket', 'bat', 'ball', 'football', 'basketball', 'tennis',
        'badminton', 'racket', 'shuttlecock', 'net',
        
        // ===== HINDI - EXTENSIVE =====
        // General
        'kharidari', 'shopping', 'kharida', 'kharide', 'khareedna',
        'liya', 'liya', 'le', 'lena', 'lenge', 'legi',
        'order', 'mangwaya', 'delivery',
        'dukan', 'shop', 'mall', 'bazaar', 'market',
        
        // Clothing
        'kapde', 'kapda', 'vastra', 'poshak',
        'shirt', 'tshirt', 'kamiz', 'kurta', 'kurti',
        'pant', 'jeans', 'pajama', 'salwar', 'churidar',
        'saree', 'sari', 'dupatta', 'lehnga', 'ghagra',
        'jacket', 'sweater', 'cardigan',
        
        // Footwear
        'joote', 'jutay', 'chappal', 'sandal', 'shoes',
        
        // Accessories
        'bag', 'jhola', 'wallet', 'purse', 'basta',
        'ghadi', 'watch', 'chashma', 'goggles',
        'gehne', 'jewelry', 'chain', 'bracelet', 'ring',
        
        // Electronics
        'mobile', 'phone', 'laptop', 'computer',
        'headphone', 'earphone', 'speaker',
        'tv', 'television', 'ac', 'fridge', 'cooler',
        
        // ===== MARATHI - EXTENSIVE =====
        // General
        'kharedi', 'shopping', 'kharidla', 'kharidli', 'kharidlay',
        'ghenyala', 'ghetle', 'ghetla', 'ghetli',
        'order', 'delivery',
        'dukan', 'shop', 'mall', 'bazaar',
        
        // Clothing
        'kapde', 'vastra', 'pehrav',
        'shirt', 'tshirt', 'kurta', 'kurti',
        'pant', 'jeans', 'pyjama', 'salwar',
        'saadi', 'lugad', 'dupatta', 'lehnga',
        'jacket', 'sweater',
        
        // Footwear
        'boot', 'chappal', 'sandal', 'shoes',
        
        // Accessories
        'pishvi', 'bag', 'wallet', 'ghadi', 'chashma',
        'daginay', 'jewelry', 'chain',
        
        // Electronics
        'mobile', 'phone', 'laptop', 'computer',
        'tv', 'ac', 'fridge',
        
        // ===== BRANDS & PLATFORMS =====
        'amazon', 'flipkart', 'myntra', 'ajio', 'meesho', 'snapdeal',
        'nykaa', 'purplle', 'tata cliq', 'shoppers stop', 'lifestyle',
        'zara', 'h&m', 'uniqlo', 'levis', 'nike', 'adidas', 'puma',
        'max', 'westside', 'reliance trends', 'pantaloons',
        'big bazaar', 'dmart', 'more', 'reliance fresh',
      ],
      'entertainment': [
        // ===== ENGLISH - EXTENSIVE =====
        // Movies & Cinema
        'movie', 'movies', 'film', 'films', 'cinema', 'picture',
        'theatre', 'theater', 'multiplex', 'pvr', 'inox', 'cinepolis', 'carnival',
        'show', 'screening', 'premiere', 'matinee', 'night show',
        'ticket', 'booking', 'seat', 'recliner', 'balcony', 'popcorn',
        
        // Gaming
        'game', 'games', 'gaming', 'video game', 'console', 'arcade',
        'ps5', 'playstation', 'xbox', 'nintendo', 'switch',
        'pc gaming', 'steam', 'epic games',
        
        // Events & Celebrations
        'party', 'parties', 'celebration', 'celebrate', 'bash',
        'birthday', 'anniversary', 'wedding', 'reception', 'function',
        'event', 'gathering', 'get together', 'reunion', 'meet',
        'concert', 'music concert', 'live show', 'gig', 'performance',
        'play', 'drama', 'theatre', 'standup', 'comedy show',
        'exhibition', 'expo', 'fair', 'carnival', 'festival',
        
        // Outings & Recreation
        'outing', 'hangout', 'hang out', 'chill', 'fun', 'enjoyment',
        'picnic', 'trip', 'excursion', 'day out', 'weekend',
        'vacation', 'holiday', 'holidays', 'tour', 'touring', 'sightseeing',
        'beach', 'hill station', 'resort', 'hotel', 'stay',
        'amusement park', 'theme park', 'water park', 'adventure park',
        'zoo', 'aquarium', 'museum', 'gallery', 'planetarium',
        
        // Streaming & Subscriptions
        'netflix', 'amazon prime', 'prime video', 'hotstar', 'disney',
        'youtube', 'youtube premium', 'youtube music',
        'spotify', 'gaana', 'jiosaavn', 'wynk', 'apple music',
        'subscription', 'membership', 'premium', 'plan',
        'streaming', 'ott', 'web series', 'series', 'season', 'episode',
        
        // Music & Dance
        'music', 'song', 'songs', 'album', 'playlist',
        'dance', 'dancing', 'club', 'disco', 'pub', 'bar', 'lounge',
        'dj', 'band', 'orchestra', 'karaoke',
        
        // Sports & Activities
        'sports', 'match', 'stadium', 'arena', 'tournament',
        'cricket', 'football', 'tennis', 'badminton', 'bowling',
        'adventure', 'trekking', 'hiking', 'camping', 'rafting',
        
        // ===== HINDI - EXTENSIVE =====
        // Movies
        'picture', 'film', 'cinema', 'tasveer',
        'theatre', 'talkies', 'pvr', 'inox',
        'ticket', 'show', 'dekhna', 'dekhi', 'dekha',
        
        // Entertainment
        'manoranjan', 'masti', 'mazaa', 'maja', 'maza',
        'party', 'function', 'karyakram', 'samaroh',
        'birthday', 'janamdin', 'saalgirah',
        'shaadi', 'wedding', 'vivah',
        
        // Outings
        'ghumna', 'ghoomna', 'picnic', 'trip', 'yatra',
        'chutti', 'holiday', 'vacation', 'ghumne',
        
        // Subscriptions
        'netflix', 'prime', 'hotstar',
        'spotify', 'gaana', 'music',
        
        // ===== MARATHI - EXTENSIVE =====
        // Movies
        'picture', 'cinema', 'film', 'chitra',
        'theatre', 'talkies', 'pvr', 'inox',
        'ticket', 'show', 'baghayla', 'bagitla',
        
        // Entertainment
        'manoranjan', 'majha', 'maza', 'masti',
        'party', 'function', 'karyakram',
        'vadhdivsacha', 'birthday',
        'lagna', 'wedding', 'vivah',
        
        // Outings
        'phirnya', 'picnic', 'trip', 'pravas',
        'suttee', 'holiday', 'vacation',
        
        // Subscriptions
        'netflix', 'prime', 'hotstar',
        'spotify', 'gaana',
      ],
      'health': [
        // ===== ENGLISH - EXTENSIVE =====
        // Medical General
        'medical', 'medicine', 'medication', 'drug', 'pharmacy', 'chemist',
        'doctor', 'physician', 'specialist', 'consultant', 'surgeon',
        'hospital', 'clinic', 'dispensary', 'nursing home', 'medical center',
        'appointment', 'consultation', 'checkup', 'visit', 'followup',
        'emergency', 'casualty', 'ambulance', 'icu', 'admit', 'admission',
        
        // Medicines & Treatment
        'pills', 'tablets', 'capsules', 'syrup', 'suspension', 'drops',
        'injection', 'shot', 'vaccine', 'vaccination', 'immunization',
        'prescription', 'dosage', 'course', 'antibiotic', 'painkiller',
        'treatment', 'therapy', 'healing', 'cure', 'remedy',
        'surgery', 'operation', 'procedure', 'transplant',
        
        // Tests & Diagnostics
        'test', 'tests', 'blood test', 'urine test', 'stool test',
        'scan', 'xray', 'x-ray', 'mri', 'ct scan', 'ultrasound', 'sonography',
        'ecg', 'eeg', 'endoscopy', 'biopsy', 'screening',
        'lab', 'laboratory', 'pathology', 'radiology', 'diagnostics',
        
        // Specializations
        'dental', 'dentist', 'teeth', 'tooth', 'cavity', 'filling', 'root canal',
        'eye', 'optician', 'ophthalmologist', 'vision', 'glasses', 'lens',
        'skin', 'dermatologist', 'dermatology', 'hair', 'acne',
        'orthopedic', 'ortho', 'bone', 'fracture', 'joint', 'spine',
        'cardiology', 'cardiologist', 'heart', 'bp', 'ecg',
        'gynecology', 'gynecologist', 'pregnancy', 'delivery', 'maternity',
        'pediatric', 'pediatrician', 'child', 'baby', 'infant',
        'ent', 'ear', 'nose', 'throat', 'hearing',
        'neurologist', 'neurology', 'brain', 'nerve', 'migraine',
        'psychiatrist', 'psychology', 'counseling', 'therapy', 'mental health',
        
        // Fitness & Wellness
        'gym', 'fitness', 'health', 'wellness', 'workout', 'exercise',
        'yoga', 'meditation', 'pranayam', 'asana',
        'zumba', 'aerobics', 'crossfit', 'pilates', 'spinning',
        'trainer', 'coach', 'instructor', 'membership', 'subscription',
        'protein', 'supplement', 'vitamins', 'minerals', 'nutrition',
        'diet', 'dietician', 'nutritionist', 'weight loss', 'weight gain',
        'massage', 'spa', 'physiotherapy', 'physio', 'rehabilitation',
        
        // Ailments & Symptoms
        'sick', 'ill', 'illness', 'disease', 'condition', 'disorder',
        'pain', 'ache', 'fever', 'cold', 'cough', 'flu', 'infection',
        'headache', 'migraine', 'stomachache', 'backache', 'bodyache',
        'injury', 'wound', 'cut', 'bruise', 'sprain', 'strain',
        
        // ===== HINDI - EXTENSIVE =====
        // Medical
        'davai', 'dawa', 'dawai', 'aushadh', 'medicine',
        'daktar', 'doctor', 'vaidya', 'hakim',
        'hospital', 'aspatal', 'clinic', 'dawakhana',
        'ilaj', 'upchar', 'chikitsa', 'treatment',
        
        // Tests
        'test', 'janch', 'parikshan', 'checkup',
        'xray', 'scan', 'blood test', 'khoon ki janch',
        
        // Fitness
        'gym', 'vyayam', 'kasrat', 'exercise',
        'yoga', 'dhyan', 'meditation',
        
        // Ailments
        'bimar', 'bimari', 'rog', 'beemari',
        'dard', 'pain', 'bukhar', 'fever', 'jukham', 'khansi',
        
        // ===== MARATHI - EXTENSIVE =====
        // Medical
        'aushadh', 'dava', 'dawai', 'medicine',
        'doctor', 'vaidya', 'hakim',
        'hospital', 'rugnalaya', 'clinic',
        'upchar', 'treatment', 'ilaj',
        
        // Tests
        'test', 'tapaasni', 'checkup',
        'xray', 'scan', 'blood test',
        
        // Fitness
        'gym', 'vyayam', 'exercise', 'kasrat',
        'yoga', 'dhyan',
        
        // Ailments
        'ajar', 'aajar', 'rog', 'illness',
        'vedana', 'dard', 'pain', 'taap', 'fever', 'khokla', 'cough',
      ],
      'bills': [
        // ===== ENGLISH - EXTENSIVE =====
        // General
        'bill', 'bills', 'payment', 'pay', 'paid', 'paying',
        'due', 'dues', 'outstanding', 'pending', 'arrears',
        'monthly', 'quarterly', 'annual', 'yearly', 'installment', 'emi',
        
        // Utilities
        'electricity', 'electric', 'power', 'current', 'bijli', 'light',
        'water', 'pani', 'jal', 'water supply', 'municipal',
        'gas', 'cooking gas', 'lpg', 'cylinder', 'piped gas',
        
        // Telecom
        'mobile', 'phone', 'telephone', 'landline', 'broadband',
        'internet', 'wifi', 'wi-fi', 'data', 'connection',
        'recharge', 'prepaid', 'postpaid', 'plan', 'pack',
        'airtel', 'jio', 'vi', 'vodafone', 'idea', 'bsnl',
        
        // Housing
        'rent', 'rental', 'lease', 'kiraya', 'bhada',
        'maintenance', 'society', 'society maintenance', 'housing',
        'property tax', 'house tax', 'municipal tax',
        
        // Subscriptions
        'subscription', 'membership', 'renewal', 'premium',
        'netflix', 'amazon', 'hotstar', 'spotify', 'youtube',
        
        // Financial
        'loan', 'emi', 'installment', 'repayment', 'mortgage',
        'home loan', 'car loan', 'personal loan', 'education loan',
        'insurance', 'life insurance', 'health insurance', 'vehicle insurance',
        'policy', 'premium', 'coverage',
        'tax', 'income tax', 'gst', 'service tax',
        
        // Services
        'dtth', 'cable', 'dish tv', 'tata sky', 'airtel digital',
        'newspaper', 'magazine', 'delivery',
        'cleaning', 'maid', 'servant', 'cook', 'driver',
        
        // ===== HINDI - EXTENSIVE =====
        'bill', 'bhugtan', 'payment', 'ada', 'chukana',
        'bijli', 'light', 'electricity', 'current',
        'pani', 'paani', 'jal', 'water',
        'gas', 'cylinder', 'cooking gas',
        'kiraya', 'bhada', 'rent', 'masikaana',
        'phone', 'mobile', 'recharge',
        'internet', 'wifi', 'broadband',
        'loan', 'karz', 'udhaar', 'emi',
        'bima', 'insurance', 'policy',
        'tax', 'kar',
        
        // ===== MARATHI - EXTENSIVE =====
        'bill', 'payment', 'bhugtan', 'ada',
        'vij', 'light', 'electricity',
        'pani', 'paani', 'water',
        'gas', 'cylinder',
        'bhade', 'bhada', 'kiraya', 'rent',
        'phone', 'mobile', 'recharge',
        'internet', 'wifi',
        'loan', 'karz', 'emi',
        'vima', 'insurance',
        'kar', 'tax',
      ],
      'education': [
        // ===== ENGLISH - EXTENSIVE =====
        // Institutions
        'education', 'school', 'college', 'university', 'institute', 'academy',
        'coaching', 'tuition', 'classes', 'training', 'course',
        'kindergarten', 'nursery', 'primary', 'secondary', 'higher secondary',
        
        // Fees & Expenses
        'fees', 'fee', 'admission', 'registration', 'enrollment',
        'tuition fee', 'exam fee', 'library fee', 'lab fee',
        'scholarship', 'donation', 'contribution',
        
        // Study Materials
        'books', 'book', 'textbook', 'notebook', 'register', 'diary',
        'guide', 'reference', 'notes', 'study material',
        'stationery', 'pen', 'pencil', 'eraser', 'sharpener', 'ruler',
        'colors', 'crayons', 'markers', 'highlighter',
        'bag', 'school bag', 'backpack', 'lunchbox', 'water bottle',
        'uniform', 'dress', 'shoes', 'tie', 'belt', 'socks',
        
        // Academic
        'exam', 'examination', 'test', 'quiz', 'assessment', 'evaluation',
        'assignment', 'homework', 'project', 'practical', 'lab work',
        'semester', 'term', 'annual', 'final', 'midterm',
        'result', 'marks', 'grades', 'percentage', 'cgpa',
        'certificate', 'degree', 'diploma', 'course completion',
        
        // Subjects & Activities
        'study', 'studying', 'learning', 'reading', 'writing',
        'maths', 'science', 'english', 'hindi', 'history', 'geography',
        'physics', 'chemistry', 'biology', 'computer', 'coding',
        'sports', 'games', 'arts', 'craft', 'music', 'dance',
        'competition', 'contest', 'debate', 'quiz', 'olympiad',
        
        // Online Learning
        'online class', 'zoom', 'google meet', 'virtual class',
        'elearning', 'udemy', 'coursera', 'byju', 'unacademy',
        
        // ===== HINDI - EXTENSIVE =====
        'shiksha', 'padhai', 'padhna', 'likhna',
        'school', 'vidyalaya', 'paaṭhshaala',
        'college', 'mahavidyalaya', 'university', 'vishwavidyalaya',
        'coaching', 'tuition', 'class',
        'fees', 'shulk', 'donation',
        'kitab', 'kitaab', 'book', 'pustak',
        'kopi', 'notebook', 'register', 'diary',
        'bag', 'basta', 'jhola',
        'uniform', 'dress', 'joote',
        'exam', 'pariksha', 'test', 'imtihaan',
        'homework', 'assignment', 'grahkarya',
        'result', 'natija', 'marks', 'ank',
        
        // ===== MARATHI - EXTENSIVE =====
        'shikshan', 'abhyas', 'vaachan', 'lihaan',
        'school', 'shala', 'shaala',
        'college', 'mahavidyalaya', 'vishwavidyalaya',
        'coaching', 'tuition', 'class', 'varg',
        'fees', 'shulk', 'donation',
        'pustak', 'book', 'kitaab',
        'vahi', 'notebook', 'register',
        'pishvi', 'bag', 'basta',
        'uniform', 'dress', 'boot',
        'pariksha', 'exam', 'test',
        'homework', 'assignment',
        'result', 'marks', 'gunn',
      ],
      'personal': [
        // ===== ENGLISH - EXTENSIVE =====
        // Grooming & Beauty
        'personal', 'grooming', 'beauty', 'self care', 'care',
        'salon', 'parlour', 'parlor', 'spa', 'wellness center',
        'haircut', 'hair cut', 'trim', 'style', 'styling', 'blow dry',
        'hair color', 'coloring', 'highlights', 'bleach', 'straightening', 'smoothing',
        'shave', 'shaving', 'beard', 'beard trim', 'mustache',
        'facial', 'cleanup', 'scrub', 'peel', 'mask',
        'waxing', 'threading', 'laser', 'hair removal',
        'manicure', 'pedicure', 'nail polish', 'nail art', 'nails',
        'massage', 'body massage', 'head massage', 'foot massage',
        'makeup', 'makeover', 'bridal makeup', 'party makeup',
        
        // Cosmetics & Products
        'cosmetics', 'beauty products', 'skincare', 'skin care',
        'cream', 'lotion', 'moisturizer', 'face wash', 'cleanser',
        'serum', 'toner', 'sunscreen', 'facewash',
        'shampoo', 'conditioner', 'hair oil', 'hair gel', 'hair spray',
        'soap', 'body wash', 'shower gel', 'scrub', 'body lotion',
        'perfume', 'fragrance', 'cologne', 'deodorant', 'deo', 'body spray',
        'lipstick', 'lip balm', 'lip gloss', 'kajal', 'eyeliner', 'mascara',
        'foundation', 'compact', 'powder', 'blush', 'highlighter',
        
        // Hygiene
        'toothpaste', 'toothbrush', 'mouthwash', 'floss', 'dental',
        'razor', 'shaving cream', 'aftershave', 'trimmer',
        'sanitary pads', 'tampons', 'menstrual cup', 'periods',
        'tissues', 'wipes', 'wet wipes', 'hand wash', 'sanitizer',
        
        // ===== HINDI - EXTENSIVE =====
        'saundarya', 'beauty', 'shringar',
        'salon', 'parlour', 'spa',
        'baal', 'hair', 'haircut', 'katwaana',
        'daadhi', 'beard', 'shave', 'muchchh',
        'facial', 'massage', 'maalish',
        'nakhun', 'nails', 'manicure', 'pedicure',
        'cream', 'lotion', 'tel', 'oil',
        'shampoo', 'sabun', 'soap',
        'perfume', 'khushbu', 'itr', 'deodorant',
        'makeup', 'shringar', 'lipstick', 'kajal',
        
        // ===== MARATHI - EXTENSIVE =====
        'saundarya', 'beauty', 'shringar',
        'salon', 'parlour', 'spa',
        'kesha', 'hair', 'haircut', 'kaapne',
        'daadhi', 'beard', 'shave', 'misha',
        'facial', 'massage', 'maalish',
        'nakhe', 'nails', 'manicure', 'pedicure',
        'cream', 'lotion', 'tel',
        'shampoo', 'saabana', 'soap',
        'perfume', 'sugandh', 'deodorant',
        'makeup', 'shringar', 'lipstick', 'kajal',
      ],
    };

    return base;
  }

  /// Infer category from vague context
  String _inferCategoryFromContext(String text, String language) {
    // Drinks/beverages → food
    if (text.contains('drink') || text.contains('beverage') || 
        text.contains('chai') || text.contains('coffee') || 
        text.contains('tea') || text.contains('juice') ||
        text.contains('beer') || text.contains('wine') ||
        text.contains('alcohol') || text.contains('bottle')) {
      return 'food';
    }

    // Anything consumed/eaten → food
    if (text.contains('consume') || text.contains('eating') ||
        text.contains('khaya') || text.contains('khali') ||
        text.contains('peeta') || text.contains('piya')) {
      return 'food';
    }

    // Movement/travel → transport
    if (text.contains('went') || text.contains('going') ||
        text.contains('commute') || text.contains('ride') ||
        text.contains('gaya') || text.contains('gayi') ||
        text.contains('jaa')) {
      return 'transport';
    }

    // Fun/enjoyment → entertainment
    if (text.contains('fun') || text.contains('enjoy') ||
        text.contains('party') || text.contains('celebrate') ||
        text.contains('maza') || text.contains('khushi')) {
      return 'entertainment';
    }

    // Default to misc for truly vague inputs
    return 'misc';
  }

  /// Parse income-specific details with comprehensive field extraction
  Map<String, dynamic> _parseIncomeDetails(String text, String language) {
    final source = _extractIncomeSource(text, language);
    final type = _extractIncomeType(text, language);
    final fromWhom = _extractFromWhom(text, language);
    final description = _cleanDescription(text);
    
    return {
      'source': source,
      'type': type,
      'fromWhom': fromWhom,
      'description': description,
    };
  }

  String _extractIncomeSource(String text, String language) {
    final sourcePatterns = {
      'Salary': [
        // English
        'salary', 'salaries', 'monthly pay', 'wage', 'wages', 'paycheck', 'payday',
        'monthly salary', 'annual salary', 'basic pay', 'gross salary', 'net salary',
        // Hindi
        'tankha', 'vetann', 'maasik', 'majdoori', 'maheena',
        // Marathi
        'paagar', 'mahinya',
      ],
      'Freelance': [
        // English
        'freelance', 'freelancing', 'project', 'contract', 'gig', 'client work',
        'contract work', 'consulting', 'consultation', 'assignment',
        // Hindi
        'project ka paisa', 'client se',
        // Marathi
        'project che paise',
      ],
      'Business': [
        // English
        'business', 'profit', 'sale', 'sales', 'revenue', 'earnings',
        'business income', 'shop income', 'store income', 'trading',
        // Hindi
        'vyapar', 'vyapaar', 'dhandha', 'karobar', 'munafa',
        // Marathi
        'vyapar', 'dhandha', 'naafa',
      ],
      'Gift': [
        // English
        'gift', 'gifted', 'present', 'bonus', 'reward', 'prize',
        'birthday gift', 'wedding gift', 'cash gift',
        // Hindi
        'tohfa', 'inaam', 'bonus', 'upahaar',
        // Marathi
        'bhet', 'inam', 'bonus',
      ],
      'Investment': [
        // English
        'investment', 'dividend', 'interest', 'returns', 'stocks', 'shares',
        'mutual fund', 'capital gain', 'profit from investment',
        'stock market', 'trading profit',
        // Hindi
        'nivesh', 'byaj', 'faida',
        // Marathi
        'guntavnuk', 'vyaj', 'naafa',
      ],
      'Rental': [
        // English
        'rent', 'rental', 'rental income', 'house rent', 'property rent',
        'tenant payment', 'lease', 'lease payment',
        // Hindi
        'kiraya', 'kiraaya', 'bhada', 'ghar ka kiraya',
        // Marathi
        'bhade', 'bhada', 'ghar bhade',
      ],
    };

    // Check each source pattern
    for (var entry in sourcePatterns.entries) {
      for (var pattern in entry.value) {
        if (text.contains(pattern.toLowerCase())) {
          return entry.key;
        }
      }
    }

    return 'Other';
  }

  String _extractIncomeType(String text, String language) {
    // Salary indicators
    if (text.contains('salary') || text.contains('tankha') || text.contains('paagar') ||
        text.contains('wage') || text.contains('paycheck') || text.contains('monthly pay') ||
        text.contains('vetann') || text.contains('maasik') || text.contains('majdoori')) {
      return 'salary';
    }
    
    // Freelance indicators
    if (text.contains('freelance') || text.contains('project') || text.contains('contract') ||
        text.contains('gig') || text.contains('client') || text.contains('consulting')) {
      return 'freelance';
    }
    
    // Business indicators
    if (text.contains('business') || text.contains('vyapar') || text.contains('vyapaar') ||
        text.contains('dhandha') || text.contains('shop') || text.contains('store') ||
        text.contains('trading') || text.contains('karobar')) {
      return 'business';
    }
    
    // Gift indicators
    if (text.contains('gift') || text.contains('tohfa') || text.contains('bhet') ||
        text.contains('bonus') || text.contains('reward') || text.contains('prize') ||
        text.contains('inaam') || text.contains('upahaar')) {
      return 'gift';
    }
    
    // Investment indicators
    if (text.contains('investment') || text.contains('dividend') || text.contains('interest') ||
        text.contains('stock') || text.contains('share') || text.contains('mutual fund') ||
        text.contains('capital gain') || text.contains('nivesh') || text.contains('byaj')) {
      return 'other'; // Investment returns go under 'other' type
    }
    
    // Rental indicators
    if (text.contains('rent') || text.contains('rental') || text.contains('kiraya') ||
        text.contains('bhada') || text.contains('bhade') || text.contains('lease') ||
        text.contains('tenant')) {
      return 'other'; // Rental income goes under 'other' type
    }
    
    return 'other';
  }

  String? _extractFromWhom(String text, String language) {
    // Comprehensive markers for income source (who paid you)
    final markers = {
      'en': [
        // Basic prepositions
        'from', 'by', 'via', 'through',
        
        // Payment markers
        'received from', 'got from', 'paid by',
        'earned from', 'income from', 'salary from',
        'credited by', 'given by', 'sent by',
        
        // Employment markers
        'work for', 'working for', 'employed by', 'employed at',
        'job at', 'company', 'employer',
        
        // Client/customer markers
        'client', 'customer', 'buyer', 'purchaser',
        'sold to', 'service to', 'project for',
      ],
      'hi': [
        // Basic prepositions
        'se', 'say', 'dwara', 'dwaara', 'taraf se',
        
        // Payment markers
        'se mila', 'se milaa', 'se paaya',
        'se aaya', 'se credited hua',
        
        // Employment markers
        'kaam karta', 'kaam karti', 'job hai',
        'company', 'malik', 'employer',
        
        // Source indicators
        'ka paisa', 'ki salary', 'ka payment',
      ],
      'mr': [
        // Basic prepositions
        'pasun', 'pasoon', 'kadun', 'kadhun',
        'tarafan', 'taraphone',
        
        // Payment markers
        'pasun mila', 'pasun milala', 'pasun prapt',
        
        // Employment markers
        'kam karto', 'kam karate', 'job ahe',
        'company', 'maalik', 'employer',
        
        // Source indicators
        'che paise', 'chi salary', 'che payment',
      ],
    };

    final langMarkers = markers[language] ?? markers['en']!;
    final words = text.split(' ');
    
    // Look for markers followed by source name
    for (int i = 0; i < words.length; i++) {
      for (var marker in langMarkers) {
        final markerWords = marker.split(' ');
        
        // Check if marker matches at current position
        bool markerMatches = true;
        for (int j = 0; j < markerWords.length && i + j < words.length; j++) {
          if (!words[i + j].toLowerCase().contains(markerWords[j].toLowerCase())) {
            markerMatches = false;
            break;
          }
        }
        
        // If marker found, extract source name after it
        if (markerMatches) {
          final nameIndex = i + markerWords.length;
          if (nameIndex < words.length) {
            final potentialName = words[nameIndex];
            if (!_isCommonWord(potentialName)) {
              return _capitalizeName(potentialName);
            }
          }
        }
      }
    }
    
    return null;
  }

  /// Parse debt-specific details with ultra-accurate direction detection
  Map<String, dynamic> _parseDebtDetails(String text, String language, String? debtType) {
    final personName = _extractPersonName(text, language);
    final description = _cleanDescription(text);
    
    // CRITICAL: Correctly determine direction based on transaction type
    // debt_i_owe = I borrowed/took money FROM someone = I 'owe' them
    // debt_owed_to_me = I lent/gave money TO someone = They 'owe' me, money is 'owed' to me
    final direction = debtType == 'debt_i_owe' ? 'owe' : 'owed';
    
    return {
      'personName': personName,
      'description': description,
      'direction': direction,
    };
  }

  /// Enhanced person name extraction with comprehensive helper words
  String? _extractPersonName(String text, String language) {
    // Comprehensive markers that indicate person name follows
    final markers = {
      'en': [
        // Basic prepositions
        'to', 'from', 'by', 'for', 'with',
        
        // Extended prepositions
        'towards', 'toward', 'unto', 'upon',
        
        // Give/take markers
        'gave to', 'give to', 'given to', 'gave', 'give',
        'took from', 'take from', 'taken from', 'took', 'take',
        'lent to', 'lend to', 'lent', 'lend',
        'borrowed from', 'borrow from', 'borrowed', 'borrow',
        'paid to', 'pay to', 'paid', 'pay',
        'received from', 'receive from', 'received', 'receive',
        'got from', 'get from', 'got', 'get',
        
        // Loan/debt markers
        'owes me', 'owe me', 'owed me', 'owe',
        'i owe', 'owe to', 'owed to', 'owing',
        'loan to', 'loan from', 'loaned to', 'loaned from',
        
        // Expense markers
        'bought from', 'buy from', 'purchased from', 'purchase from',
        'spent at', 'spent on', 'paid at', 'paid for',
        
        // Person indicators
        'person', 'guy', 'man', 'woman', 'friend', 'relative',
        'brother', 'sister', 'mother', 'father', 'uncle', 'aunt',
      ],
      'hi': [
        // Basic prepositions
        'ko', 'koh', 'se', 'say', 'ne', 'nay', 'ke liye', 'keliye',
        'dwara', 'dwaara', 'taraf', 'taraph',
        
        // Give/take markers
        'diya', 'dia', 'diye', 'di', 'de diya', 'de di',
        'liya', 'lia', 'liye', 'li', 'le liya', 'le li',
        'dena hai', 'dene hai', 'deni hai',
        'lena hai', 'lene hai', 'leni hai',
        
        // Extended forms
        'ko diya', 'ko diye', 'ko di',
        'se liya', 'se liye', 'se li',
        'ko dena hai', 'se lena hai',
        'ko loan diya', 'se loan liya',
        'ko udhaar diya', 'se udhaar liya',
        'ko karz diya', 'se karz liya',
        
        // Payment markers
        'ko payment kiya', 'ko paid kiya',
        'se payment mila', 'se mila',
        
        // Person indicators
        'vyakti', 'aadmi', 'aurat', 'dost', 'rishtedaar',
        'bhai', 'behan', 'maa', 'baap', 'chacha', 'chachi',
      ],
      'mr': [
        // Basic prepositions
        'la', 'laa', 'ne', 'nay', 'pasun', 'pasoon',
        'sathi', 'saathi', 'karita', 'kadun', 'kadhun',
        'taraf', 'towar',
        
        // Give/take markers
        'dila', 'dili', 'dile', 'dela', 'deli',
        'ghetla', 'ghetli', 'ghetle', 'ghyatla',
        'dyaycha ahe', 'dyacha ahe', 'dyachi ahe',
        'ghyaycha ahe', 'ghyacha ahe', 'ghyachi ahe',
        
        // Extended forms
        'la dila', 'la dili', 'la dile',
        'pasun ghetla', 'pasun ghetli', 'pasun ghetle',
        'la loan dila', 'pasun loan ghetla',
        'la pharaki dila', 'pasun pharaki ghetla',
        'la karz dila', 'pasun karz ghetla',
        
        // Payment markers
        'la payment kela', 'la paid kela',
        'pasun payment mila', 'pasun mila',
        
        // Person indicators
        'vyakti', 'maanus', 'baai', 'mitra', 'natewaik',
        'bhau', 'bahin', 'aai', 'baba', 'kaka', 'kaki',
      ],
    };

    final langMarkers = markers[language] ?? markers['en']!;
    final words = text.split(' ');
    
    // Strategy 1: Look for markers followed by name
    for (int i = 0; i < words.length; i++) {
      for (var marker in langMarkers) {
        final markerWords = marker.split(' ');
        
        // Check if marker matches at current position
        bool markerMatches = true;
        for (int j = 0; j < markerWords.length && i + j < words.length; j++) {
          if (!words[i + j].toLowerCase().contains(markerWords[j].toLowerCase())) {
            markerMatches = false;
            break;
          }
        }
        
        // If marker found, extract name after it
        if (markerMatches) {
          final nameIndex = i + markerWords.length;
          if (nameIndex < words.length) {
            final potentialName = words[nameIndex];
            // Skip common words that aren't names
            if (!_isCommonWord(potentialName)) {
              return _capitalizeName(potentialName);
            }
          }
        }
      }
    }
    
    // Strategy 2: Find capitalized words (likely names)
    for (var word in words) {
      if (word.isNotEmpty && word.length > 2) {
        final firstChar = word[0];
        // Check if first letter is uppercase
        if (firstChar == firstChar.toUpperCase() && firstChar != firstChar.toLowerCase()) {
          // Skip common words even if capitalized
          if (!_isCommonWord(word)) {
            return word;
          }
        }
      }
    }
    
    // Strategy 3: Look for proper noun patterns (Mr., Mrs., etc.)
    final titles = ['mr', 'mrs', 'miss', 'dr', 'prof', 'sir', 'madam',
                    'shri', 'smt', 'kumari', 'beta', 'bhai', 'didi'];
    for (int i = 0; i < words.length - 1; i++) {
      final word = words[i].toLowerCase().replaceAll('.', '');
      if (titles.contains(word) && i + 1 < words.length) {
        return _capitalizeName(words[i + 1]);
      }
    }
    
    return 'Unknown';
  }

  /// Check if word is a common word (not a name)
  bool _isCommonWord(String word) {
    final commonWords = {
      // English
      'i', 'me', 'my', 'mine', 'myself',
      'you', 'your', 'yours', 'yourself',
      'he', 'him', 'his', 'himself',
      'she', 'her', 'hers', 'herself',
      'it', 'its', 'itself',
      'we', 'us', 'our', 'ours', 'ourselves',
      'they', 'them', 'their', 'theirs', 'themselves',
      'the', 'a', 'an', 'this', 'that', 'these', 'those',
      'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being',
      'have', 'has', 'had', 'having',
      'do', 'does', 'did', 'doing',
      'will', 'would', 'shall', 'should', 'can', 'could', 'may', 'might', 'must',
      'and', 'but', 'or', 'nor', 'for', 'yet', 'so',
      'at', 'by', 'for', 'from', 'in', 'into', 'of', 'on', 'to', 'with',
      'about', 'above', 'across', 'after', 'against', 'along', 'among', 'around',
      'before', 'behind', 'below', 'beneath', 'beside', 'between', 'beyond',
      'during', 'except', 'inside', 'like', 'near', 'off', 'out', 'outside',
      'over', 'through', 'toward', 'under', 'until', 'up', 'upon', 'within', 'without',
      'what', 'when', 'where', 'which', 'who', 'whom', 'whose', 'why', 'how',
      'all', 'another', 'any', 'anybody', 'anyone', 'anything',
      'both', 'each', 'either', 'everybody', 'everyone', 'everything',
      'few', 'many', 'most', 'much', 'neither', 'nobody', 'none', 'nothing',
      'one', 'other', 'several', 'some', 'somebody', 'someone', 'something',
      'such', 'than', 'then', 'there',
      
      // Hindi
      'mai', 'mein', 'mera', 'meri', 'mere',
      'tu', 'tum', 'tera', 'teri', 'tere', 'tumhara', 'tumhari',
      'woh', 'wo', 'uska', 'uski', 'uske',
      'yeh', 'ye', 'iska', 'iski', 'iske',
      'hum', 'hamara', 'hamari', 'hamare',
      'aur', 'ya', 'lekin', 'par', 'kyunki',
      'kya', 'kaun', 'kab', 'kahan', 'kyun', 'kaise',
      'hai', 'hain', 'tha', 'thi', 'the', 'thi',
      
      // Marathi
      'mi', 'mee', 'maza', 'maji', 'maze',
      'tu', 'tula', 'tuja', 'tuji', 'tuje',
      'to', 'ti', 'tya', 'tyacha', 'tyachi', 'tyache',
      'he', 'hi', 'hya', 'hyacha', 'hyachi', 'hyache',
      'aapan', 'aamcha', 'aamchi', 'aamche',
      'ani', 'kiva', 'pan', 'parantu', 'karan',
      'kay', 'kon', 'kevha', 'kuthe', 'ka', 'kase',
      'aahe', 'ahe', 'hota', 'hoti', 'hote',
    };
    
    return commonWords.contains(word.toLowerCase());
  }

  String _capitalizeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w\s]'), '');
    if (cleaned.isEmpty) return 'Unknown';
    return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
  }

  String _cleanDescription(String text) {
    // Remove transaction type markers and amount, keep the meaningful description
    String cleaned = text;
    
    // Remove common transaction markers
    final markersToRemove = [
      // English
      'spent', 'spend', 'paid', 'pay', 'bought', 'buy', 'purchased', 'purchase',
      'gave', 'give', 'took', 'take', 'lent', 'lend', 'borrowed', 'borrow',
      'earned', 'earn', 'received', 'receive', 'got', 'get',
      'owe', 'owes', 'owed', 'owing',
      // Hindi
      'kharch', 'kharcha', 'diya', 'liya', 'kamaaya', 'mila',
      'udhaar', 'karz', 'loan',
      // Marathi
      'kharch', 'dila', 'ghetla', 'kamavla', 'mila',
      'pharaki', 'karz',
      // Prepositions
      'to', 'from', 'by', 'for', 'on', 'at', 'in',
      'ko', 'se', 'ne', 'la', 'pasun',
    ];
    
    // Remove numbers and currency symbols
    cleaned = cleaned.replaceAll(RegExp(r'\d+\.?\d*'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'(rs|rupees|rupee|rupaye|₹)'), '').trim();
    
    // Remove transaction markers
    for (var marker in markersToRemove) {
      cleaned = cleaned.replaceAll(RegExp('\\b$marker\\b', caseSensitive: false), '').trim();
    }
    
    // Remove extra spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Return cleaned description or full text if nothing left
    return cleaned.isNotEmpty ? cleaned : text.trim();
  }

  // ============================================================================
  // DATABASE CREATION METHODS (Updated for enhanced parsing)
  // ============================================================================

  Future<Map<String, dynamic>> _createIncome(Map<String, dynamic> parsed, String userId) async {
    if (parsed['amount'] == null) {
      return {'success': false, 'message': 'Could not detect amount'};
    }

    // Create income entry with all properly mapped fields
    final now = DateTime.now();
    final income = Income(
      userId: userId,
      amount: parsed['amount'],
      source: parsed['source'] ?? 'Other',
      fromWhom: parsed['fromWhom'], // Can be null if not detected
      description: parsed['description'] ?? parsed['originalText'], // Fallback to original text
      date: now, // Income date is current date
      type: parsed['type'] ?? 'other',
      isRecurring: false, // Voice input is always one-time
      frequency: null, // Not recurring
      recurringDay: null, // Not recurring
      createdAt: now,
    );

    final success = await DatabaseService.addIncome(income);
    return {
      'success': success,
      'message': success 
        ? 'Income of ₹${parsed['amount']} added successfully' 
        : 'Failed to add income',
    };
  }

  Future<Map<String, dynamic>> _createExpense(Map<String, dynamic> parsed, String userId) async {
    if (parsed['amount'] == null) {
      return {'success': false, 'message': 'Could not detect amount'};
    }

    final expense = Expense(
      userId: userId,
      amount: parsed['amount'],
      category: parsed['category'] ?? 'misc',
      description: parsed['description'],
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );

    return await DatabaseService.addExpense(expense);
  }

  Future<Map<String, dynamic>> _createDebt(Map<String, dynamic> parsed, String userId) async {
    // Validate required fields
    if (parsed['amount'] == null) {
      return {'success': false, 'message': 'Could not detect amount'};
    }
    
    if (parsed['personName'] == null || parsed['personName'] == 'Unknown') {
      return {'success': false, 'message': 'Could not detect person name'};
    }

    // Create debt entry with all properly mapped fields
    final now = DateTime.now();
    final dueDate = now.add(const Duration(days: 10)); // Due in 10 days as requested
    
    final debt = Debt(
      userId: userId,
      personName: parsed['personName'],
      amount: parsed['amount'],
      paidAmount: 0.0, // Initially unpaid
      direction: parsed['direction'] ?? 'owe', // 'owe' or 'owed'
      description: parsed['description'] ?? parsed['originalText'], // Fallback to original text
      dueDate: dueDate, // 10 days from now
      isSettled: false, // Initially not settled
      createdAt: now, // Creation date is current date
      updatedAt: now,
    );

    final result = await DatabaseService.addDebt(debt);
    
    // Enhance result message with details
    if (result['success']) {
      final directionText = parsed['direction'] == 'owe' 
        ? 'You owe ${parsed['personName']}'
        : '${parsed['personName']} owes you';
      result['message'] = '$directionText ₹${parsed['amount']} (Due: ${dueDate.day}/${dueDate.month}/${dueDate.year})';
    }
    
    return result;
  }

  // ============================================================================
  // LOCALIZATION METHODS
  // ============================================================================

  Map<String, Map<String, String>> get _texts => {
    'hi': {
      'voiceInput': 'वॉइस इनपुट',
      'initializing': 'शुरू हो रहा है...',
      'readyToRecord': 'रिकॉर्ड करने के लिए तैयार',
      'listening': 'सुन रहा हूं... बोलें',
      'processing': 'प्रोसेस हो रहा है...',
      'transcribed': 'ट्रांसक्राइब किया गया',
      'tapToSpeak': 'बोलने के लिए टैप करें',
      'examples': 'उदाहरण:',
      'cancel': 'रद्द करें',
      'record': 'रिकॉर्ड करें',
      'stop': 'रोकें',
      'success': 'सफलता!',
      'error': 'त्रुटि',
      'permissionDenied': 'माइक्रोफोन अनुमति की आवश्यकता है',
      'initializationFailed': 'शुरू करने में विफल',
      'recordingFailed': 'रिकॉर्डिंग शुरू नहीं हुई',
      'noSpeechDetected': 'कोई आवाज नहीं सुनी',
      'tryAgain': 'फिर से प्रयास करें',
      'couldNotUnderstand': 'समझ नहीं आया',
      'creatingTransaction': 'ट्रांजैक्शन बना रहे हैं...',
      'transactionCreated': 'ट्रांजैक्शन बनाया गया',
      'failed': 'असफल',
      'switchingLanguage': 'भाषा बदल रही है...',
      'languageChangeFailed': 'भाषा बदलने में विफल',
      'userNotLoggedIn': 'यूजर लॉगिन नहीं है',
      'processingFailed': 'प्रोसेसिंग विफल',
    },
    'mr': {
      'voiceInput': 'व्हॉईस इनपुट',
      'initializing': 'सुरू होत आहे...',
      'readyToRecord': 'रेकॉर्ड करण्यासाठी तयार',
      'listening': 'ऐकत आहे... बोला',
      'processing': 'प्रोसेस होत आहे...',
      'transcribed': 'ट्रान्सक्राइब केले',
      'tapToSpeak': 'बोलण्यासाठी टॅप करा',
      'examples': 'उदाहरणे:',
      'cancel': 'रद्द करा',
      'record': 'रेकॉर्ड करा',
      'stop': 'थांबवा',
      'success': 'यश!',
      'error': 'चूक',
      'permissionDenied': 'मायक्रोफोन परवानगी आवश्यक आहे',
      'initializationFailed': 'सुरू करण्यात अयशस्वी',
      'recordingFailed': 'रेकॉर्डिंग सुरू झाले नाही',
      'noSpeechDetected': 'आवाज ऐकू आला नाही',
      'tryAgain': 'पुन्हा प्रयत्न करा',
      'couldNotUnderstand': 'समजले नाही',
      'creatingTransaction': 'व्यवहार तयार करत आहे...',
      'transactionCreated': 'व्यवहार तयार झाला',
      'failed': 'अयशस्वी',
      'switchingLanguage': 'भाषा बदलत आहे...',
      'languageChangeFailed': 'भाषा बदलण्यात अयशस्वी',
      'userNotLoggedIn': 'युजर लॉगिन नाही',
      'processingFailed': 'प्रोसेसिंग अयशस्वी',
    },
    'en': {
      'voiceInput': 'Voice Input',
      'initializing': 'Initializing...',
      'readyToRecord': 'Ready to record',
      'listening': 'Listening... Speak now',
      'processing': 'Processing...',
      'transcribed': 'Transcribed',
      'tapToSpeak': 'Tap to speak',
      'examples': 'Examples:',
      'cancel': 'Cancel',
      'record': 'Record',
      'stop': 'Stop',
      'success': 'Success!',
      'error': 'Error',
      'permissionDenied': 'Microphone permission required',
      'initializationFailed': 'Failed to initialize',
      'recordingFailed': 'Recording failed to start',
      'noSpeechDetected': 'No speech detected',
      'tryAgain': 'Please try again',
      'couldNotUnderstand': 'Could not understand',
      'creatingTransaction': 'Creating transaction...',
      'transactionCreated': 'Transaction created',
      'failed': 'Failed',
      'switchingLanguage': 'Switching language...',
      'languageChangeFailed': 'Failed to change language',
      'userNotLoggedIn': 'User not logged in',
      'processingFailed': 'Processing failed',
    },
  };

  String _getText(String key) {
    return _texts[_selectedLanguage]?[key] ?? _texts['en']![key]!;
  }

  List<String> _getExamplePhrases(String language) {
    final examples = {
      'en': [
        '500 earned today',
        'Spent 200 on food',
        'Gave 300 to Raj',
      ],
      'hi': [
        'Aaj 500 kamaaye',
        'Khana par 200 kharch',
        'Raj ko 300 diye',
      ],
      'mr': [
        'Aaj 500 kamavale',
        'Jevan var 200 kharch',
        'Raj la 300 dile',
      ],
    };

    return examples[language] ?? examples['en']!;
  }
}
