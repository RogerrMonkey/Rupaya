import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/income.dart';
import '../models/expense.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'dart:math' as math;

class IncomeManagementScreen extends StatefulWidget {
  final String selectedLanguage;

  const IncomeManagementScreen({super.key, required this.selectedLanguage});

  @override
  State<IncomeManagementScreen> createState() => _IncomeManagementScreenState();
}

class _IncomeManagementScreenState extends State<IncomeManagementScreen> {
  User? _currentUser;
  List<Income> _incomeList = [];
  Map<String, double> _incomeBySource = {};
  double _totalIncome = 0.0;
  double _monthlyGoal = 0.0;
  double _currentSavings = 0.0;
  double _savingsTarget = 0.0;
  bool _isLoading = true;
  
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceText = '';

  @override
  void initState() {
    super.initState();
    _currentUser = AuthService.currentUser;
    _speech = stt.SpeechToText();
    _loadIncomeData();
  }

  Future<void> _loadIncomeData() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      
      // Get all income for the current month
      _incomeList = await DatabaseService.getIncomeForUser(_currentUser!.id!);
      
      // Filter for current month
      final currentMonthIncome = _incomeList.where((income) {
        return income.date.year == now.year && income.date.month == now.month;
      }).toList();

      // Calculate total
      _totalIncome = currentMonthIncome.fold(0.0, (sum, income) => sum + income.amount);

      // Group by source
      _incomeBySource = {};
      for (var income in currentMonthIncome) {
        _incomeBySource[income.source] = (_incomeBySource[income.source] ?? 0.0) + income.amount;
      }

      // Get user's monthly goal and savings goal
      final userResult = await DatabaseService.getUserById(_currentUser!.id!);
      if (userResult != null) {
        _monthlyGoal = userResult.monthlyIncomeGoal ?? 0.0;
        _savingsTarget = userResult.savingsGoal ?? (_monthlyGoal > 0 ? _monthlyGoal * 0.3 : 10000.0);
      }
      
      // Load savings data
      final allExpenses = await DatabaseService.getExpensesForUser(_currentUser!.id!);
      _currentSavings = allExpenses
          .where((e) => e.category == 'savings')
          .fold(0.0, (sum, e) => sum + e.amount);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading income data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Status: $status'),
      onError: (error) => print('Error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _voiceText = result.recognizedWords;
          });
          if (result.finalResult) {
            _processVoiceInput(_voiceText);
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _processVoiceInput(String text) {
    // Simple parsing for "Earned {amount}" pattern
    final regex = RegExp(r'earned\s+(\d+)', caseSensitive: false);
    final match = regex.firstMatch(text.toLowerCase());
    
    if (match != null) {
      final amount = double.tryParse(match.group(1)!);
      if (amount != null) {
        _showQuickAddDialog(amount);
      }
    }
  }

  Future<void> _showQuickAddDialog(double amount) async {
    final sourceController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getText('quickAdd')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_getText('amount')}: ₹${amount.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            TextField(
              controller: sourceController,
              decoration: InputDecoration(
                labelText: _getText('source'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final income = Income(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: _currentUser!.id!,
                amount: amount,
                source: sourceController.text.trim().isEmpty 
                    ? 'Voice Entry' 
                    : sourceController.text.trim(),
                date: DateTime.now(),
                type: 'other',
                createdAt: DateTime.now(),
              );
              
              await DatabaseService.addIncome(income);
              Navigator.pop(context);
              _loadIncomeData();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_getText('success')),
                  backgroundColor: const Color(0xFF46EC13),
                ),
              );
            },
            child: Text(_getText('add')),
          ),
        ],
      ),
    );
  }

  Future<void> _showSetGoalDialog() async {
    final goalController = TextEditingController(
      text: _monthlyGoal > 0 ? _monthlyGoal.toStringAsFixed(0) : '',
    );
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getText('setGoal')),
        content: TextField(
          controller: goalController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _getText('monthlyGoal'),
            prefixText: '₹ ',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final goal = double.tryParse(goalController.text.trim());
              if (goal != null) {
                await DatabaseService.updateUserIncomeGoal(_currentUser!.id!, goal);
                Navigator.pop(context);
                _loadIncomeData();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_getText('goalUpdated')),
                    backgroundColor: const Color(0xFF46EC13),
                  ),
                );
              }
            },
            child: Text(_getText('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _showSetSavingsGoalDialog() async {
    final goalController = TextEditingController(
      text: _savingsTarget > 0 ? _savingsTarget.toStringAsFixed(0) : '',
    );
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getText('setSavingsGoal')),
        content: TextField(
          controller: goalController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _getText('savingsGoalLabel'),
            prefixText: '₹ ',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getText('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final goal = double.tryParse(goalController.text.trim());
              if (goal != null && _currentUser != null) {
                await DatabaseService.updateUserSavingsGoal(_currentUser!.id!, goal);
                Navigator.pop(context);
                if (mounted) {
                  _loadIncomeData();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_getText('savingsGoalUpdated')),
                      backgroundColor: const Color(0xFFE91E63),
                    ),
                  );
                }
              }
            },
            child: Text(_getText('save')),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, String>> get _texts => {
    'hi': {
      'title': 'आय प्रबंधन',
      'totalIncome': 'कुल आय',
      'incomeGoal': 'आय लक्ष्य',
      'savingsGoal': 'बचत लक्ष्य',
      'setSavingsGoal': 'बचत लक्ष्य सेट करें',
      'savingsGoalLabel': 'बचत लक्ष्य राशि',
      'savingsGoalUpdated': 'बचत लक्ष्य अपडेट हो गया!',
      'saved': 'बचत',
      'target': 'लक्ष्य',
      'savingsTip': 'मासिक आय का 30% बचत करें',
      'incomeBreakdown': 'स्रोत के अनुसार आय',
      'voiceInput': 'बोलकर जोड़ें',
      'setGoal': 'लक्ष्य निर्धारित करें',
      'monthlyGoal': 'मासिक लक्ष्य',
      'quickAdd': 'त्वरित जोड़ें',
      'source': 'स्रोत',
      'cancel': 'रद्द करें',
      'add': 'जोड़ें',
      'save': 'सहेजें',
      'success': 'आय जोड़ी गई!',
      'goalUpdated': 'लक्ष्य अपडेट किया गया!',
      'amount': 'राशि',
      'listening': 'सुन रहा है...',
      'tapToSpeak': 'बोलने के लिए टैप करें',
      'noIncome': 'इस महीने कोई आय नहीं',
    },
    'mr': {
      'title': 'उत्पन्न व्यवस्थापन',
      'totalIncome': 'एकूण उत्पन्न',
      'incomeGoal': 'उत्पन्न लक्ष्य',
      'savingsGoal': 'बचत लक्ष्य',
      'setSavingsGoal': 'बचत लक्ष्य सेट करा',
      'savingsGoalLabel': 'बचत लक्ष्य रक्कम',
      'savingsGoalUpdated': 'बचत लक्ष्य अपडेट झाले!',
      'saved': 'बचत',
      'target': 'लक्ष्य',
      'savingsTip': 'मासिक उत्पन्नाच्या 30% बचत करा',
      'incomeBreakdown': 'स्रोतानुसार उत्पन्न',
      'voiceInput': 'बोलून जोडा',
      'setGoal': 'लक्ष्य सेट करा',
      'monthlyGoal': 'मासिक लक्ष्य',
      'quickAdd': 'जलद जोडा',
      'source': 'स्रोत',
      'cancel': 'रद्द करा',
      'add': 'जोडा',
      'save': 'जतन करा',
      'success': 'उत्पन्न जोडले!',
      'goalUpdated': 'लक्ष्य अपडेट झाले!',
      'amount': 'रक्कम',
      'listening': 'ऐकत आहे...',
      'tapToSpeak': 'बोलण्यासाठी टॅप करा',
      'noIncome': 'या महिन्यात उत्पन्न नाही',
    },
    'en': {
      'title': 'Income Management',
      'totalIncome': 'Total Income',
      'incomeGoal': 'Income Goal',
      'savingsGoal': 'Savings Goal',
      'setSavingsGoal': 'Set Savings Goal',
      'savingsGoalLabel': 'Savings Goal Amount',
      'savingsGoalUpdated': 'Savings goal updated!',
      'saved': 'saved',
      'target': 'target',
      'savingsTip': 'Save 30% of monthly income for financial security',
      'incomeBreakdown': 'Income by Source',
      'voiceInput': 'Voice Add',
      'setGoal': 'Set Goal',
      'monthlyGoal': 'Monthly Goal',
      'quickAdd': 'Quick Add',
      'source': 'Source',
      'cancel': 'Cancel',
      'add': 'Add',
      'save': 'Save',
      'success': 'Income added!',
      'goalUpdated': 'Goal updated!',
      'amount': 'Amount',
      'listening': 'Listening...',
      'tapToSpeak': 'Tap to speak',
      'noIncome': 'No income this month',
    },
  };

  String _getText(String key) {
    return _texts[widget.selectedLanguage]?[key] ?? _texts['en']![key]!;
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
          _getText('title'),
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag, color: Color(0xFF46EC13)),
            onPressed: _showSetGoalDialog,
          ),
          IconButton(
            icon: const Icon(Icons.savings, color: Color(0xFFE91E63)),
            onPressed: _showSetSavingsGoalDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Income Card
                  _buildTotalIncomeCard(),
                  const SizedBox(height: 16),

                  // Income Goal Progress
                  if (_monthlyGoal > 0) ...[
                    _buildGoalProgressCard(),
                    const SizedBox(height: 16),
                  ],

                  // Income Breakdown
                  _buildIncomeBreakdown(),
                  const SizedBox(height: 16),

                  // Voice Input Button
                  _buildVoiceInputButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalIncomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF46EC13), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getText('totalIncome'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_totalIncome.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressCard() {
    final progress = _monthlyGoal > 0 ? (_totalIncome / _monthlyGoal).clamp(0.0, 1.0) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getText('incomeGoal'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF46EC13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF46EC13)),
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_totalIncome.toStringAsFixed(0)} / ₹${_monthlyGoal.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGoalCard() {
    final savingsProgress = _savingsTarget > 0 ? (_currentSavings / _savingsTarget).clamp(0.0, 1.0) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.savings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getText('savingsGoal'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${(savingsProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: savingsProgress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${_currentSavings.toStringAsFixed(0)} ${_getText('saved')}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${_savingsTarget.toStringAsFixed(0)} ${_getText('target')}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getText('savingsTip'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeBreakdown() {
    if (_incomeBySource.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            _getText('noIncome'),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    final sortedSources = _incomeBySource.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getText('incomeBreakdown'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedSources.map((entry) {
            final percentage = _totalIncome > 0 ? (entry.value / _totalIncome) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '₹${entry.value.toStringAsFixed(0)} (${(percentage * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF46EC13),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getColorForIndex(sortedSources.indexOf(entry)),
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVoiceInputButton() {
    return GestureDetector(
      onTap: _isListening ? _stopListening : _startListening,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isListening ? const Color(0xFFFF5722) : const Color(0xFF46EC13),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              _isListening ? _getText('listening') : _getText('tapToSpeak'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF46EC13),
      const Color(0xFF2196F3),
      const Color(0xFFFFC107),
      const Color(0xFF9C27B0),
      const Color(0xFFFF5722),
    ];
    return colors[index % colors.length];
  }
}
