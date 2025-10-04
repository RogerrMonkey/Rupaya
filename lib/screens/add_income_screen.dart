import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/income.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AddIncomeScreen extends StatefulWidget {
  final String selectedLanguage;

  const AddIncomeScreen({super.key, required this.selectedLanguage});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _fromWhomController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'salary'; // salary, freelance, business, gift, other
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isRecurring = false;
  String _frequency = 'monthly'; // daily, weekly, monthly
  int? _recurringDay;

  // Language-specific text
  Map<String, Map<String, String>> get _texts => {
    'hi': {
      'title': 'आय जोड़ें',
      'subtitle': 'अपनी आय का विवरण दर्ज करें',
      'amount': 'राशि',
      'amountPlaceholder': '₹ 5000',
      'source': 'स्रोत',
      'sourcePlaceholder': 'वेतन, व्यवसाय, फ्रीलांस, आदि',
      'fromWhom': 'किससे मिली',
      'fromWhomPlaceholder': 'कंपनी/व्यक्ति का नाम',
      'description': 'विवरण (वैकल्पिक)',
      'descriptionPlaceholder': 'अतिरिक्त जानकारी',
      'type': 'प्रकार',
      'date': 'दिनांक',
      'salary': 'वेतन',
      'freelance': 'फ्रीलांसिंग',
      'business': 'व्यवसाय',
      'gift': 'उपहार',
      'other': 'अन्य',
      'isRecurring': 'नियमित आय',
      'frequency': 'आवृत्ति',
      'daily': 'दैनिक',
      'weekly': 'साप्ताहिक',
      'monthly': 'मासिक',
      'dayOfWeek': 'सप्ताह का दिन',
      'dayOfMonth': 'महीने का दिन',
      'addIncome': 'आय जोड़ें',
      'cancel': 'रद्द करें',
      'success': 'आय सफलतापूर्वक जोड़ी गई!',
      'error': 'आय जोड़ने में त्रुटि',
      'fillAllFields': 'कृपया सभी आवश्यक फील्ड भरें',
      'invalidAmount': 'कृपया वैध राशि दर्ज करें',
    },
    'mr': {
      'title': 'उत्पन्न जोडा',
      'subtitle': 'तुमच्या उत्पन्नाचे तपशील टाका',
      'amount': 'रक्कम',
      'amountPlaceholder': '₹ 5000',
      'source': 'स्रोत',
      'sourcePlaceholder': 'पगार, व्यवसाय, फ्रीलान्स, इत्यादी',
      'fromWhom': 'कोणाकडून मिळाली',
      'fromWhomPlaceholder': 'कंपनी/व्यक्तीचे नाव',
      'description': 'विवरण (पर्यायी)',
      'descriptionPlaceholder': 'अतिरिक्त माहिती',
      'type': 'प्रकार',
      'date': 'दिनांक',
      'salary': 'पगार',
      'freelance': 'फ्रीलान्सिंग',
      'business': 'व्यवसाय',
      'gift': 'भेट',
      'other': 'इतर',
      'isRecurring': 'नियमित उत्पन्न',
      'frequency': 'वारंवारता',
      'daily': 'दैनिक',
      'weekly': 'साप्ताहिक',
      'monthly': 'मासिक',
      'dayOfWeek': 'आठवड्याचा दिवस',
      'dayOfMonth': 'महिन्याचा दिवस',
      'addIncome': 'उत्पन्न जोडा',
      'cancel': 'रद्द करा',
      'success': 'उत्पन्न यशस्वीरित्या जोडले!',
      'error': 'उत्पन्न जोडण्यात त्रुटी',
      'fillAllFields': 'कृपया सर्व आवश्यक फील्ड भरा',
      'invalidAmount': 'कृपया वैध रक्कम टाका',
    },
    'en': {
      'title': 'Add Income',
      'subtitle': 'Enter your income details',
      'amount': 'Amount',
      'amountPlaceholder': '₹ 5000',
      'source': 'Source',
      'sourcePlaceholder': 'Salary, Business, Freelance, etc.',
      'fromWhom': 'From Whom',
      'fromWhomPlaceholder': 'Company/Person name',
      'description': 'Description (Optional)',
      'descriptionPlaceholder': 'Additional information',
      'type': 'Type',
      'date': 'Date',
      'salary': 'Salary',
      'freelance': 'Freelancing',
      'business': 'Business',
      'gift': 'Gift',
      'other': 'Other',
      'isRecurring': 'Recurring Income',
      'frequency': 'Frequency',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'dayOfWeek': 'Day of Week',
      'dayOfMonth': 'Day of Month',
      'addIncome': 'Add Income',
      'cancel': 'Cancel',
      'success': 'Income added successfully!',
      'error': 'Error adding income',
      'fillAllFields': 'Please fill all required fields',
      'invalidAmount': 'Please enter a valid amount',
    },
  };

  String _getText(String key) {
    return _texts[widget.selectedLanguage]?[key] ?? _texts['en']![key]!;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _fromWhomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF46EC13),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getDayName(int day) {
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return dayNames[day - 1];
  }

  Future<void> _addIncome() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getText('invalidAmount')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final income = Income(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser.id!,
        amount: amount,
        source: _sourceController.text.trim(),
        fromWhom: _fromWhomController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        date: _selectedDate,
        type: _selectedType,
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _frequency : null,
        recurringDay: _isRecurring ? _recurringDay : null,
        createdAt: DateTime.now(),
      );

      final success = await DatabaseService.addIncome(income);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getText('success')),
              backgroundColor: const Color(0xFF46EC13),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception('Failed to add income');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getText('error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getText('title'),
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getText('subtitle'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Amount field
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _getText('amount'),
                            hintText: _getText('amountPlaceholder'),
                            prefixIcon: const Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _getText('fillAllFields');
                            }
                            final amount = double.tryParse(value.trim());
                            if (amount == null || amount <= 0) {
                              return _getText('invalidAmount');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Source field
                        TextFormField(
                          controller: _sourceController,
                          decoration: InputDecoration(
                            labelText: _getText('source'),
                            hintText: _getText('sourcePlaceholder'),
                            prefixIcon: const Icon(Icons.source),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _getText('fillAllFields');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // From Whom field
                        TextFormField(
                          controller: _fromWhomController,
                          decoration: InputDecoration(
                            labelText: _getText('fromWhom'),
                            hintText: _getText('fromWhomPlaceholder'),
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _getText('fillAllFields');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Type field
                        DropdownButtonFormField<String>(
                          initialValue: _selectedType,
                          decoration: InputDecoration(
                            labelText: _getText('type'),
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(value: 'salary', child: Text(_getText('salary'))),
                            DropdownMenuItem(value: 'freelance', child: Text(_getText('freelance'))),
                            DropdownMenuItem(value: 'business', child: Text(_getText('business'))),
                            DropdownMenuItem(value: 'gift', child: Text(_getText('gift'))),
                            DropdownMenuItem(value: 'other', child: Text(_getText('other'))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date field
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: _getText('date'),
                              prefixIcon: const Icon(Icons.date_range),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
                              ),
                            ),
                            child: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Recurring Income Toggle
                        CheckboxListTile(
                          title: Text(_getText('isRecurring')),
                          value: _isRecurring,
                          activeColor: const Color(0xFF46EC13),
                          onChanged: (value) {
                            setState(() {
                              _isRecurring = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),

                        // Show frequency options if recurring
                        if (_isRecurring) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _frequency,
                            decoration: InputDecoration(
                              labelText: _getText('frequency'),
                              prefixIcon: const Icon(Icons.repeat),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(value: 'daily', child: Text(_getText('daily'))),
                              DropdownMenuItem(value: 'weekly', child: Text(_getText('weekly'))),
                              DropdownMenuItem(value: 'monthly', child: Text(_getText('monthly'))),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _frequency = value!;
                                _recurringDay = null; // Reset day when frequency changes
                              });
                            },
                          ),
                          
                          // Day selection for weekly/monthly
                          if (_frequency == 'weekly' || _frequency == 'monthly') ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              value: _recurringDay,
                              decoration: InputDecoration(
                                labelText: _frequency == 'weekly' 
                                    ? _getText('dayOfWeek') 
                                    : _getText('dayOfMonth'),
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
                                ),
                              ),
                              items: _frequency == 'weekly'
                                  ? List.generate(7, (index) => index + 1)
                                      .map((day) => DropdownMenuItem<int>(
                                            value: day,
                                            child: Text(_getDayName(day)),
                                          ))
                                      .toList()
                                  : List.generate(31, (index) => index + 1)
                                      .map((day) => DropdownMenuItem<int>(
                                            value: day,
                                            child: Text('Day $day'),
                                          ))
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _recurringDay = value;
                                });
                              },
                            ),
                          ],
                        ],
                        
                        const SizedBox(height: 16),

                        // Description field (optional)
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: _getText('description'),
                            hintText: _getText('descriptionPlaceholder'),
                            prefixIcon: const Icon(Icons.description),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF46EC13), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFF46EC13)),
                        ),
                        child: Text(
                          _getText('cancel'),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF46EC13),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addIncome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF46EC13),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _getText('addIncome'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}