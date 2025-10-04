import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/expense.dart';
import '../models/debt.dart';

class InsightsScreen extends StatefulWidget {
  final String selectedLanguage;

  const InsightsScreen({super.key, required this.selectedLanguage});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // Real data from database
  Map<String, double> weeklyExpenses = {};
  Map<String, double> categoryExpenses = {};
  List<Expense> recentExpenses = [];
  double monthlyTotal = 0.0;
  double dailyAverage = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInsightsData();
  }

  @override
  void didUpdateWidget(InsightsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh data when widget updates
    _loadInsightsData();
  }

  Future<void> _loadInsightsData() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Get current month expenses
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      // Load expenses for current month
      recentExpenses = await DatabaseService.getExpensesForUser(currentUser.id!);
      
      // Filter for current month
      final monthlyExpenses = recentExpenses.where((expense) {
        return expense.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
               expense.date.isBefore(monthEnd.add(const Duration(days: 1)));
      }).toList();

      // Calculate monthly total
      monthlyTotal = monthlyExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      
      // Calculate daily average
      final daysInMonth = monthEnd.day;
      dailyAverage = monthlyTotal / daysInMonth;

      // Calculate category expenses
      categoryExpenses.clear();
      for (final expense in monthlyExpenses) {
        categoryExpenses[expense.category] = 
            (categoryExpenses[expense.category] ?? 0.0) + expense.amount;
      }

      // Calculate weekly expenses (last 7 days)
      weeklyExpenses.clear();
      final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayName = weekDays[date.weekday - 1];
        final dayExpenses = monthlyExpenses.where((expense) {
          return expense.date.year == date.year &&
                 expense.date.month == date.month &&
                 expense.date.day == date.day;
        }).fold(0.0, (sum, expense) => sum + expense.amount);
        weeklyExpenses[dayName] = dayExpenses;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading insights data: $e');
      setState(() {
        isLoading = false;
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
        automaticallyImplyLeading: false,
        title: Text(
          _getText('insights'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF46EC13),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF46EC13),
          tabs: [
            Tab(text: _getText('spending')),
            Tab(text: _getText('trends')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSpendingTab(),
          _buildTrendsTab(),
        ],
      ),
    );
  }

  Widget _buildSpendingTab() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF46EC13),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF46EC13), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getText('thisMonth'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLoading ? '₹--' : '₹${monthlyTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getText('totalSpent'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Category Breakdown
          Text(
            _getText('categoryBreakdown'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 16),

          ...categoryExpenses.entries.map((entry) {
            final percentage = (entry.value / 18500) * 100;
            return _buildCategoryCard(entry.key, entry.value, percentage);
          }).toList(),

          const SizedBox(height: 24),

          // AI Insights
          Text(
            _getText('aiInsights'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 16),

          _buildInsightCard(
            icon: Icons.trending_up,
            title: _getText('spendingUp'),
            description: _getText('spendingUpDesc'),
            color: const Color(0xFFFF5722),
          ),

          const SizedBox(height: 12),

          _buildInsightCard(
            icon: Icons.lightbulb_outline,
            title: _getText('savingTip'),
            description: _getText('savingTipDesc'),
            color: const Color(0xFF46EC13),
          ),

          const SizedBox(height: 12),

          _buildInsightCard(
            icon: Icons.warning_outlined,
            title: _getText('debtAlert'),
            description: _getText('debtAlertDesc'),
            color: const Color(0xFFF44336),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF46EC13),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Spending Chart
          Text(
            _getText('weeklySpending'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 16),

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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: weeklyExpenses.keys.map((day) {
                    return Text(
                      day.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: weeklyExpenses.values.map((amount) {
                    final height = (amount / 1200) * 120; // Normalize to max height
                    return Container(
                      width: 24,
                      height: height,
                      decoration: BoxDecoration(
                        color: const Color(0xFF46EC13),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: weeklyExpenses.values.map((amount) {
                    return Text(
                      '₹${amount.toInt()}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Progress Goals
          Text(
            _getText('savingsGoals'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 16),

          _buildGoalCard(
            title: _getText('emergencyFund'),
            current: 15000,
            target: 50000,
            color: const Color(0xFF4CAF50),
          ),

          const SizedBox(height: 12),

          _buildGoalCard(
            title: _getText('debtRepayment'),
            current: 2000,
            target: 5000,
            color: const Color(0xFFF44336),
          ),

          const SizedBox(height: 24),

          // Monthly Comparison
          Text(
            _getText('monthlyComparison'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 16),

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
              children: [
                _buildComparisonRow(_getText('thisMonth'), monthlyTotal, const Color(0xFF46EC13)),
                const SizedBox(height: 12),
                _buildComparisonRow(_getText('lastMonth'), 0.0, Colors.grey), // TODO: Calculate last month
                const SizedBox(height: 12),
                _buildComparisonRow(_getText('average'), dailyAverage, const Color(0xFF2196F3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category, double amount, double percentage) {
    final categoryData = _getCategoryData(category);

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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: categoryData['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              categoryData['icon'],
              color: categoryData['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getText(category),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(categoryData['color']),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${amount.toInt()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${percentage.toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required double current,
    required double target,
    required Color color,
  }) {
    final progress = current / target;

    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${current.toInt()}',
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₹${target.toInt()}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '₹${amount.toInt()}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getCategoryData(String category) {
    final categoryMap = {
      'food': {'icon': Icons.restaurant, 'color': const Color(0xFFFF5722)},
      'travel': {'icon': Icons.directions_bus, 'color': const Color(0xFF2196F3)},
      'bills': {'icon': Icons.receipt, 'color': const Color(0xFFF44336)},
      'shopping': {'icon': Icons.shopping_bag, 'color': const Color(0xFF9C27B0)},
      'health': {'icon': Icons.local_hospital, 'color': const Color(0xFF4CAF50)},
    };

    return categoryMap[category] ?? {'icon': Icons.category, 'color': Colors.grey};
  }

  String _getText(String key) {
    final texts = {
      'hi': {
        'insights': 'अंतर्दृष्टि',
        'spending': 'खर्च',
        'trends': 'रुझान',
        'thisMonth': 'इस महीने',
        'totalSpent': 'कुल खर्च',
        'categoryBreakdown': 'श्रेणी के अनुसार खर्च',
        'food': 'भोजन',
        'travel': 'यात्रा',
        'bills': 'बिल',
        'shopping': 'खरीदारी',
        'health': 'स्वास्थ्य',
        'aiInsights': 'AI अंतर्दृष्टि',
        'spendingUp': 'खर्च बढ़ा है',
        'spendingUpDesc': 'पिछले महीने से 14% अधिक खर्च',
        'savingTip': 'बचत का सुझाव',
        'savingTipDesc': 'रोज ₹50 बचाने से महीने में ₹1,500 जमा होंगे',
        'debtAlert': 'कर्ज चेतावनी',
        'debtAlertDesc': '₹5,000 का कर्ज बकाया है',
        'weeklySpending': 'साप्ताहिक खर्च',
        'savingsGoals': 'बचत लक्ष्य',
        'emergencyFund': 'आपातकालीन फंड',
        'debtRepayment': 'कर्ज चुकता',
        'monthlyComparison': 'मासिक तुलना',
        'lastMonth': 'पिछला महीना',
        'average': 'औसत',
      },
      'mr': {
        'insights': 'अंतर्दृष्टी',
        'spending': 'खर्च',
        'trends': 'ट्रेंड',
        'thisMonth': 'या महिन्यात',
        'totalSpent': 'एकूण खर्च',
        'categoryBreakdown': 'श्रेणीनुसार खर्च',
        'food': 'जेवण',
        'travel': 'प्रवास',
        'bills': 'बिले',
        'shopping': 'खरेदी',
        'health': 'आरोग्य',
        'aiInsights': 'AI अंतर्दृष्टी',
        'spendingUp': 'खर्च वाढला आहे',
        'spendingUpDesc': 'गेल्या महिन्यापेक्षा 14% जास्त खर्च',
        'savingTip': 'बचतीचा सल्ला',
        'savingTipDesc': 'रोज ₹50 बचत केल्यास महिन्यात ₹1,500 जमा होतील',
        'debtAlert': 'कर्ज चेतावणी',
        'debtAlertDesc': '₹5,000 चे कर्ज बाकी आहे',
        'weeklySpending': 'साप्ताहिक खर्च',
        'savingsGoals': 'बचत लक्ष्य',
        'emergencyFund': 'आपत्कालीन फंड',
        'debtRepayment': 'कर्ज फेड',
        'monthlyComparison': 'मासिक तुलना',
        'lastMonth': 'गेला महिना',
        'average': 'सरासरी',
      },
      'en': {
        'insights': 'Insights',
        'spending': 'Spending',
        'trends': 'Trends',
        'thisMonth': 'This Month',
        'totalSpent': 'Total Spent',
        'categoryBreakdown': 'Category Breakdown',
        'food': 'Food',
        'travel': 'Travel',
        'bills': 'Bills',
        'shopping': 'Shopping',
        'health': 'Health',
        'aiInsights': 'AI Insights',
        'spendingUp': 'Spending Increased',
        'spendingUpDesc': '14% more than last month',
        'savingTip': 'Saving Tip',
        'savingTipDesc': 'Save ₹50 daily to collect ₹1,500 monthly',
        'debtAlert': 'Debt Alert',
        'debtAlertDesc': '₹5,000 debt is pending',
        'weeklySpending': 'Weekly Spending',
        'savingsGoals': 'Savings Goals',
        'emergencyFund': 'Emergency Fund',
        'debtRepayment': 'Debt Repayment',
        'monthlyComparison': 'Monthly Comparison',
        'lastMonth': 'Last Month',
        'average': 'Average',
      },
    };

    return texts[widget.selectedLanguage]?[key] ?? texts['en']![key]!;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
