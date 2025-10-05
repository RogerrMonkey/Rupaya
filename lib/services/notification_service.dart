import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'database_service.dart';
import '../models/debt.dart';
import '../models/expense.dart';
import '../models/income.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Notification IDs
  static const int dailyExpenseReminderId = 1;
  static const int debtReminderBaseId = 1000; // Base ID for debt reminders
  static const int savingsGoalId = 2000;
  static const int incomeGoalId = 2001;
  static const int budgetAlertId = 2002;
  static const int achievementId = 2003;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // Indian timezone

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    
    // Request permissions
    await requestPermissions();
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on notification payload
    // This can be expanded to navigate to specific screens
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule daily expense reminder (8 PM every day)
  static Future<void> scheduleDailyExpenseReminder() async {
    await _notifications.zonedSchedule(
      dailyExpenseReminderId,
      'Track Your Expenses 📝',
      'Have you logged all your expenses today?',
      _nextInstanceOf8PM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Daily reminders to track expenses',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule debt repayment reminders
  static Future<void> scheduleDebtReminders() async {
    try {
      final db = await DatabaseService.database;
      final userMaps = await db.query('users', limit: 1);
      if (userMaps.isEmpty) return;

      final userId = userMaps.first['id'].toString();
      final debts = await DatabaseService.getDebtsForUser(userId);

      // Cancel existing debt reminders
      for (int i = 0; i < 100; i++) {
        await _notifications.cancel(debtReminderBaseId + i);
      }

      int reminderIndex = 0;
      final now = DateTime.now();

      for (final debt in debts) {
        if (debt.isSettled || debt.direction != 'owe') continue;

        final dueDate = debt.dueDate;
        final remainingAmount = debt.amount - debt.paidAmount;

        // 3 days before
        final threeDaysBefore = dueDate.subtract(const Duration(days: 3));
        if (threeDaysBefore.isAfter(now) && reminderIndex < 100) {
          await _scheduleDebtNotification(
            debtReminderBaseId + reminderIndex++,
            'Debt Reminder 📅',
            'Debt to ${debt.personName} due in 3 days. Amount: ₹${remainingAmount.toStringAsFixed(0)}',
            threeDaysBefore,
          );
        }

        // 1 day before
        final oneDayBefore = dueDate.subtract(const Duration(days: 1));
        if (oneDayBefore.isAfter(now) && reminderIndex < 100) {
          await _scheduleDebtNotification(
            debtReminderBaseId + reminderIndex++,
            'Debt Due Tomorrow! ⚠️',
            'Reminder: Pay ${debt.personName} ₹${remainingAmount.toStringAsFixed(0)} by tomorrow',
            oneDayBefore,
          );
        }

        // On due date
        if (dueDate.isAfter(now) && reminderIndex < 100) {
          await _scheduleDebtNotification(
            debtReminderBaseId + reminderIndex++,
            'Debt Due Today! 🔔',
            'Pay ${debt.personName} ₹${remainingAmount.toStringAsFixed(0)} today',
            dueDate,
          );
        }
      }
    } catch (e) {
      print('Error scheduling debt reminders: $e');
    }
  }

  static Future<void> _scheduleDebtNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
  ) async {
    // Schedule at 9 AM on the scheduled date
    final scheduledTime = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      9, // 9 AM
    );

    if (scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'debt_reminders',
            'Debt Reminders',
            channelDescription: 'Reminders for upcoming debt payments',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Check and notify for income goal progress
  static Future<void> checkIncomeGoalProgress() async {
    try {
      final db = await DatabaseService.database;
      final userMaps = await db.query('users', limit: 1);
      if (userMaps.isEmpty) return;

      final user = userMaps.first;
      final monthlyIncomeGoal = user['monthlyIncomeGoal'] as double?;
      if (monthlyIncomeGoal == null || monthlyIncomeGoal <= 0) return;

      final userId = user['id'].toString();
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));

      final incomes = await DatabaseService.getIncomeForUser(userId);
      final monthlyIncome = incomes
          .where((i) => i.date.isAfter(monthStart.subtract(const Duration(days: 1))) && 
                       i.date.isBefore(monthEnd.add(const Duration(days: 1))))
          .fold(0.0, (sum, i) => sum + i.amount);

      final progress = (monthlyIncome / monthlyIncomeGoal * 100).clamp(0, 100);

      // Notify at 75% progress
      if (progress >= 75 && progress < 100) {
        await showInstantNotification(
          incomeGoalId,
          'Almost There! 🎯',
          'You\'ve earned ${progress.toStringAsFixed(0)}% of your monthly income goal!',
          'income_goal',
        );
      }
      // Notify when goal achieved
      else if (progress >= 100) {
        await showInstantNotification(
          incomeGoalId,
          'Goal Achieved! 🎉',
          'Congratulations! You\'ve reached your monthly income goal of ₹${monthlyIncomeGoal.toStringAsFixed(0)}',
          'income_goal',
        );
      }
    } catch (e) {
      print('Error checking income goal: $e');
    }
  }

  /// Check and notify for savings goal progress
  static Future<void> checkSavingsGoalProgress() async {
    try {
      final db = await DatabaseService.database;
      final userMaps = await db.query('users', limit: 1);
      if (userMaps.isEmpty) return;

      final user = userMaps.first;
      final savingsGoal = user['savingsGoal'] as double?;
      if (savingsGoal == null || savingsGoal <= 0) return;

      final userId = user['id'].toString();
      final expenses = await DatabaseService.getExpensesForUser(userId);
      final currentSavings = expenses
          .where((e) => e.category == 'savings')
          .fold(0.0, (sum, e) => sum + e.amount);

      final progress = (currentSavings / savingsGoal * 100).clamp(0, 100);

      // Notify at 50%, 75%, and 100%
      if (progress >= 50 && progress < 75) {
        await showInstantNotification(
          savingsGoalId,
          'Halfway There! 💰',
          'You\'ve saved ${progress.toStringAsFixed(0)}% of your savings goal!',
          'savings_goal',
        );
      } else if (progress >= 75 && progress < 100) {
        await showInstantNotification(
          savingsGoalId,
          'Great Progress! 🌟',
          'You\'re at ${progress.toStringAsFixed(0)}% of your savings goal. Keep going!',
          'savings_goal',
        );
      } else if (progress >= 100) {
        await showInstantNotification(
          savingsGoalId,
          'Savings Goal Achieved! 🎊',
          'Amazing! You\'ve saved ₹${currentSavings.toStringAsFixed(0)}. Time to set a new goal?',
          'savings_goal',
        );
      }
    } catch (e) {
      print('Error checking savings goal: $e');
    }
  }

  /// Check for unusual spending and send alerts
  static Future<void> checkBudgetAlerts() async {
    try {
      final db = await DatabaseService.database;
      final userMaps = await db.query('users', limit: 1);
      if (userMaps.isEmpty) return;

      final userId = userMaps.first['id'].toString();
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      
      final expenses = await DatabaseService.getExpensesForUser(userId);
      final monthlyExpenses = expenses
          .where((e) => e.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
                       e.category != 'savings')
          .toList();

      final totalSpent = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);
      
      // Calculate daily average for the month
      final daysInMonth = now.day;
      final dailyAverage = daysInMonth > 0 ? totalSpent / daysInMonth : 0.0;

      // Check today's spending
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayExpenses = expenses
          .where((e) => e.date.isAfter(todayStart.subtract(const Duration(days: 1))) &&
                       e.date.isBefore(todayStart.add(const Duration(days: 1))) &&
                       e.category != 'savings')
          .fold(0.0, (sum, e) => sum + e.amount);

      // Alert if today's spending is 2x the daily average
      if (todayExpenses > dailyAverage * 2 && dailyAverage > 100) {
        await showInstantNotification(
          budgetAlertId,
          'High Spending Alert! 💸',
          'You\'ve spent ₹${todayExpenses.toStringAsFixed(0)} today, which is higher than usual.',
          'budget_alert',
        );
      }
    } catch (e) {
      print('Error checking budget alerts: $e');
    }
  }

  /// Show instant notification
  static Future<void> showInstantNotification(
    int id,
    String title,
    String body,
    String payload,
  ) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notifications',
          'Instant Notifications',
          channelDescription: 'Important instant notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Notify when achievement is unlocked
  static Future<void> notifyAchievementUnlocked(String achievementTitle) async {
    await showInstantNotification(
      achievementId,
      'Achievement Unlocked! 🏆',
      achievementTitle,
      'achievement',
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Get next instance of 8 PM
  static tz.TZDateTime _nextInstanceOf8PM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20, // 8 PM
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Schedule all recurring notifications
  static Future<void> scheduleAllNotifications() async {
    await initialize();
    await scheduleDailyExpenseReminder();
    await scheduleDebtReminders();
  }

  /// Check all progress-based notifications (call when data changes)
  static Future<void> checkAllProgress() async {
    await checkIncomeGoalProgress();
    await checkSavingsGoalProgress();
    await checkBudgetAlerts();
  }
}
