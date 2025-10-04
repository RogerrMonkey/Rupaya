import 'package:flutter/material.dart';
import '../services/voice_input_service.dart';
import '../services/voice_permission_manager.dart';

class VoiceInputDialog extends StatefulWidget {
  final String language;

  const VoiceInputDialog({super.key, required this.language});

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog>
    with SingleTickerProviderStateMixin {
  final VoiceInputService _voiceService = VoiceInputService();
  bool _isListening = false;
  String _recognizedText = '';
  String _statusMessage = '';
  bool _isProcessing = false;
  bool _hasProcessed = false; // Prevent multiple processing
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _voiceService.setLanguage(widget.language);

    // Pulse animation for mic icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startListening();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _hasProcessed = false;
      _recognizedText = ''; // Clear previous text
      _statusMessage = _getText('listening');
    });

    _pulseController.repeat(reverse: true);

    await _voiceService.listen(
      onResult: (text) {
        if (!mounted) return;
        
        setState(() {
          _recognizedText = text;
        });
      },
      onError: (error) {
        if (!mounted) return;
        
        setState(() {
          _isListening = false;
          _statusMessage = error;
        });
        _pulseController.stop();
      },
    );
  }

  Future<void> _stopAndProcess() async {
    if (!_isListening || _isProcessing || _hasProcessed) return;

    // Stop listening
    _voiceService.stopListening();
    
    setState(() {
      _isListening = false;
    });
    _pulseController.stop();

    // Small delay to ensure final result
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted || _hasProcessed) return;

    // Check if we got any speech
    if (_recognizedText.isNotEmpty) {
      _processVoiceInput(_recognizedText);
    } else {
      // No speech detected
      setState(() {
        _statusMessage = _getText('noSpeechDetected');
      });

      // Auto-close after showing error
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }

  Future<void> _processVoiceInput(String text) async {
    if (_isProcessing || _hasProcessed) return; // Prevent duplicate processing

    setState(() {
      _isProcessing = true;
      _hasProcessed = true;
      _statusMessage = _getText('processing');
    });

    _pulseController.stop();

    final result = await _voiceService.parseAndCreateTransaction(
      text,
      widget.language,
    );

    if (result['success'] == true) {
      // Success!
      await _voiceService.speak(_getText('success'));

      // Auto-close after success
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } else {
      // Error
      setState(() {
        _isProcessing = false;
        _statusMessage = result['message'] ?? _getText('error');
      });

      // Auto-close after showing error
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF46EC13).withOpacity(0.1),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),

            const SizedBox(height: 8),

            // Animated Microphone Icon
            GestureDetector(
              onTap: _isListening && !_isProcessing ? _stopAndProcess : null,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isListening
                              ? [
                                  const Color(0xFF46EC13),
                                  const Color(0xFF34D399),
                                ]
                              : [
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                ],
                        ),
                        boxShadow: _isListening
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF46EC13).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_off,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Status Message
            Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF46EC13),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Recognized Text Display
            if (_recognizedText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF46EC13).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getText('youSaid'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _recognizedText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Processing Indicator
            if (_isProcessing)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF46EC13)),
              ),

            if (!_isProcessing && !_isListening)
              ElevatedButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.refresh),
                label: Text(_getText('tryAgain')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF46EC13),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Example phrases
            Text(
              _getText('examples'),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildExampleChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChips() {
    final examples = _getExamples();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: examples.map((example) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF46EC13).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF46EC13).withOpacity(0.3),
            ),
          ),
          child: Text(
            example,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }

  List<String> _getExamples() {
    final examples = {
      'en': [
        '"Earned 500"',
        '"Spent 200 on food"',
        '"Raj owes me 300"',
      ],
      'hi': [
        '"500 रुपये कमाये"',
        '"खाने पर 200 खर्च"',
        '"राज को 300 दिए"',
      ],
      'mr': [
        '"500 रुपये कमावले"',
        '"जेवणावर 200 खर्च"',
        '"राजला 300 दिले"',
      ],
    };

    return examples[widget.language] ?? examples['en']!;
  }

  String _getText(String key) {
    final texts = {
      'en': {
        'listening': 'Listening... Tap mic to stop',
        'processing': 'Processing your request...',
        'success': 'Transaction saved successfully!',
        'error': 'Could not understand. Please try again.',
        'noSpeechDetected': 'No speech detected. Please try again.',
        'youSaid': 'You said:',
        'tryAgain': 'Try Again',
        'examples': 'Example phrases:',
      },
      'hi': {
        'listening': 'सुन रहा हूं... रोकने के लिए माइक टैप करें',
        'processing': 'प्रोसेस कर रहे हैं...',
        'success': 'लेनदेन सफलतापूर्वक सहेजा गया!',
        'error': 'समझ नहीं आया। कृपया पुनः प्रयास करें।',
        'noSpeechDetected': 'कोई आवाज नहीं सुनी। कृपया पुनः प्रयास करें।',
        'youSaid': 'आपने कहा:',
        'tryAgain': 'पुनः प्रयास करें',
        'examples': 'उदाहरण वाक्यांश:',
      },
      'mr': {
        'listening': 'ऐकत आहे... थांबवण्यासाठी माइक टॅप करा',
        'processing': 'प्रक्रिया करत आहे...',
        'success': 'व्यवहार यशस्वीरित्या सेव्ह केला!',
        'error': 'समजले नाही. कृपया पुन्हा प्रयत्न करा.',
        'noSpeechDetected': 'कोणतीही आवाज आली नाही. कृपया पुन्हा प्रयत्न करा.',
        'youSaid': 'तुम्ही म्हणालात:',
        'tryAgain': 'पुन्हा प्रयत्न करा',
        'examples': 'उदाहरण वाक्ये:',
      },
    };

    return texts[widget.language]?[key] ?? texts['en']![key]!;
  }
}
