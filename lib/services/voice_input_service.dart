import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_service.dart';
import 'auth_service.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/debt.dart';

class VoiceInputService {
  static final VoiceInputService _instance = VoiceInputService._internal();
  factory VoiceInputService() => _instance;
  VoiceInputService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isListening = false;

  // Voice input state
  String _currentLanguage = 'en-IN';
  List<dynamic> _availableLocales = [];

  // Getters
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  List<dynamic> get availableLocales => _availableLocales;

  /// Initialize the speech recognition engine
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Speech status: $status'),
        onError: (error) => print('Speech error: $error'),
      );

      if (available) {
        _availableLocales = await _speech.locales();
        _isInitialized = true;

        // Initialize TTS
        await _tts.setLanguage('en-IN');
        await _tts.setSpeechRate(0.5);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);

        print('Voice input initialized with ${_availableLocales.length} locales');
      }

      return available;
    } catch (e) {
      print('Error initializing voice input: $e');
      return false;
    }
  }

  /// Set language for voice recognition
  void setLanguage(String appLanguage) {
    switch (appLanguage) {
      case 'hi':
        _currentLanguage = 'hi-IN';
        _tts.setLanguage('hi-IN');
        break;
      case 'mr':
        _currentLanguage = 'mr-IN';
        _tts.setLanguage('mr-IN');
        break;
      default:
        _currentLanguage = 'en-IN';
        _tts.setLanguage('en-IN');
    }
  }

  /// Start listening to user voice
  Future<String?> listen({
    required Function(String) onResult,
    required Function(String) onError,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) {
        onError('Voice input not available');
        return null;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      _isListening = true;
      String? result;

      await _speech.listen(
        onResult: (val) {
          result = val.recognizedWords;
          if (val.finalResult) {
            onResult(result ?? '');
          }
        },
        localeId: localeId ?? _currentLanguage,
        listenFor: const Duration(seconds: 5), // Stop after 5 seconds of no speech
        pauseFor: const Duration(seconds: 2), // Detect end of speech after 2 seconds of silence
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      return result;
    } catch (e) {
      _isListening = false;
      onError('Error listening: $e');
      return null;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Speak text using TTS
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  /// Parse voice input and create transaction
  Future<Map<String, dynamic>> parseAndCreateTransaction(
    String spokenText,
    String appLanguage,
  ) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      final parsed = _parseVoiceInput(spokenText.toLowerCase(), appLanguage);

      if (parsed['type'] == null) {
        return {
          'success': false,
          'message': 'Could not understand. Please try again.',
          'parsed': parsed,
        };
      }

      // Create transaction based on type
      switch (parsed['type']) {
        case 'income':
          return await _createIncomeFromVoice(parsed, currentUser.id!);
        case 'expense':
          return await _createExpenseFromVoice(parsed, currentUser.id!);
        case 'debt_i_owe':
        case 'debt_owed_to_me':
          return await _createDebtFromVoice(parsed, currentUser.id!);
        default:
          return {
            'success': false,
            'message': 'Transaction type not recognized',
          };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// NLP Parser - Detect transaction type, amount, category, person
  Map<String, dynamic> _parseVoiceInput(String text, String language) {
    Map<String, dynamic> result = {
      'type': null,
      'amount': null,
      'category': null,
      'personName': null,
      'description': text,
    };

    // Extract amount (supports numbers and Hindi/Marathi words)
    result['amount'] = _extractAmount(text, language);

    // Detect transaction type
    result['type'] = _detectTransactionType(text, language);

    // Extract person name (for debts)
    if (result['type']?.contains('debt') ?? false) {
      result['personName'] = _extractPersonName(text, language);
    }

    // Extract category (for expenses)
    if (result['type'] == 'expense') {
      result['category'] = _extractCategory(text, language);
    }

    // Extract source (for income)
    if (result['type'] == 'income') {
      result['source'] = _extractIncomeSource(text, language);
    }

    return result;
  }

  /// Extract amount from text
  double? _extractAmount(String text, String language) {
    // First try to find direct numbers
    final numberRegex = RegExp(r'\d+');
    final match = numberRegex.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(0)!);
    }

    // Hindi number words
    final hindiNumbers = {
      'ek': 1, 'do': 2, 'teen': 3, 'char': 4, 'paanch': 5,
      'chhe': 6, 'saat': 7, 'aath': 8, 'nau': 9, 'das': 10,
      'bees': 20, 'tees': 30, 'chalis': 40, 'pachaas': 50,
      'saath': 60, 'sattar': 70, 'assi': 80, 'nabbe': 90,
      'sau': 100, 'hazaar': 1000,
    };

    // Marathi number words
    final marathiNumbers = {
      'ek': 1, 'don': 2, 'teen': 3, 'char': 4, 'paach': 5,
      'sahaa': 6, 'saat': 7, 'aath': 8, 'nau': 9, 'dahaa': 10,
      'vees': 20, 'tees': 30, 'chaalis': 40, 'pannaas': 50,
      'saath': 60, 'sattar': 70, 'ayshi': 80, 'navvad': 90,
      'shambhar': 100, 'hazaar': 1000,
    };

    // Try to parse Hindi/Marathi numbers
    final numbers = language == 'mr' ? marathiNumbers : hindiNumbers;
    
    // Look for "paanch sau" (500), "teen sau" (300), etc.
    for (var entry in numbers.entries) {
      if (text.contains(entry.key)) {
        double value = entry.value.toDouble();
        
        // Check for multipliers
        if (entry.key == 'sau' || entry.key == 'shambhar') {
          // Look for number before 'sau'
          for (var mult in numbers.entries) {
            if (mult.value < 100 && text.contains('${mult.key} ${entry.key}')) {
              return mult.value * 100.0;
            }
          }
          return 100.0;
        } else if (entry.key == 'hazaar') {
          for (var mult in numbers.entries) {
            if (mult.value < 1000 && text.contains('${mult.key} ${entry.key}')) {
              return mult.value * 1000.0;
            }
          }
          return 1000.0;
        }
        
        return value;
      }
    }

    return null;
  }

  /// Detect transaction type from speech
  String? _detectTransactionType(String text, String language) {
    // Income keywords
    final incomeKeywords = {
      'en': ['earned', 'income', 'received', 'got', 'salary', 'payment'],
      'hi': ['kamaaye', 'kamaaya', 'mila', 'mile', 'aaya', 'aayi', 'amdani'],
      'mr': ['milale', 'mila', 'kamavale', 'utpanna', 'alapla'],
    };

    // Expense keywords
    final expenseKeywords = {
      'en': ['spent', 'expense', 'paid', 'bought', 'purchase'],
      'hi': ['kharch', 'kharcha', 'kharche', 'khareeda', 'liya', 'bhara'],
      'mr': ['kharch', 'kharchale', 'bharale', 'kharidla', 'dila'],
    };

    // Debt (I owe) keywords
    final debtIOweKeywords = {
      'en': ['owe', 'borrowed', 'took loan', 'gave to', 'lent to'],
      'hi': ['diye', 'diya', 'udhaar', 'karza', 'maine'],
      'mr': ['dile', 'dila', 'pharaki', 'karj'],
    };

    // Debt (Owed to me) keywords
    final debtOwedToMeKeywords = {
      'en': ['owes me', 'lent', 'gave loan', 'borrowed from me'],
      'hi': ['mujhe', 'lena', 'milna', 'dena'],
      'mr': ['mala', 'ghene', 'milane'],
    };

    // Check for debt patterns first (more specific)
    final debtIOweLang = debtIOweKeywords[language] ?? debtIOweKeywords['en']!;
    final debtOwedLang = debtOwedToMeKeywords[language] ?? debtOwedToMeKeywords['en']!;

    // "Maine Raj ko diye" → I owe
    if (debtIOweLang.any((kw) => text.contains(kw)) && 
        (text.contains('ko ') || text.contains('to '))) {
      return 'debt_i_owe';
    }

    // "Priya ne mujhe diye" → Owed to me
    if (debtOwedLang.any((kw) => text.contains(kw)) && 
        (text.contains('ne ') || text.contains('from '))) {
      return 'debt_owed_to_me';
    }

    // Check income
    final incomeLang = incomeKeywords[language] ?? incomeKeywords['en']!;
    if (incomeLang.any((kw) => text.contains(kw))) {
      return 'income';
    }

    // Check expense
    final expenseLang = expenseKeywords[language] ?? expenseKeywords['en']!;
    if (expenseLang.any((kw) => text.contains(kw))) {
      return 'expense';
    }

    return null;
  }

  /// Extract person name from debt-related speech
  String? _extractPersonName(String text, String language) {
    // Common patterns:
    // "Raj ko diye" → Raj
    // "Priya ne mujhe" → Priya
    // "gave to John" → John

    // Split text into words
    final words = text.split(' ');

    // Look for name before "ko", "ne", "to", "from"
    final markers = ['ko', 'ne', 'to', 'from', 'se'];
    
    for (int i = 0; i < words.length - 1; i++) {
      if (markers.contains(words[i + 1])) {
        // Capitalize first letter
        final name = words[i];
        return name[0].toUpperCase() + name.substring(1);
      }
    }

    // Fallback: look for capitalized words (names are usually capitalized in speech)
    for (var word in words) {
      if (word.length > 2 && 
          word[0] == word[0].toUpperCase() && 
          !['Aaj', 'Maine', 'Mujhe', 'Today', 'I', 'Me'].contains(word)) {
        return word;
      }
    }

    return 'Unknown';
  }

  /// Extract expense category from speech
  String _extractCategory(String text, String language) {
    final categoryKeywords = {
      'food': {
        'en': ['food', 'eat', 'restaurant', 'meal', 'lunch', 'dinner', 'breakfast'],
        'hi': ['khana', 'khaana', 'khaane', 'khaya', 'nashta', 'lunch', 'dinner'],
        'mr': ['jevan', 'khanya', 'nashta', 'jeval'],
      },
      'travel': {
        'en': ['travel', 'bus', 'taxi', 'auto', 'train', 'fuel', 'petrol'],
        'hi': ['travel', 'bus', 'taxi', 'auto', 'train', 'petrol', 'safar'],
        'mr': ['pravas', 'bus', 'taxi', 'auto', 'train', 'petrol'],
      },
      'bills': {
        'en': ['bill', 'electricity', 'water', 'phone', 'internet', 'rent'],
        'hi': ['bill', 'bijli', 'light', 'pani', 'phone', 'kiraya'],
        'mr': ['bill', 'vij', 'pani', 'phone', 'bhaade'],
      },
      'shopping': {
        'en': ['shopping', 'clothes', 'shop', 'bought', 'purchase'],
        'hi': ['shopping', 'kapde', 'khareeda', 'kharida'],
        'mr': ['shopping', 'kapde', 'kharidla', 'vikat'],
      },
      'health': {
        'en': ['health', 'medicine', 'doctor', 'hospital', 'medical'],
        'hi': ['health', 'dawa', 'doctor', 'hospital', 'dawai'],
        'mr': ['aarogya', 'aushadh', 'doctor', 'hospital'],
      },
      'entertainment': {
        'en': ['entertainment', 'movie', 'fun', 'game', 'party'],
        'hi': ['entertainment', 'movie', 'film', 'masti', 'party'],
        'mr': ['manoranjan', 'cinema', 'khel', 'party'],
      },
      'education': {
        'en': ['education', 'book', 'course', 'study', 'school', 'tuition'],
        'hi': ['education', 'kitab', 'book', 'padhai', 'school', 'tuition'],
        'mr': ['shikshan', 'pustak', 'abhyas', 'shala', 'tuition'],
      },
    };

    // Check each category
    for (var entry in categoryKeywords.entries) {
      final keywords = entry.value[language] ?? entry.value['en']!;
      if (keywords.any((kw) => text.contains(kw))) {
        return entry.key;
      }
    }

    return 'misc'; // Default category
  }

  /// Extract income source from speech
  String _extractIncomeSource(String text, String language) {
    final sourceKeywords = {
      'Daily Wages': {
        'en': ['daily', 'wage', 'labor', 'work'],
        'hi': ['daily', 'majdoori', 'kaam', 'wage'],
        'mr': ['rojgar', 'majuri', 'kam'],
      },
      'Freelance': {
        'en': ['freelance', 'project', 'gig'],
        'hi': ['freelance', 'project', 'kaam'],
        'mr': ['freelance', 'project'],
      },
      'Business': {
        'en': ['business', 'sale', 'profit'],
        'hi': ['business', 'vyapaar', 'faayda'],
        'mr': ['vyapar', 'faayda', 'dhandha'],
      },
    };

    for (var entry in sourceKeywords.entries) {
      final keywords = entry.value[language] ?? entry.value['en']!;
      if (keywords.any((kw) => text.contains(kw))) {
        return entry.key;
      }
    }

    return 'Other';
  }

  /// Create income from parsed voice input
  Future<Map<String, dynamic>> _createIncomeFromVoice(
    Map<String, dynamic> parsed,
    String userId,
  ) async {
    if (parsed['amount'] == null) {
      return {
        'success': false,
        'message': 'Could not detect amount',
      };
    }

    final income = Income(
      userId: userId,
      amount: parsed['amount'],
      source: parsed['source'] ?? 'Other',
      date: DateTime.now(),
      type: 'other', // Default type for voice input
      isRecurring: false,
      createdAt: DateTime.now(),
    );

    final success = await DatabaseService.addIncome(income);
    
    return {
      'success': success,
      'message': success ? 'Income added successfully' : 'Failed to add income',
    };
  }

  /// Create expense from parsed voice input
  Future<Map<String, dynamic>> _createExpenseFromVoice(
    Map<String, dynamic> parsed,
    String userId,
  ) async {
    if (parsed['amount'] == null) {
      return {
        'success': false,
        'message': 'Could not detect amount',
      };
    }

    final expense = Expense(
      userId: userId,
      amount: parsed['amount'],
      category: parsed['category'] ?? 'misc',
      date: DateTime.now(),
      description: parsed['description'],
      createdAt: DateTime.now(),
    );

    final result = await DatabaseService.addExpense(expense);
    return result;
  }

  /// Create debt from parsed voice input
  Future<Map<String, dynamic>> _createDebtFromVoice(
    Map<String, dynamic> parsed,
    String userId,
  ) async {
    if (parsed['amount'] == null || parsed['personName'] == null) {
      return {
        'success': false,
        'message': 'Could not detect amount or person name',
      };
    }

    final direction = parsed['type'] == 'debt_i_owe' ? 'owe' : 'owed';

    final debt = Debt(
      userId: userId,
      personName: parsed['personName'],
      amount: parsed['amount'],
      direction: direction,
      description: parsed['description'],
      dueDate: DateTime.now().add(const Duration(days: 30)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await DatabaseService.addDebt(debt);
    return result;
  }

  /// Clean up resources
  void dispose() {
    _speech.stop();
    _tts.stop();
  }
}
