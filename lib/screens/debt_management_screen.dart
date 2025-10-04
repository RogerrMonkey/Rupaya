import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/debt.dart';

class DebtManagementScreen extends StatefulWidget {
  final String selectedLanguage;

  const DebtManagementScreen({super.key, required this.selectedLanguage});

  @override
  State<DebtManagementScreen> createState() => _DebtManagementScreenState();
}

class _DebtManagementScreenState extends State<DebtManagementScreen> {
  List<Debt> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _debts = await DatabaseService.getDebtsForUser(currentUser.id!);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading debts: $e');
      setState(() {
        _isLoading = false;
      });
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          _getText('manageDebts'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF46EC13),
              ),
            )
          : _debts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 80,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getText('noDebts'),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF46EC13),
                  onRefresh: _loadDebts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _debts.length,
                    itemBuilder: (context, index) {
                      final debt = _debts[index];
                      return _buildDebtCard(debt);
                    },
                  ),
                ),
    );
  }

  Widget _buildDebtCard(Debt debt) {
    final isOwed = debt.direction == 'owed';
    final progressPercentage = debt.progressPercentage;
    final remainingAmount = debt.remainingAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isOwed ? const Color(0xFF4CAF50) : const Color(0xFFF44336))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isOwed ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isOwed ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.personName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isOwed ? _getText('owesYou') : _getText('youOwe'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${debt.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOwed ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                    ),
                  ),
                  if (debt.paidAmount > 0)
                    Text(
                      '₹${remainingAmount.toStringAsFixed(0)} left',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          if (debt.description != null && debt.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              debt.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.8),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Progress bar
          LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isOwed ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Text(
                '${(progressPercentage * 100).toStringAsFixed(0)}% ${_getText('paid')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              Text(
                _getText('due') + ': ${_formatDate(debt.dueDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.withOpacity(0.7),
                ),
              ),
            ],
          ),

          if (!debt.isSettled) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showPaymentDialog(debt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOwed ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isOwed ? _getText('markReceived') : _getText('markPaid'),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✓ ${_getText('settled')}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPaymentDialog(Debt debt) {
    final TextEditingController amountController = TextEditingController();
    final remainingAmount = debt.remainingAmount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getText('recordPayment')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getText('remaining')}: ₹${remainingAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: _getText('paymentAmount'),
                hintText: '0.00',
                prefixText: '₹',
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
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_getText('enterValidAmount')),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (amount > remainingAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_getText('amountTooHigh')),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _recordPayment(debt, amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF46EC13),
              foregroundColor: Colors.black,
            ),
            child: Text(_getText('record')),
          ),
        ],
      ),
    );
  }

  Future<void> _recordPayment(Debt debt, double amount) async {
    try {
      final result = await DatabaseService.updateDebtPayment(
        debtId: debt.id!,
        paymentAmount: amount,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: const Color(0xFF46EC13),
          ),
        );
        _loadDebts(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getText(String key) {
    final texts = {
      'hi': {
        'manageDebts': 'कर्ज़ प्रबंधन',
        'noDebts': 'कोई कर्ज़ नहीं मिला',
        'owesYou': 'आपको देना है',
        'youOwe': 'आप देते हैं',
        'paid': 'भुगतान',
        'due': 'देय',
        'markReceived': 'प्राप्त मार्क करें',
        'markPaid': 'भुगतान मार्क करें',
        'settled': 'निपटाया गया',
        'recordPayment': 'भुगतान रिकॉर्ड करें',
        'remaining': 'शेष',
        'paymentAmount': 'भुगतान राशि',
        'cancel': 'रद्द करें',
        'record': 'रिकॉर्ड करें',
        'enterValidAmount': 'कृपया वैध राशि दर्ज करें',
        'amountTooHigh': 'राशि शेष कर्ज़ से अधिक है',
      },
      'mr': {
        'manageDebts': 'कर्ज व्यवस्थापन',
        'noDebts': 'कोणतेही कर्ज सापडले नाही',
        'owesYou': 'तुम्हाला देणे आहे',
        'youOwe': 'तुम्ही देता',
        'paid': 'भुगतान',
        'due': 'देय',
        'markReceived': 'प्राप्त चिन्हांकित करा',
        'markPaid': 'भुगतान चिन्हांकित करा',
        'settled': 'निकाली केली',
        'recordPayment': 'भुगतान नोंदवा',
        'remaining': 'उरलेले',
        'paymentAmount': 'भुगतान रक्कम',
        'cancel': 'रद्द करा',
        'record': 'नोंदवा',
        'enterValidAmount': 'कृपया वैध रक्कम टाका',
        'amountTooHigh': 'रक्कम उरलेल्या कर्जापेक्षा जास्त आहे',
      },
      'en': {
        'manageDebts': 'Manage Debts',
        'noDebts': 'No debts found',
        'owesYou': 'owes you',
        'youOwe': 'you owe',
        'paid': 'paid',
        'due': 'Due',
        'markReceived': 'Mark Received',
        'markPaid': 'Mark Paid',
        'settled': 'Settled',
        'recordPayment': 'Record Payment',
        'remaining': 'Remaining',
        'paymentAmount': 'Payment Amount',
        'cancel': 'Cancel',
        'record': 'Record',
        'enterValidAmount': 'Please enter a valid amount',
        'amountTooHigh': 'Amount exceeds remaining debt',
      },
    };

    return texts[widget.selectedLanguage]?[key] ?? texts['en']![key]!;
  }
}