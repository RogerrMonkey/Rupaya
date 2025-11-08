import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final String selectedLanguage;

  const AddExpenseScreen({super.key, required this.selectedLanguage});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'food', 'icon': Icons.restaurant, 'color': Color(0xFFFF5722)},
    {'name': 'travel', 'icon': Icons.directions_bus, 'color': Color(0xFF2196F3)},
    {'name': 'bills', 'icon': Icons.receipt, 'color': Color(0xFFF44336)},
    {'name': 'shopping', 'icon': Icons.shopping_bag, 'color': Color(0xFF9C27B0)},
    {'name': 'health', 'icon': Icons.local_hospital, 'color': Color(0xFF4CAF50)},
    {'name': 'entertainment', 'icon': Icons.movie, 'color': Color(0xFFFF9800)},
    {'name': 'education', 'icon': Icons.school, 'color': Color(0xFF3F51B5)},
    {'name': 'savings', 'icon': Icons.savings, 'color': Color(0xFF2E7D32)},
    {'name': 'misc', 'icon': Icons.category, 'color': Color(0xFF607D8B)},
  ];

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
          _getText('addExpense'),
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF46EC13),
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

            // Category Selection
            Text(
              _getText('category'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['name'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category['color'].withOpacity(0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? category['color']
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'],
                          color: category['color'],
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getText(category['name']),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? category['color']
                                : Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Date Selection
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF46EC13)),
                    const SizedBox(width: 12),
                    Text(
                      _getText('date'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
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
                onPressed: _canSubmit() ? _submitExpense : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF46EC13),
                  foregroundColor: Colors.black,
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
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _getText('saveExpense'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    return _amountController.text.isNotEmpty &&
           _selectedCategory != null &&
           !_isLoading;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitExpense() async {
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
      // Create expense object
      final expense = Expense(
        userId: currentUser.id!,
        amount: double.parse(_amountController.text),
        category: _selectedCategory!,
        description: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        date: _selectedDate,
        createdAt: DateTime.now(),
      );

      // Save to database
      final result = await DatabaseService.addExpense(expense);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Check for budget alerts and savings goal progress
        NotificationService.checkAllProgress();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getText('expenseSaved')),
            backgroundColor: const Color(0xFF46EC13),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Go back to home
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save expense'),
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
        'addExpense': 'व्यय जोड़ें',
        'amount': 'राशि',
        'category': 'श्रेणी',
        'food': 'भोजन',
        'travel': 'यात्रा',
        'bills': 'बिल',
        'shopping': 'खरीदारी',
        'health': 'स्वास्थ्य',
        'entertainment': 'मनोरंजन',
        'education': 'शिक्षा',
        'savings': 'बचत',
        'misc': 'अन्य',
        'date': 'दिनांक',
        'notes': 'नोट्स',
        'notesHint': 'वैकल्पिक विवरण...',
        'saveExpense': 'व्यय सेव करें',
        'expenseSaved': 'व्यय सफलतापूर्वक सेव हुआ!',
      },
      'mr': {
        'addExpense': 'खर्च जोडा',
        'amount': 'रक्कम',
        'category': 'श्रेणी',
        'food': 'जेवण',
        'travel': 'प्रवास',
        'bills': 'बिले',
        'shopping': 'खरेदी',
        'health': 'आरोग्य',
        'entertainment': 'मनोरंजन',
        'education': 'शिक्षण',
        'savings': 'बचत',
        'misc': 'इतर',
        'date': 'दिनांक',
        'notes': 'नोट्स',
        'notesHint': 'वैकल्पिक तपशील...',
        'saveExpense': 'खर्च सेव्ह करा',
        'expenseSaved': 'खर्च यशस्वीरित्या सेव्ह झाला!',
      },
      'en': {
        'addExpense': 'Add Expense',
        'amount': 'Amount',
        'category': 'Category',
        'food': 'Food',
        'travel': 'Travel',
        'bills': 'Bills',
        'shopping': 'Shopping',
        'health': 'Health',
        'entertainment': 'Entertainment',
        'education': 'Education',
        'savings': 'Savings',
        'misc': 'Misc',
        'date': 'Date',
        'notes': 'Notes',
        'notesHint': 'Optional description...',
        'saveExpense': 'Save Expense',
        'expenseSaved': 'Expense saved successfully!',
      },
    };

    return texts[widget.selectedLanguage]?[key] ?? texts['en']![key]!;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
