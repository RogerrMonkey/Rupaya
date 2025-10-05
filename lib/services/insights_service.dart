import '../models/expense.dart';
import '../models/income.dart';
import '../models/debt.dart';

/// Comprehensive service for analyzing spending patterns and generating insights
class InsightsService {
  
  /// Calculate monthly spending total
  static double calculateMonthlyTotal(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Calculate daily average spending
  static double calculateDailyAverage(List<Expense> expenses) {
    if (expenses.isEmpty) return 0.0;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final monthlyTotal = calculateMonthlyTotal(expenses);
    return monthlyTotal / daysInMonth;
  }

  /// Group expenses by category with totals
  static Map<String, double> getCategoryBreakdown(List<Expense> expenses) {
    final Map<String, double> breakdown = {};
    for (var expense in expenses) {
      breakdown[expense.category] = (breakdown[expense.category] ?? 0.0) + expense.amount;
    }
    // Sort by amount descending
    final sorted = Map.fromEntries(
      breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );
    return sorted;
  }

  /// Get top spending category
  static MapEntry<String, double>? getTopCategory(List<Expense> expenses) {
    final breakdown = getCategoryBreakdown(expenses);
    return breakdown.entries.isNotEmpty ? breakdown.entries.first : null;
  }

  /// Calculate category percentage of total
  static double getCategoryPercentage(String category, List<Expense> expenses) {
    final total = calculateMonthlyTotal(expenses);
    if (total == 0) return 0.0;
    final categoryTotal = expenses
        .where((e) => e.category == category)
        .fold(0.0, (sum, e) => sum + e.amount);
    return (categoryTotal / total) * 100;
  }

  /// Get weekly spending breakdown (last 7 days)
  static Map<String, double> getWeeklyBreakdown(List<Expense> expenses) {
    final Map<String, double> weekly = {
      'Mon': 0.0,
      'Tue': 0.0,
      'Wed': 0.0,
      'Thu': 0.0,
      'Fri': 0.0,
      'Sat': 0.0,
      'Sun': 0.0,
    };

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    for (var expense in expenses) {
      final daysDiff = expense.date.difference(weekStart).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][daysDiff];
        weekly[dayName] = (weekly[dayName] ?? 0.0) + expense.amount;
      }
    }

    return weekly;
  }

  /// Compare current month vs last month
  static Map<String, dynamic> getMonthlyComparison(
    List<Expense> currentMonthExpenses,
    List<Expense> lastMonthExpenses,
  ) {
    final currentTotal = calculateMonthlyTotal(currentMonthExpenses);
    final lastTotal = calculateMonthlyTotal(lastMonthExpenses);
    final difference = currentTotal - lastTotal;
    final percentageChange = lastTotal > 0 ? (difference / lastTotal) * 100 : 0.0;

    return {
      'currentMonth': currentTotal,
      'lastMonth': lastTotal,
      'difference': difference,
      'percentageChange': percentageChange,
      'increased': difference > 0,
    };
  }

  /// Get highest single expense
  static Expense? getHighestExpense(List<Expense> expenses) {
    if (expenses.isEmpty) return null;
    return expenses.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  /// Detect spending patterns (weekend vs weekday)
  static Map<String, dynamic> getSpendingPatterns(List<Expense> expenses) {
    double weekdayTotal = 0.0;
    double weekendTotal = 0.0;
    int weekdayCount = 0;
    int weekendCount = 0;

    for (var expense in expenses) {
      if (expense.date.weekday >= 6) {
        // Saturday = 6, Sunday = 7
        weekendTotal += expense.amount;
        weekendCount++;
      } else {
        weekdayTotal += expense.amount;
        weekdayCount++;
      }
    }

    final weekdayAvg = weekdayCount > 0 ? weekdayTotal / weekdayCount : 0.0;
    final weekendAvg = weekendCount > 0 ? weekendTotal / weekendCount : 0.0;

    return {
      'weekdayTotal': weekdayTotal,
      'weekendTotal': weekendTotal,
      'weekdayAverage': weekdayAvg,
      'weekendAverage': weekendAvg,
      'weekendSpendingHigher': weekendAvg > weekdayAvg,
      'ratio': weekdayAvg > 0 ? weekendAvg / weekdayAvg : 0.0,
    };
  }

  /// Calculate spending velocity (burn rate)
  static Map<String, dynamic> getSpendingVelocity(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return {
        'dailyRate': 0.0,
        'projectedMonthly': 0.0,
        'daysElapsed': 0,
        'onTrack': true,
      };
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final daysElapsed = now.difference(monthStart).inDays + 1;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    final currentTotal = calculateMonthlyTotal(expenses);
    final dailyRate = currentTotal / daysElapsed;
    final projectedMonthly = dailyRate * daysInMonth;

    return {
      'dailyRate': dailyRate,
      'projectedMonthly': projectedMonthly,
      'daysElapsed': daysElapsed,
      'daysRemaining': daysInMonth - daysElapsed,
      'currentTotal': currentTotal,
      'onTrack': true, // Can be compared with budget
    };
  }

  /// Get debt summary
  static Map<String, dynamic> getDebtSummary(List<Debt> debts) {
    final activeDebts = debts.where((d) => !d.isSettled).toList();
    
    double totalOwed = 0.0; // I owe others
    double totalReceivable = 0.0; // Others owe me
    
    for (var debt in activeDebts) {
      final remaining = debt.amount - debt.paidAmount;
      if (debt.direction == 'owe') {
        totalOwed += remaining;
      } else {
        totalReceivable += remaining;
      }
    }

    return {
      'totalDebts': activeDebts.length,
      'totalOwed': totalOwed,
      'totalReceivable': totalReceivable,
      'netPosition': totalReceivable - totalOwed,
      'hasOverdueDebts': activeDebts.any((d) => 
        d.dueDate != null && d.dueDate!.isBefore(DateTime.now())
      ),
    };
  }

  /// Calculate income vs expense ratio
  static Map<String, dynamic> getIncomeExpenseRatio(
    List<Income> incomes,
    List<Expense> expenses,
  ) {
    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final totalExpenses = calculateMonthlyTotal(expenses);
    final savings = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? (savings / totalIncome) * 100 : 0.0;

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'savings': savings,
      'savingsRate': savingsRate,
      'inProfit': savings > 0,
    };
  }

  /// Get category trends (comparing to average)
  static Map<String, dynamic> getCategoryTrends(
    String category,
    List<Expense> currentExpenses,
    List<Expense> historicalExpenses,
  ) {
    final currentTotal = currentExpenses
        .where((e) => e.category == category)
        .fold(0.0, (sum, e) => sum + e.amount);
    
    final historicalTotal = historicalExpenses
        .where((e) => e.category == category)
        .fold(0.0, (sum, e) => sum + e.amount);

    final averageHistorical = historicalExpenses.isNotEmpty 
        ? historicalTotal / historicalExpenses.length 
        : 0.0;
    
    final difference = currentTotal - averageHistorical;
    final percentageChange = averageHistorical > 0 
        ? (difference / averageHistorical) * 100 
        : 0.0;

    return {
      'current': currentTotal,
      'average': averageHistorical,
      'difference': difference,
      'percentageChange': percentageChange,
      'trending': percentageChange > 10 ? 'up' : (percentageChange < -10 ? 'down' : 'stable'),
    };
  }

  /// Generate rule-based insights (local, no API needed)
  static List<Map<String, String>> generateLocalInsights(
    List<Expense> expenses,
    List<Income> incomes,
    List<Debt> debts,
  ) {
    final insights = <Map<String, String>>[];
    
    if (expenses.isEmpty) {
      insights.add({
        'type': 'info',
        'title': 'No Expenses Yet',
        'description': 'Start tracking your expenses to see insights',
        'icon': 'info',
      });
      return insights;
    }

    // Monthly comparison insight
    final now = DateTime.now();
    final currentMonthExpenses = expenses.where((e) =>
      e.date.year == now.year && e.date.month == now.month
    ).toList();
    
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthExpenses = expenses.where((e) =>
      e.date.year == lastMonth.year && e.date.month == lastMonth.month
    ).toList();

    if (lastMonthExpenses.isNotEmpty) {
      final comparison = getMonthlyComparison(currentMonthExpenses, lastMonthExpenses);
      final change = comparison['percentageChange'].abs().toStringAsFixed(0);
      
      insights.add({
        'type': comparison['increased'] ? 'warning' : 'success',
        'title': comparison['increased'] ? 'Spending Increased' : 'Spending Decreased',
        'description': '${change}% ${comparison['increased'] ? 'more' : 'less'} than last month',
        'icon': comparison['increased'] ? 'trending_up' : 'trending_down',
      });
    }

    // Top category insight
    final topCategory = getTopCategory(currentMonthExpenses);
    if (topCategory != null) {
      final percentage = getCategoryPercentage(topCategory.key, currentMonthExpenses);
      insights.add({
        'type': 'info',
        'title': 'Biggest Expense: ${topCategory.key}',
        'description': '₹${topCategory.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}% of total)',
        'icon': 'category',
      });
    }

    // Weekend spending pattern
    final patterns = getSpendingPatterns(currentMonthExpenses);
    if (patterns['weekendSpendingHigher'] && patterns['ratio'] > 1.5) {
      insights.add({
        'type': 'tip',
        'title': 'Weekend Spending Alert',
        'description': 'You spend ${patterns['ratio'].toStringAsFixed(1)}x more on weekends',
        'icon': 'calendar_today',
      });
    }

    // Savings category insight
    final savingsExpenses = currentMonthExpenses.where((e) => e.category == 'savings').toList();
    if (savingsExpenses.isNotEmpty) {
      final totalSavings = savingsExpenses.fold(0.0, (sum, e) => sum + e.amount);
      insights.add({
        'type': 'success',
        'title': 'Savings Milestone!',
        'description': 'You\'ve saved ₹${totalSavings.toStringAsFixed(0)} this month',
        'icon': 'savings',
      });
    }

    // Debt alert
    final debtSummary = getDebtSummary(debts);
    if (debtSummary['totalOwed'] > 0) {
      insights.add({
        'type': 'warning',
        'title': 'Pending Debts',
        'description': '₹${debtSummary['totalOwed'].toStringAsFixed(0)} debt to be paid',
        'icon': 'account_balance_wallet',
      });
    }

    // Savings insight
    final incomeExpense = getIncomeExpenseRatio(incomes, currentMonthExpenses);
    if (incomeExpense['inProfit']) {
      insights.add({
        'type': 'success',
        'title': 'Great Job Saving!',
        'description': 'Saving ${incomeExpense['savingsRate'].toStringAsFixed(0)}% of your income',
        'icon': 'savings',
      });
    } else if (incomes.isNotEmpty) {
      insights.add({
        'type': 'warning',
        'title': 'Overspending Alert',
        'description': 'Expenses exceed income by ₹${incomeExpense['savings'].abs().toStringAsFixed(0)}',
        'icon': 'warning',
      });
    }

    return insights;
  }
}
