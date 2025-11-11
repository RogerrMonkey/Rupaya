import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/insights_service.dart';
import '../models/expense.dart';
import '../models/income.dart';
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
  List<Expense> currentMonthExpenses = [];
  List<Expense> lastMonthExpenses = [];
  List<Income> currentMonthIncomes = [];
  List<Debt> debts = [];
  
  // Analytics data
  double monthlyTotal = 0.0;
  double dailyAverage = 0.0;
  List<Map<String, String>> localInsights = [];
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
    if (currentUser == null || currentUser.id == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final now = DateTime.now();
      final userId = currentUser.id!;

      // Load all expenses, incomes, and debts
      final allExpenses = await DatabaseService.getExpensesForUser(userId);
      final allIncomes = await DatabaseService.getIncomeForUser(userId);
      debts = await DatabaseService.getDebtsForUser(userId);

      // Filter current month expenses
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
      currentMonthExpenses = allExpenses.where((e) =>
        e.date.isAfter(currentMonthStart.subtract(const Duration(days: 1))) &&
        e.date.isBefore(currentMonthEnd.add(const Duration(days: 1)))
      ).toList();

      // Filter last month expenses
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);
      lastMonthExpenses = allExpenses.where((e) =>
        e.date.isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
        e.date.isBefore(lastMonthEnd.add(const Duration(days: 1)))
      ).toList();

      // Filter current month incomes
      currentMonthIncomes = allIncomes.where((i) =>
        i.date.isAfter(currentMonthStart.subtract(const Duration(days: 1))) &&
        i.date.isBefore(currentMonthEnd.add(const Duration(days: 1)))
      ).toList();

      // Use InsightsService for calculations
      monthlyTotal = InsightsService.calculateMonthlyTotal(currentMonthExpenses);
      dailyAverage = InsightsService.calculateDailyAverage(currentMonthExpenses);
      categoryExpenses = InsightsService.getCategoryBreakdown(currentMonthExpenses);
      weeklyExpenses = InsightsService.getWeeklyBreakdown(currentMonthExpenses);

      // Generate local insights
      localInsights = InsightsService.generateLocalInsights(
        currentMonthExpenses,
        currentMonthIncomes,
        debts,
      );

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

    } catch (e) {
      debugPrint('Error loading insights data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
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
        automaticallyImplyLeading: false,
        title: Text(
          _getText('insights'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF46EC13)),
            onPressed: () {
              _loadInsightsData();
            },
            tooltip: 'Refresh',
          ),
        ],
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

          const SizedBox(height: 16),

          // Expense Log Button
          GestureDetector(
            onTap: _showExpenseLogModal,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF46EC13), width: 2),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF46EC13).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Color(0xFF46EC13),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'View Expense Log',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${currentMonthExpenses.length} expenses this month',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF46EC13),
                    size: 20,
                  ),
                ],
              ),
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

          if (categoryExpenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _getText('noExpenses'),
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else
            ...categoryExpenses.entries.map((entry) {
              // Calculate percentage based on monthly total, avoid division by zero
              final percentage = monthlyTotal > 0 ? (entry.value / monthlyTotal) * 100 : 0.0;
              return _buildCategoryCard(entry.key, entry.value, percentage);
            }).toList(),

          const SizedBox(height: 24),

          // Insights Section
          Text(
            _getText('aiInsights'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 16),

          // Local Insights (Always Available)
          ...localInsights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildInsightCard(
              icon: _getIconForType(insight['icon'] ?? 'info'),
              title: insight['title'] ?? '',
              description: insight['description'] ?? '',
              color: _getColorForType(insight['type'] ?? 'info'),
            ),
          )).toList(),
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
            child: weeklyExpenses.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No spending data for this week',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Column(
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
                        // Find max value for normalization, avoid division by zero
                        final maxAmount = weeklyExpenses.values.reduce((a, b) => a > b ? a : b);
                        final normalizedMax = maxAmount > 0 ? maxAmount : 1.0;
                        final height = (amount / normalizedMax) * 120;
                        return Container(
                          width: 24,
                          height: height > 0 ? height : 2, // Minimum height of 2
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

          // Dynamic savings goals based on actual data
          if (currentMonthIncomes.isNotEmpty) ...[
            () {
              final ratio = InsightsService.getIncomeExpenseRatio(
                currentMonthIncomes,
                currentMonthExpenses,
              );
              final savings = (ratio['savings'] as num?)?.toDouble() ?? 0.0;
              final totalIncome = (ratio['totalIncome'] as num?)?.toDouble() ?? 0.0;
              
              return _buildGoalCard(
                title: 'Monthly Savings',
                current: savings.clamp(0.0, double.infinity),
                target: totalIncome > 0 ? totalIncome : 1.0, // Avoid division by zero
                color: const Color(0xFF4CAF50),
              );
            }(),
            const SizedBox(height: 12),
          ],

          // Debt repayment progress
          if (debts.isNotEmpty) ...[
            () {
              final debtSummary = InsightsService.getDebtSummary(debts);
              final totalDebt = (debtSummary['totalOwed'] as num?)?.toDouble() ?? 0.0;
              final paidAmount = debts
                  .where((d) => d.direction == 'owe')
                  .fold(0.0, (sum, d) => sum + d.paidAmount);
              
              return _buildGoalCard(
                title: _getText('debtRepayment'),
                current: paidAmount,
                target: totalDebt + paidAmount > 0 ? totalDebt + paidAmount : 1.0,
                color: const Color(0xFFF44336),
              );
            }(),
            const SizedBox(height: 12),
          ],

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
                _buildComparisonRow(
                  _getText('thisMonth'),
                  monthlyTotal,
                  const Color(0xFF46EC13),
                ),
                const SizedBox(height: 12),
                _buildComparisonRow(
                  _getText('lastMonth'),
                  InsightsService.calculateMonthlyTotal(lastMonthExpenses),
                  Colors.grey,
                ),
                const SizedBox(height: 12),
                _buildComparisonRow(
                  _getText('average'),
                  dailyAverage * DateTime.now().day,
                  const Color(0xFF2196F3),
                ),
              ],
            ),
          ),

          // Add spending velocity insight
          const SizedBox(height: 24),
          
          () {
            final velocity = InsightsService.getSpendingVelocity(currentMonthExpenses);
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF46EC13).withOpacity(0.1),
                    const Color(0xFF2E7D32).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF46EC13).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spending Velocity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Rate',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            '₹${((velocity['dailyRate'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF46EC13),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Projected Monthly',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            '₹${((velocity['projectedMonthly'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: () {
                      final elapsed = (velocity['daysElapsed'] as num?)?.toDouble() ?? 0.0;
                      final remaining = (velocity['daysRemaining'] as num?)?.toDouble() ?? 1.0;
                      final total = elapsed + remaining;
                      return total > 0 ? elapsed / total : 0.0;
                    }(),
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF46EC13)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(velocity['daysRemaining'] as num?)?.toInt() ?? 0} days remaining in month',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }(),
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
    bool isAI = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: isAI ? [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
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
      'transport': {'icon': Icons.directions_car, 'color': const Color(0xFF2196F3)},
      'bills': {'icon': Icons.receipt, 'color': const Color(0xFFF44336)},
      'shopping': {'icon': Icons.shopping_bag, 'color': const Color(0xFF9C27B0)},
      'health': {'icon': Icons.local_hospital, 'color': const Color(0xFF4CAF50)},
      'entertainment': {'icon': Icons.movie, 'color': const Color(0xFFFF9800)},
      'education': {'icon': Icons.school, 'color': const Color(0xFF3F51B5)},
      'personal': {'icon': Icons.person, 'color': const Color(0xFF607D8B)},
    };

    return categoryMap[category.toLowerCase()] ?? {'icon': Icons.category, 'color': Colors.grey};
  }

  IconData _getIconForType(String iconName) {
    final iconMap = {
      'trending_up': Icons.trending_up,
      'trending_down': Icons.trending_down,
      'category': Icons.category,
      'calendar_today': Icons.calendar_today,
      'account_balance_wallet': Icons.account_balance_wallet,
      'savings': Icons.savings,
      'warning': Icons.warning,
      'info': Icons.info,
      'lightbulb': Icons.lightbulb_outline,
      'check_circle': Icons.check_circle,
      'psychology': Icons.psychology,
      'error': Icons.error,
    };

    return iconMap[iconName] ?? Icons.info;
  }

  Color _getColorForType(String type) {
    final colorMap = {
      'warning': const Color(0xFFFF5722),
      'success': const Color(0xFF4CAF50),
      'tip': const Color(0xFF46EC13),
      'info': const Color(0xFF2196F3),
      'error': const Color(0xFFF44336),
    };

    return colorMap[type] ?? const Color(0xFF2196F3);
  }

  void _showExpenseLogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F8F6),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Expense Log',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${currentMonthExpenses.length} expenses • ₹${monthlyTotal.toStringAsFixed(0)} total',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              // Expense list
              Expanded(
                child: currentMonthExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start tracking your expenses',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: currentMonthExpenses.length,
                        itemBuilder: (context, index) {
                          // Sort expenses by date (newest first)
                          final sortedExpenses = List<Expense>.from(currentMonthExpenses)
                            ..sort((a, b) => b.date.compareTo(a.date));
                          final expense = sortedExpenses[index];
                          final categoryData = _getCategoryData(expense.category);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: (categoryData['color'] as Color).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  categoryData['icon'] as IconData,
                                  color: categoryData['color'] as Color,
                                  size: 24,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      expense.description ?? 'No description',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '₹${expense.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF44336),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF46EC13).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        expense.category,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF46EC13),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(expense.date),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) {
      return 'Today';
    } else if (expenseDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
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
        'noExpenses': 'No expenses this month',
      },
    };

    return texts[widget.selectedLanguage]?[key] ?? texts['en']?[key] ?? key;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
