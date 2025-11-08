import 'package:flutter/material.dart';
import 'add_expense_screen.dart';
import 'add_debt_screen.dart';
import 'add_income_screen.dart';
import 'income_management_screen.dart';
import 'debt_management_screen.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/user.dart';
import '../models/expense.dart';
import '../models/debt.dart';

class HomeScreen extends StatefulWidget {
  final String selectedLanguage;

  const HomeScreen({super.key, required this.selectedLanguage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _debtMonsterController;
  late Animation<double> _monsterAnimation;

  // Real financial data
  User? _currentUser;
  double _netBalance = 0.0;
  double _totalDebtOwed = 0.0;
  double _totalDebtToCollect = 0.0;
  List<Expense> _recentExpenses = [];
  List<Debt> _activeDebts = [];
  bool _isLoading = true;

  void _onUserStateChanged() {
    setState(() {
      _currentUser = AuthService.currentUser;
    });
    _loadFinancialData();
  }

  @override
  void initState() {
    super.initState();
    _currentUser = AuthService.currentUser;
    AuthService.addListener(_onUserStateChanged);
    
    _debtMonsterController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _monsterAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _debtMonsterController, curve: Curves.easeInOut),
    );

    _loadFinancialData();
    
    // Schedule all notifications
    NotificationService.scheduleAllNotifications();
    
    // Schedule all notifications
    NotificationService.scheduleAllNotifications();
  }

  @override
  void dispose() {
    AuthService.removeListener(_onUserStateChanged);
    _debtMonsterController.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialData() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load current month balance
      final now = DateTime.now();

      _netBalance = await DatabaseService.getMonthlyNetBalance(_currentUser!.id!, now);

      // Load debt summary
      final debtSummary = await DatabaseService.getDebtSummary(_currentUser!.id!);
      _totalDebtOwed = debtSummary['totalOwed'] ?? 0.0;
      _totalDebtToCollect = debtSummary['totalOwedBy'] ?? 0.0;

      // Load recent expenses and debts
      _recentExpenses = await DatabaseService.getExpensesForUser(_currentUser!.id!, limit: 5);
      _activeDebts = await DatabaseService.getDebtsForUser(_currentUser!.id!);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading financial data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double get _debtProgress {
    if (_activeDebts.isEmpty) return 0.0;
    
    double totalAmount = 0.0;
    double totalPaid = 0.0;
    
    for (final debt in _activeDebts) {
      if (debt.direction == 'owe') {
        totalAmount += debt.amount;
        totalPaid += debt.paidAmount;
      }
    }
    
    return totalAmount > 0 ? (totalPaid / totalAmount) : 0.0;
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    return _currentUser != null 
        ? '$greeting, ${_currentUser!.name.split(' ').first}!'
        : _getText('goodMorning');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreetingMessage(),
              style: TextStyle(
                fontSize: 15,
                color: Colors.black.withOpacity(0.6),
                fontWeight: FontWeight.normal,
              ),
            ),
            Text(
              _getText('welcome'),
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF46EC13),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Total Money Balance Card
            _buildTotalMoneyCard(),

            const SizedBox(height: 14),

            // Debt Visualization Section
            _buildDebtSection(),

            const SizedBox(height: 14),

            // Quick Actions
            Text(
              _getText('quickActions'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 13),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    title: _getText('addIncome'),
                    icon: Icons.trending_up,
                    color: const Color(0xFF4CAF50),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddIncomeScreen(selectedLanguage: widget.selectedLanguage),
                        ),
                      );
                      // Refresh data when returning
                      _loadFinancialData();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    title: _getText('addExpense'),
                    icon: Icons.remove_circle_outline,
                    color: const Color(0xFFFF5722),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddExpenseScreen(selectedLanguage: widget.selectedLanguage),
                        ),
                      );
                      // Refresh data when returning
                      _loadFinancialData();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    title: _getText('addDebt'),
                    icon: Icons.group,
                    color: const Color(0xFF9C27B0),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddDebtScreen(selectedLanguage: widget.selectedLanguage),
                        ),
                      );
                      // Refresh data when returning
                      _loadFinancialData();
                    },
                  ),
                ),
              ],
            ),


          ],
        ),
      ),
    );
  }

  Widget _buildTotalMoneyCard() {
    final bool isPositive = _netBalance >= 0;
    final Color balanceColor = isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final IconData balanceIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncomeManagementScreen(
              selectedLanguage: widget.selectedLanguage,
            ),
          ),
        );
        _loadFinancialData();
      },
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPositive 
              ? [const Color(0xFF46EC13), const Color(0xFF34D399)]
              : [const Color(0xFFF44336), const Color(0xFFEF5350)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: balanceColor.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        balanceIcon,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPositive ? _getText('surplus') : _getText('deficit'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              _getText('totalMoney'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _netBalance.abs().toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withOpacity(0.9),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getText('balanceInfo'),
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
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(icon, color: color, size: 24),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _getText('debtStatus'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 15),

          // Debt Monster Animation
          AnimatedBuilder(
            animation: _monsterAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _monsterAnimation.value * (1 - _debtProgress * 0.5),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _totalDebtOwed > 0 ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Icon(
                    _totalDebtOwed > 0 ? Icons.sentiment_dissatisfied : Icons.sentiment_very_satisfied,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 13),

          if (_totalDebtOwed > 0)
            LinearProgressIndicator(
              value: _debtProgress,
              backgroundColor: Colors.red.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _getText('youOwe'),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '₹${_totalDebtOwed.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF44336),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _getText('youAreOwed'),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '₹${_totalDebtToCollect.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // Manage Debts Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DebtManagementScreen(selectedLanguage: widget.selectedLanguage),
                  ),
                );
                // Refresh data when returning
                _loadFinancialData();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF46EC13), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                _getText('manageDebts'),
                style: const TextStyle(
                  color: Color(0xFF46EC13),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }



  String _getText(String key) {
    final texts = {
      'hi': {
        'goodMorning': 'शुभ प्रभात',
        'welcome': 'स्वागत है!',
        'moneyIn': 'आय',
        'moneyOut': 'व्यय',
        'totalMoney': 'कुल राशि',
        'surplus': 'बचत',
        'deficit': 'घाटा',
        'balanceInfo': 'आय + वापसी - व्यय - उधार',
        'debtStatus': 'कर्ज स्थिति',
        'youOwe': 'आप पर कर्ज',
        'youAreOwed': 'आपको मिलना है',
        'manageDebts': 'कर्ज प्रबंधन',
        'quickActions': 'त्वरित क्रियाएं',
        'addIncome': 'आय जोड़ें',
        'addExpense': 'व्यय जोड़ें',
        'addDebt': 'कर्ज जोड़ें',
        'transactionAdded': 'लेनदेन सफलतापूर्वक जोड़ा गया!',
      },
      'mr': {
        'goodMorning': 'शुभ सकाळ',
        'welcome': 'स्वागत आहे!',
        'moneyIn': 'उत्पन्न',
        'moneyOut': 'खर्च',
        'totalMoney': 'एकूण रक्कम',
        'surplus': 'बचत',
        'deficit': 'तूट',
        'balanceInfo': 'उत्पन्न + परतावा - खर्च - कर्ज',
        'debtStatus': 'कर्ज स्थिती',
        'youOwe': 'तुमचे कर्ज',
        'youAreOwed': 'तुम्हाला मिळणे',
        'quickActions': 'जलद कृती',
        'manageDebts': 'कर्ज व्यवस्थापन',
        'addIncome': 'उत्पन्न जोडा',
        'addExpense': 'खर्च जोडा',
        'addDebt': 'कर्ज जोडा',
        'transactionAdded': 'व्यवहार यशस्वीरित्या जोडला!',
      },
      'en': {
        'goodMorning': 'Good Morning',
        'welcome': 'Welcome!',
        'moneyIn': 'Money In',
        'moneyOut': 'Money Out',
        'totalMoney': 'Total Money',
        'surplus': 'Surplus',
        'deficit': 'Deficit',
        'balanceInfo': 'Income + Repayments - Expenses - Loans',
        'debtStatus': 'Debt Status',
        'youOwe': 'You Owe',
        'youAreOwed': 'You Are Owed',
        'quickActions': 'Quick Actions',
        'manageDebts': 'Manage Debts',
        'addIncome': 'Add Income',
        'addExpense': 'Add Expense',
        'addDebt': 'Add Debt',
        'transactionAdded': 'Transaction added successfully!',
      },
    };

    return texts[widget.selectedLanguage]?[key] ?? texts['en']![key]!;
  }

}
