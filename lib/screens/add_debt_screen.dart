import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/voice_input_dialog_v2.dart';
import '../models/debt.dart';

class AddDebtScreen extends StatefulWidget {
  final String selectedLanguage;

  const AddDebtScreen({super.key, required this.selectedLanguage});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _debtDirection = 'owe'; // 'owe' or 'owed'
  DateTime _createdDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30)); // Default 30 days from now
  bool _isListening = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          _getText('addDebt'),
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
            // Debt Direction Selection
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _debtDirection = 'owe'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _debtDirection == 'owe'
                              ? const Color(0xFFF44336)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getText('youOwe'),
                          style: TextStyle(
                            color: _debtDirection == 'owe'
                                ? Colors.white
                                : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _debtDirection = 'owed'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _debtDirection == 'owed'
                              ? const Color(0xFF4CAF50)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getText('youAreOwed'),
                          style: TextStyle(
                            color: _debtDirection == 'owed'
                                ? Colors.white
                                : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Person Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: TextFormField(
                controller: _personController,
                decoration: InputDecoration(
                  labelText: _getText('personName'),
                  hintText: _getText('personHint'),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF46EC13)),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    onPressed: () {
                      // TODO: Open contact picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_getText('contactPicker')),
                          backgroundColor: const Color(0xFF46EC13),
                        ),
                      );
                    },
                    icon: const Icon(Icons.contacts, color: Colors.grey),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Amount Input Section
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getText('amount'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _startVoiceInput,
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? const Color(0xFF46EC13) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _debtDirection == 'owe'
                              ? const Color(0xFFF44336)
                              : const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              fontSize: 32,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                          ),
                          autofocus: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Creation Date Selection
            GestureDetector(
              onTap: _selectCreationDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Color(0xFF46EC13)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getText('creationDate'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_createdDate.day}/${_createdDate.month}/${_createdDate.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Due Date Selection
            GestureDetector(
              onTap: _selectDueDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _dueDate.isBefore(DateTime.now())
                        ? Colors.red.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.3),
                    width: _dueDate.isBefore(DateTime.now()) ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.alarm,
                      color: _dueDate.isBefore(DateTime.now())
                          ? const Color(0xFFF44336)
                          : const Color(0xFF46EC13),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getText('dueDate'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _dueDate.isBefore(DateTime.now())
                                  ? const Color(0xFFF44336)
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Notes Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _getText('notes'),
                  hintText: _getText('notesHint'),
                  prefixIcon: const Icon(Icons.note_add, color: Color(0xFF46EC13)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit() ? _submitDebt : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _debtDirection == 'owe'
                      ? const Color(0xFFF44336)
                      : const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _getText('saveDebt'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Debt Monster Animation Preview
            if (_amountController.text.isNotEmpty && _debtDirection == 'owe')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF44336).withOpacity(0.1),
                      const Color(0xFFF44336).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sentiment_dissatisfied,
                      color: Color(0xFFF44336),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getText('debtMonsterGrows'),
                        style: const TextStyle(
                          color: Color(0xFFF44336),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    return _amountController.text.isNotEmpty &&
           _personController.text.isNotEmpty &&
           !_isLoading;
  }

  Future<void> _startVoiceInput() async {
    setState(() {
      _isListening = true;
    });

    // Show new voice input dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceInputDialogV2(
        initialLanguage: widget.selectedLanguage,
        onComplete: (success) {
          if (success) {
            // Transaction was created, go back
            Navigator.of(context).pop(true);
          }
        },
      ),
    );

    setState(() {
      _isListening = false;
    });

    // If transaction was created, close this screen
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _selectCreationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _createdDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF46EC13),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _createdDate) {
      setState(() {
        _createdDate = picked;
        // If due date is before new creation date, adjust it
        if (_dueDate.isBefore(_createdDate)) {
          _dueDate = _createdDate.add(const Duration(days: 30));
        }
      });
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(_createdDate) 
          ? _createdDate 
          : _dueDate,
      firstDate: _createdDate,
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF46EC13),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _submitDebt() async {
    if (!_canSubmit()) return;
    
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create debt object
      final debt = Debt(
        userId: currentUser.id!,
        personName: _personController.text.trim(),
        amount: double.parse(_amountController.text),
        direction: _debtDirection,
        description: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        dueDate: _dueDate,
        createdAt: _createdDate,
        updatedAt: DateTime.now(),
      );

      // Save to database
      final result = await DatabaseService.addDebt(debt);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Schedule debt reminders
        NotificationService.scheduleDebtReminders();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getText('debtSaved')),
            backgroundColor: _debtDirection == 'owe'
                ? const Color(0xFFF44336)
                : const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Go back to home
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save debt'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getText(String key) {
    final texts = {
      'hi': {
        'addDebt': 'कर्ज जोड़ें',
        'youOwe': 'आप पर कर्ज',
        'youAreOwed': 'आपको मिलना है',
        'personName': 'व्यक्ति का नाम',
        'personHint': 'किससे/किसको',
        'contactPicker': 'संपर्क चुनें',
        'amount': 'राशि',
        'creationDate': 'कर्ज बनाने की तारीख',
        'dueDate': 'भुगतान की अंतिम तिथि',
        'notes': 'नोट्स',
        'notesHint': 'कर्ज का कारण...',
        'saveDebt': 'कर्ज सेव करें',
        'debtSaved': 'कर्ज सफलतापूर्वक सेव हुआ!',
        'debtMonsterGrows': 'कर्ज राक्षस बढ़ रहा है! जल्दी चुकता करें',
      },
      'mr': {
        'addDebt': 'कर्ज जोडा',
        'youOwe': 'तुमचे कर्ज',
        'youAreOwed': 'तुम्हाला मिळणे',
        'personName': 'व्यक्तीचे नाव',
        'personHint': 'कोणाकडून/कोणाला',
        'contactPicker': 'संपर्क निवडा',
        'amount': 'रक्कम',
        'creationDate': 'कर्ज तयार करण्याची तारीख',
        'dueDate': 'देय तारीख',
        'notes': 'नोट्स',
        'notesHint': 'कर्जाचे कारण...',
        'saveDebt': 'कर्ज सेव्ह करा',
        'debtSaved': 'कर्ज यशस्वीरित्या सेव्ह झाले!',
        'debtMonsterGrows': 'कर्ज राक्षस वाढत आहे! लवकर फेडा',
      },
      'en': {
        'addDebt': 'Add Debt',
        'youOwe': 'You Owe',
        'youAreOwed': 'You Are Owed',
        'personName': 'Person Name',
        'personHint': 'From/To whom',
        'contactPicker': 'Choose Contact',
        'amount': 'Amount',
        'creationDate': 'Debt Created On',
        'dueDate': 'Due Date',
        'notes': 'Notes',
        'notesHint': 'Reason for debt...',
        'saveDebt': 'Save Debt',
        'debtSaved': 'Debt saved successfully!',
        'debtMonsterGrows': 'Debt monster is growing! Repay soon',
      },
    };

    return texts[widget.selectedLanguage]?[key] ?? texts['en']![key]!;
  }

  String _getVoiceText(String key) {
    final texts = {
      'hi': {'detected': 'कर्ज पहचाना गया'},
      'mr': {'detected': 'कर्ज ओळखले'},
      'en': {'detected': 'Debt detected'},
    };
    return texts[widget.selectedLanguage]?[key] ?? texts['en']![key]!;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _personController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
