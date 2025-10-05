import '../models/expense.dart';
import '../models/income.dart';
import '../models/debt.dart';

/// Service for calculating and tracking user achievements
class AchievementsService {
  
  /// Get all achievements with their unlock status based on user data
  static List<Achievement> getAchievements({
    required List<Expense> expenses,
    required List<Income> incomes,
    required List<Debt> debts,
    required int totalDays, // Days since user registration
  }) {
    // Calculate various metrics
    final totalExpenses = expenses.length;
    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final savingsExpenses = expenses.where((e) => e.category == 'savings').toList();
    final totalSavings = savingsExpenses.fold(0.0, (sum, e) => sum + e.amount);
    
    // Debt metrics
    final totalDebts = debts.length;
    final owedDebts = debts.where((d) => d.direction == 'owe' && !d.isSettled).toList();
    final totalOwed = owedDebts.fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount));
    final repaidDebt = debts.where((d) => d.direction == 'owe').fold(0.0, (sum, d) => sum + d.paidAmount);
    final totalDebtAmount = debts.where((d) => d.direction == 'owe').fold(0.0, (sum, d) => sum + d.amount);
    final debtRepaymentPercentage = totalDebtAmount > 0 ? (repaidDebt / totalDebtAmount) * 100 : 100.0;
    final settledDebts = debts.where((d) => d.isSettled).length;
    
    // Category tracking
    final uniqueCategories = expenses.map((e) => e.category).toSet().length;
    final foodExpenses = expenses.where((e) => e.category == 'food').length;
    
    // Streak calculations
    final consecutiveDays = _calculateConsecutiveDays(expenses);
    
    return [
      // Beginner achievements
      Achievement(
        id: 'first_expense',
        title: 'First Step',
        description: 'Added your first expense',
        icon: 'add_circle',
        isUnlocked: totalExpenses >= 1,
        points: 10,
        progress: totalExpenses >= 1 ? 1.0 : 0.0,
        target: 1,
      ),
      
      Achievement(
        id: 'expense_tracker',
        title: 'Expense Tracker',
        description: 'Track 10 expenses',
        icon: 'assignment',
        isUnlocked: totalExpenses >= 10,
        points: 25,
        progress: (totalExpenses / 10).clamp(0.0, 1.0),
        target: 10,
      ),
      
      Achievement(
        id: 'dedicated_tracker',
        title: 'Dedicated Tracker',
        description: 'Track 50 expenses',
        icon: 'trending_up',
        isUnlocked: totalExpenses >= 50,
        points: 50,
        progress: (totalExpenses / 50).clamp(0.0, 1.0),
        target: 50,
      ),
      
      // Savings achievements
      Achievement(
        id: 'savings_start',
        title: 'Savings Beginner',
        description: 'Save ₹1,000',
        icon: 'savings',
        isUnlocked: totalSavings >= 1000,
        points: 30,
        progress: (totalSavings / 1000).clamp(0.0, 1.0),
        target: 1000,
      ),
      
      Achievement(
        id: 'savings_pro',
        title: 'Savings Pro',
        description: 'Save ₹5,000',
        icon: 'account_balance',
        isUnlocked: totalSavings >= 5000,
        points: 75,
        progress: (totalSavings / 5000).clamp(0.0, 1.0),
        target: 5000,
      ),
      
      Achievement(
        id: 'savings_master',
        title: 'Savings Master',
        description: 'Save ₹10,000',
        icon: 'star',
        isUnlocked: totalSavings >= 10000,
        points: 150,
        progress: (totalSavings / 10000).clamp(0.0, 1.0),
        target: 10000,
      ),
      
      // Debt achievements
      Achievement(
        id: 'debt_warrior',
        title: 'Debt Warrior',
        description: 'Started tracking debts',
        icon: 'shield',
        isUnlocked: totalDebts >= 1,
        points: 20,
        progress: totalDebts >= 1 ? 1.0 : 0.0,
        target: 1,
      ),
      
      Achievement(
        id: 'debt_slayer',
        title: 'Debt Slayer',
        description: 'Repaid 50% of debt',
        icon: 'military_tech',
        isUnlocked: debtRepaymentPercentage >= 50,
        points: 100,
        progress: (debtRepaymentPercentage / 50).clamp(0.0, 1.0),
        target: 50,
      ),
      
      Achievement(
        id: 'debt_crusher',
        title: 'Debt Crusher',
        description: 'Settle your first debt completely',
        icon: 'check_circle',
        isUnlocked: settledDebts >= 1,
        points: 80,
        progress: settledDebts >= 1 ? 1.0 : 0.0,
        target: 1,
      ),
      
      Achievement(
        id: 'debt_free',
        title: 'Debt Free Hero',
        description: 'Completely debt free',
        icon: 'emoji_events',
        isUnlocked: owedDebts.isEmpty && totalDebts > 0,
        points: 300,
        progress: totalDebts > 0 ? (owedDebts.isEmpty ? 1.0 : 0.0) : 0.0,
        target: 1,
      ),
      
      // Income achievements
      Achievement(
        id: 'income_tracker',
        title: 'Income Tracker',
        description: 'Record your first income',
        icon: 'payment',
        isUnlocked: incomes.isNotEmpty,
        points: 15,
        progress: incomes.isNotEmpty ? 1.0 : 0.0,
        target: 1,
      ),
      
      Achievement(
        id: 'earner',
        title: 'Big Earner',
        description: 'Earn ₹50,000 in total',
        icon: 'attach_money',
        isUnlocked: totalIncome >= 50000,
        points: 100,
        progress: (totalIncome / 50000).clamp(0.0, 1.0),
        target: 50000,
      ),
      
      // Consistency achievements
      Achievement(
        id: 'week_streak',
        title: 'Consistent Week',
        description: 'Track expenses for 7 consecutive days',
        icon: 'date_range',
        isUnlocked: consecutiveDays >= 7,
        points: 50,
        progress: (consecutiveDays / 7).clamp(0.0, 1.0),
        target: 7,
      ),
      
      Achievement(
        id: 'month_streak',
        title: 'Monthly Dedication',
        description: 'Active for 30 days',
        icon: 'calendar_today',
        isUnlocked: totalDays >= 30,
        points: 100,
        progress: (totalDays / 30).clamp(0.0, 1.0),
        target: 30,
      ),
      
      // Category achievements
      Achievement(
        id: 'category_explorer',
        title: 'Category Explorer',
        description: 'Use 5 different expense categories',
        icon: 'explore',
        isUnlocked: uniqueCategories >= 5,
        points: 40,
        progress: (uniqueCategories / 5).clamp(0.0, 1.0),
        target: 5,
      ),
    ];
  }
  
  /// Calculate consecutive days of expense tracking
  static int _calculateConsecutiveDays(List<Expense> expenses) {
    if (expenses.isEmpty) return 0;
    
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int consecutiveDays = 0;
    DateTime checkDate = today;
    
    for (int i = 0; i < 365; i++) {
      final hasExpense = sortedExpenses.any((e) {
        final expenseDate = DateTime(e.date.year, e.date.month, e.date.day);
        return expenseDate.isAtSameMomentAs(checkDate);
      });
      
      if (hasExpense) {
        consecutiveDays++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return consecutiveDays;
  }
  
  /// Calculate total points earned
  static int getTotalPoints(List<Achievement> achievements) {
    return achievements
        .where((a) => a.isUnlocked)
        .fold(0, (sum, a) => sum + a.points);
  }
  
  /// Get achievement completion percentage
  static double getCompletionPercentage(List<Achievement> achievements) {
    if (achievements.isEmpty) return 0.0;
    final unlocked = achievements.where((a) => a.isUnlocked).length;
    return (unlocked / achievements.length) * 100;
  }
  
  /// Get next achievement to unlock
  static Achievement? getNextAchievement(List<Achievement> achievements) {
    final locked = achievements.where((a) => !a.isUnlocked).toList();
    if (locked.isEmpty) return null;
    
    // Sort by progress (closest to unlocking)
    locked.sort((a, b) => b.progress.compareTo(a.progress));
    return locked.first;
  }
  
  /// Get recently unlocked achievements (for notifications)
  static List<Achievement> getRecentlyUnlocked(List<Achievement> achievements) {
    return achievements.where((a) => a.isUnlocked).toList();
  }
}

/// Achievement model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon; // Icon name as string
  final bool isUnlocked;
  final int points;
  final double progress; // 0.0 to 1.0
  final int target; // Target value for the achievement
  
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.points,
    required this.progress,
    required this.target,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'isUnlocked': isUnlocked,
      'points': points,
      'progress': progress,
      'target': target,
    };
  }
}
