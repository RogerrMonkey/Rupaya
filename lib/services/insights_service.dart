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

  /// Generate comprehensive rule-based insights (local, no API needed)
  static List<Map<String, String>> generateLocalInsights(
    List<Expense> expenses,
    List<Income> incomes,
    List<Debt> debts,
  ) {
    final insights = <Map<String, String>>[];
    
    if (expenses.isEmpty) {
      insights.add({
        'type': 'info',
        'title': 'Start Your Financial Journey',
        'description': 'Begin tracking expenses to unlock powerful insights about your spending habits',
        'icon': 'info',
      });
      return insights;
    }

    final now = DateTime.now();
    final currentMonthExpenses = expenses.where((e) =>
      e.date.year == now.year && e.date.month == now.month
    ).toList();
    
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthExpenses = expenses.where((e) =>
      e.date.year == lastMonth.year && e.date.month == lastMonth.month
    ).toList();

    final categoryBreakdown = getCategoryBreakdown(currentMonthExpenses);
    final monthlyTotal = calculateMonthlyTotal(currentMonthExpenses);
    final dailyAverage = calculateDailyAverage(currentMonthExpenses);

    // 1. MONTHLY COMPARISON WITH DETAILS
    if (lastMonthExpenses.isNotEmpty && currentMonthExpenses.isNotEmpty) {
      final comparison = getMonthlyComparison(currentMonthExpenses, lastMonthExpenses);
      final change = comparison['percentageChange'].abs().toStringAsFixed(1);
      final diff = comparison['difference'].abs().toStringAsFixed(0);
      
      if (comparison['increased']) {
        insights.add({
          'type': 'warning',
          'title': 'Spending Up by ${change}%',
          'description': '₹$diff more than last month. Review your ${categoryBreakdown.entries.first.key} expenses.',
          'icon': 'trending_up',
        });
      } else {
        insights.add({
          'type': 'success',
          'title': 'Excellent Progress!',
          'description': 'Saved ₹$diff more than last month (${change}% decrease). Keep it up!',
          'icon': 'trending_down',
        });
      }
    }

    // 2. TOP CATEGORY DETAILED ANALYSIS
    if (categoryBreakdown.isNotEmpty) {
      final topCategory = categoryBreakdown.entries.first;
      final percentage = (topCategory.value / monthlyTotal * 100).toStringAsFixed(1);
      final avgPerDay = (topCategory.value / now.day).toStringAsFixed(0);
      
      insights.add({
        'type': percentage.compareTo('40') > 0 ? 'warning' : 'info',
        'title': '${topCategory.key} Dominates Spending',
        'description': '${percentage}% of budget (₹${topCategory.value.toStringAsFixed(0)}). Daily avg: ₹$avgPerDay',
        'icon': 'category',
      });

      // Category-specific advice
      if (topCategory.key.toLowerCase() == 'food' && double.parse(percentage) > 30) {
        insights.add({
          'type': 'tip',
          'title': 'Food Budget Opportunity',
          'description': 'Consider meal prepping to save 20-30% on food expenses',
          'icon': 'restaurant',
        });
      } else if (topCategory.key.toLowerCase() == 'entertainment' && double.parse(percentage) > 20) {
        insights.add({
          'type': 'tip',
          'title': 'Entertainment Budget Alert',
          'description': 'Entertainment is ${percentage}% of spending. Set a monthly limit to save more',
          'icon': 'movie',
        });
      } else if (topCategory.key.toLowerCase() == 'transport' && double.parse(percentage) > 25) {
        insights.add({
          'type': 'tip',
          'title': 'Transport Cost Optimization',
          'description': 'Transport is high at ${percentage}%. Explore carpooling or public transit options',
          'icon': 'directions_car',
        });
      }
    }

    // 3. SPENDING VELOCITY & PROJECTION
    final velocity = getSpendingVelocity(currentMonthExpenses);
    final projected = velocity['projectedMonthly'].toStringAsFixed(0);
    final daysLeft = velocity['daysRemaining'];
    
    if (daysLeft > 0) {
      final remainingBudget = (velocity['projectedMonthly'] - monthlyTotal).toStringAsFixed(0);
      insights.add({
        'type': 'info',
        'title': 'Monthly Projection: ₹$projected',
        'description': 'At current rate, you have ₹$remainingBudget for next $daysLeft days (₹${(double.parse(remainingBudget) / daysLeft).toStringAsFixed(0)}/day)',
        'icon': 'timeline',
      });
    }

    // 4. WEEKEND VS WEEKDAY PATTERN
    final patterns = getSpendingPatterns(currentMonthExpenses);
    if (patterns['weekendTotal'] > 0 && patterns['weekdayTotal'] > 0) {
      final ratio = patterns['ratio'];
      if (ratio > 1.5) {
        final extraSpending = (patterns['weekendTotal'] - patterns['weekdayTotal']).toStringAsFixed(0);
        insights.add({
          'type': 'warning',
          'title': 'Weekend Spending Spike',
          'description': '${ratio.toStringAsFixed(1)}x higher on weekends. Save ₹$extraSpending by planning weekend activities',
          'icon': 'calendar_today',
        });
      } else if (ratio < 0.7) {
        insights.add({
          'type': 'success',
          'title': 'Great Weekend Discipline',
          'description': 'You spend less on weekends. Excellent financial habit!',
          'icon': 'thumb_up',
        });
      }
    }

    // 5. INCOME VS EXPENSE DETAILED ANALYSIS
    if (incomes.isNotEmpty) {
      final incomeExpense = getIncomeExpenseRatio(incomes, currentMonthExpenses);
      final savingsRate = incomeExpense['savingsRate'];
      final savings = incomeExpense['savings'].toStringAsFixed(0);
      
      if (incomeExpense['inProfit']) {
        if (savingsRate >= 30) {
          insights.add({
            'type': 'success',
            'title': 'Exceptional Savings: ${savingsRate.toStringAsFixed(0)}%',
            'description': 'Saving ₹$savings this month. You\'re in the top 10% of savers!',
            'icon': 'stars',
          });
        } else if (savingsRate >= 20) {
          insights.add({
            'type': 'success',
            'title': 'Healthy Savings: ${savingsRate.toStringAsFixed(0)}%',
            'description': 'Saving ₹$savings. Try to reach 30% savings rate for financial freedom',
            'icon': 'savings',
          });
        } else if (savingsRate >= 10) {
          insights.add({
            'type': 'info',
            'title': 'Building Savings: ${savingsRate.toStringAsFixed(0)}%',
            'description': 'Saving ₹$savings. Increase by cutting your top expense by 15%',
            'icon': 'account_balance_wallet',
          });
        } else {
          insights.add({
            'type': 'warning',
            'title': 'Low Savings: ${savingsRate.toStringAsFixed(0)}%',
            'description': 'Only ₹$savings saved. Aim for 20% minimum savings rate',
            'icon': 'warning',
          });
        }
      } else {
        final overspend = savings.replaceAll('-', '');
        insights.add({
          'type': 'warning',
          'title': 'Budget Deficit Alert',
          'description': 'Spending ₹$overspend more than income. Cut ${categoryBreakdown.entries.first.key} by 30%',
          'icon': 'error',
        });
      }
    }

    // 6. DEBT MANAGEMENT INSIGHTS
    final debtSummary = getDebtSummary(debts);
    if (debtSummary['totalOwed'] > 0) {
      final owed = debtSummary['totalOwed'].toStringAsFixed(0);
      if (debtSummary['hasOverdueDebts']) {
        insights.add({
          'type': 'warning',
          'title': 'Overdue Debt: ₹$owed',
          'description': 'Prioritize clearing overdue debts to maintain good relationships and credit',
          'icon': 'priority_high',
        });
      } else {
        insights.add({
          'type': 'info',
          'title': 'Active Debts: ₹$owed',
          'description': 'Allocate 10-15% of income monthly to clear debts faster',
          'icon': 'account_balance_wallet',
        });
      }
    }
    
    if (debtSummary['totalReceivable'] > 0) {
      final receivable = debtSummary['totalReceivable'].toStringAsFixed(0);
      insights.add({
        'type': 'info',
        'title': 'Money to Collect: ₹$receivable',
        'description': 'Follow up on receivables to improve your cash flow',
        'icon': 'call_received',
      });
    }

    // 7. HIGHEST SINGLE EXPENSE ALERT
    final highestExpense = getHighestExpense(currentMonthExpenses);
    if (highestExpense != null && highestExpense.amount > dailyAverage * 3) {
      final percentage = (highestExpense.amount / monthlyTotal * 100).toStringAsFixed(0);
      insights.add({
        'type': 'warning',
        'title': 'Large Expense Detected',
        'description': '₹${highestExpense.amount.toStringAsFixed(0)} on ${highestExpense.category} (${percentage}% of budget). Plan major purchases in advance',
        'icon': 'warning_amber',
      });
    }

    // 8. CATEGORY DIVERSITY INSIGHT
    if (categoryBreakdown.length <= 2 && currentMonthExpenses.length > 5) {
      insights.add({
        'type': 'tip',
        'title': 'Diversify Expense Categories',
        'description': 'Track expenses in more categories for better financial visibility',
        'icon': 'pie_chart',
      });
    }

    // 9. DAILY AVERAGE CONTEXT
    if (dailyAverage > 0) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final suggestedDaily = (monthlyTotal * 0.8 / daysInMonth).toStringAsFixed(0);
      
      if (dailyAverage > double.parse(suggestedDaily)) {
        insights.add({
          'type': 'tip',
          'title': 'Daily Spending: ₹${dailyAverage.toStringAsFixed(0)}',
          'description': 'Try limiting to ₹$suggestedDaily/day to save 20% more this month',
          'icon': 'calendar_view_day',
        });
      }
    }

    // 10. MILESTONE ACHIEVEMENTS
    if (currentMonthExpenses.length >= 30) {
      insights.add({
        'type': 'success',
        'title': 'Consistency Champion!',
        'description': '${currentMonthExpenses.length} expenses tracked. Daily tracking leads to 40% better savings',
        'icon': 'emoji_events',
      });
    }

    // 11. CATEGORY COMPARISON WITH LAST MONTH
    if (lastMonthExpenses.isNotEmpty && categoryBreakdown.isNotEmpty) {
      final lastMonthBreakdown = getCategoryBreakdown(lastMonthExpenses);
      final topCat = categoryBreakdown.entries.first.key;
      
      if (lastMonthBreakdown.containsKey(topCat)) {
        final currentCatSpend = categoryBreakdown[topCat]!;
        final lastCatSpend = lastMonthBreakdown[topCat]!;
        final catChange = ((currentCatSpend - lastCatSpend) / lastCatSpend * 100).toStringAsFixed(0);
        
        if (double.parse(catChange).abs() > 25) {
          insights.add({
            'type': double.parse(catChange) > 0 ? 'warning' : 'success',
            'title': '$topCat: ${catChange}% ${double.parse(catChange) > 0 ? "Increase" : "Decrease"}',
            'description': double.parse(catChange) > 0 
              ? 'Investigate this spike. Set a category limit to control spending'
              : 'Great reduction! Maintain this trend for long-term savings',
            'icon': 'analytics',
          });
        }
      }
    }

    // 12. SMART RECOMMENDATIONS BASED ON SPENDING PATTERNS
    if (monthlyTotal > 0) {
      final foodSpend = categoryBreakdown['Food'] ?? categoryBreakdown['food'] ?? 0;
      final transportSpend = categoryBreakdown['Transport'] ?? categoryBreakdown['transport'] ?? 0;
      
      if (foodSpend / monthlyTotal > 0.4) {
        insights.add({
          'type': 'tip',
          'title': '💡 Food Savings Tip',
          'description': 'Reduce outside dining by 2x/week to save ₹${(foodSpend * 0.15).toStringAsFixed(0)} monthly',
          'icon': 'lightbulb',
        });
      }
      
      if (transportSpend / monthlyTotal > 0.3) {
        insights.add({
          'type': 'tip',
          'title': '💡 Transport Savings Tip',
          'description': 'Switch 3 trips/week to public transport to save ₹${(transportSpend * 0.2).toStringAsFixed(0)}',
          'icon': 'lightbulb',
        });
      }
    }

    return insights;
  }
}
