import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/expense.dart';
import '../models/debt.dart';
import '../models/income.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'rupaya.db';
  static const int _databaseVersion = 4;

  // Table names
  static const String _usersTable = 'users';
  static const String _expensesTable = 'expenses';
  static const String _debtsTable = 'debts';
  static const String _incomeTable = 'income';

  // Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database with better error handling
  static Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Database initialization error: $e');
      // If there's an issue with getDatabasesPath, try alternative approach
      try {
        String path = join(await getDatabasesPath(), _databaseName);
        return await openDatabase('rupaya.db', version: _databaseVersion, onCreate: _createTables);
      } catch (e2) {
        print('Alternative database initialization failed: $e2');
        rethrow;
      }
    }
  }

  // Create tables
  static Future<void> _createTables(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE $_usersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phoneNumber TEXT UNIQUE NOT NULL,
        pinHash TEXT NOT NULL,
        occupation TEXT NOT NULL,
        city TEXT,
        monthlyIncome REAL,
        incomeDay INTEGER,
        monthlyIncomeGoal REAL,
        savingsGoal REAL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE $_expensesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES $_usersTable (id)
      )
    ''');

    // Debts table
    await db.execute('''
      CREATE TABLE $_debtsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        personName TEXT NOT NULL,
        amount REAL NOT NULL,
        paidAmount REAL DEFAULT 0.0,
        direction TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        isSettled INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES $_usersTable (id)
      )
    ''');

    // Income table
    await db.execute('''
      CREATE TABLE $_incomeTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        amount REAL NOT NULL,
        source TEXT NOT NULL,
        fromWhom TEXT,
        description TEXT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        isRecurring INTEGER DEFAULT 0,
        frequency TEXT,
        recurringDay INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES $_usersTable (id)
      )
    ''');
    
    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_expenses_userId_date ON $_expensesTable(userId, date)');
    await db.execute('CREATE INDEX idx_debts_userId ON $_debtsTable(userId)');
    await db.execute('CREATE INDEX idx_income_userId_date ON $_incomeTable(userId, date)');
    await db.execute('CREATE INDEX idx_expenses_category ON $_expensesTable(category)');
  }

  // Handle database upgrades
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add expenses table
      await db.execute('''
        CREATE TABLE $_expensesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          description TEXT,
          date TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES $_usersTable (id)
        )
      ''');

      // Add debts table
      await db.execute('''
        CREATE TABLE $_debtsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          personName TEXT NOT NULL,
          amount REAL NOT NULL,
          paidAmount REAL DEFAULT 0.0,
          direction TEXT NOT NULL,
          description TEXT,
          dueDate TEXT NOT NULL,
          isSettled INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES $_usersTable (id)
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Add income table
      await db.execute('''
        CREATE TABLE $_incomeTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          amount REAL NOT NULL,
          source TEXT NOT NULL,
          fromWhom TEXT,
          description TEXT,
          date TEXT NOT NULL,
          type TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (userId) REFERENCES $_usersTable (id)
        )
      ''');

      // Add monthly income fields to users table
      await db.execute('ALTER TABLE $_usersTable ADD COLUMN monthlyIncome REAL');
      await db.execute('ALTER TABLE $_usersTable ADD COLUMN incomeDay INTEGER');
    }
    
    if (oldVersion < 4) {
      // Add recurring income fields to income table
      await db.execute('ALTER TABLE $_incomeTable ADD COLUMN isRecurring INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE $_incomeTable ADD COLUMN frequency TEXT');
      await db.execute('ALTER TABLE $_incomeTable ADD COLUMN recurringDay INTEGER');
      
      // Add income goal to users table
      await db.execute('ALTER TABLE $_usersTable ADD COLUMN monthlyIncomeGoal REAL');
    }
  }

  // Hash PIN for security
  static String _hashPin(String pin) {
    var bytes = utf8.encode(pin);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register new user
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String phoneNumber,
    required String pin,
    required String occupation,
    String? city,
    double? monthlyIncome,
    int? incomeDay,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final hashedPin = _hashPin(pin);

      // Check if phone number already exists
      final existingUser = await db.query(
        _usersTable,
        where: 'phoneNumber = ?',
        whereArgs: [phoneNumber],
      );

      if (existingUser.isNotEmpty) {
        return {
          'success': false,
          'message': 'Phone number already registered. Please login instead.'
        };
      }

      // Insert new user
      final userId = await db.insert(_usersTable, {
        'name': name,
        'phoneNumber': phoneNumber,
        'pinHash': hashedPin,
        'occupation': occupation,
        'city': city,
        'monthlyIncome': monthlyIncome,
        'incomeDay': incomeDay,
        'createdAt': now,
        'updatedAt': now,
      });

      // Return success with user data
      final user = User(
        id: userId.toString(),
        name: name,
        phoneNumber: phoneNumber,
        pinHash: hashedPin,
        occupation: occupation,
        city: city,
        createdAt: DateTime.parse(now),
        updatedAt: DateTime.parse(now),
      );

      return {
        'success': true,
        'user': user,
        'message': 'Registration successful! Welcome to Rupaya.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}'
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> loginUser({
    required String phoneNumber,
    required String pin,
  }) async {
    try {
      final db = await database;
      final hashedPin = _hashPin(pin);

      // Find user by phone number and PIN
      final userMaps = await db.query(
        _usersTable,
        where: 'phoneNumber = ? AND pinHash = ?',
        whereArgs: [phoneNumber, hashedPin],
      );

      if (userMaps.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid phone number or PIN. Please check and try again.'
        };
      }

      final userMap = userMaps.first;
      final user = User(
        id: userMap['id'].toString(),
        name: userMap['name'] as String,
        phoneNumber: userMap['phoneNumber'] as String,
        pinHash: userMap['pinHash'] as String,
        occupation: userMap['occupation'] as String,
        city: userMap['city'] as String?,
        createdAt: DateTime.parse(userMap['createdAt'] as String),
        updatedAt: DateTime.parse(userMap['updatedAt'] as String),
      );

      return {
        'success': true,
        'user': user,
        'message': 'Login successful! Welcome back.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}'
      };
    }
  }

  // Check if phone number exists
  static Future<bool> phoneNumberExists(String phoneNumber) async {
    try {
      final db = await database;
      final result = await db.query(
        _usersTable,
        where: 'phoneNumber = ?',
        whereArgs: [phoneNumber],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? name,
    String? occupation,
    String? city,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      Map<String, dynamic> updateData = {
        'updatedAt': now,
      };

      if (name != null) updateData['name'] = name;
      if (occupation != null) updateData['occupation'] = occupation;
      if (city != null) updateData['city'] = city;

      final rowsAffected = await db.update(
        _usersTable,
        updateData,
        where: 'id = ?',
        whereArgs: [int.parse(userId)],
      );

      if (rowsAffected == 0) {
        return {
          'success': false,
          'message': 'User not found.'
        };
      }

      // Get updated user data
      final userMaps = await db.query(
        _usersTable,
        where: 'id = ?',
        whereArgs: [int.parse(userId)],
      );

      if (userMaps.isEmpty) {
        return {
          'success': false,
          'message': 'User not found after update.'
        };
      }

      final userMap = userMaps.first;
      final user = User(
        id: userMap['id'].toString(),
        name: userMap['name'] as String,
        phoneNumber: userMap['phoneNumber'] as String,
        pinHash: userMap['pinHash'] as String,
        occupation: userMap['occupation'] as String,
        city: userMap['city'] as String?,
        createdAt: DateTime.parse(userMap['createdAt'] as String),
        updatedAt: DateTime.parse(userMap['updatedAt'] as String),
      );

      return {
        'success': true,
        'user': user,
        'message': 'Profile updated successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Update failed: ${e.toString()}'
      };
    }
  }

  // Get user by ID
  static Future<User?> getUserById(String userId) async {
    try {
      final db = await database;
      final userMaps = await db.query(
        _usersTable,
        where: 'id = ?',
        whereArgs: [int.parse(userId)],
      );

      if (userMaps.isEmpty) return null;

      final userMap = userMaps.first;
      return User(
        id: userMap['id'].toString(),
        name: userMap['name'] as String,
        phoneNumber: userMap['phoneNumber'] as String,
        pinHash: userMap['pinHash'] as String,
        occupation: userMap['occupation'] as String,
        city: userMap['city'] as String?,
        monthlyIncome: (userMap['monthlyIncome'] as num?)?.toDouble(),
        incomeDay: userMap['incomeDay'] as int?,
        monthlyIncomeGoal: (userMap['monthlyIncomeGoal'] as num?)?.toDouble(),
        createdAt: DateTime.parse(userMap['createdAt'] as String),
        updatedAt: DateTime.parse(userMap['updatedAt'] as String),
      );
    } catch (e) {
      return null;
    }
  }

  // Update user's monthly income goal
  static Future<bool> updateUserIncomeGoal(String userId, double goal) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      await db.update(
        _usersTable,
        {'monthlyIncomeGoal': goal, 'updatedAt': now},
        where: 'id = ?',
        whereArgs: [int.parse(userId)],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Update user savings goal
  static Future<bool> updateUserSavingsGoal(String userId, double goal) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      await db.update(
        _usersTable,
        {'savingsGoal': goal, 'updatedAt': now},
        where: 'id = ?',
        whereArgs: [int.parse(userId)],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // EXPENSE METHODS

  // Add expense
  static Future<Map<String, dynamic>> addExpense(Expense expense) async {
    try {
      final db = await database;
      final id = await db.insert(_expensesTable, expense.toJson());
      
      return {
        'success': true,
        'expense': expense.copyWith(id: id.toString()),
        'message': 'Expense added successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add expense: ${e.toString()}'
      };
    }
  }

  // Get expenses for user
  static Future<List<Expense>> getExpensesForUser(String userId, {int? limit}) async {
    try {
      final db = await database;
      final maps = await db.query(
        _expensesTable,
        where: 'userId = ?',
        whereArgs: [int.parse(userId)],
        orderBy: 'date DESC',
        limit: limit,
      );

      return maps.map((map) => Expense.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get total expenses for user in a date range
  static Future<double> getTotalExpenses(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final db = await database;
      String whereClause = 'userId = ?';
      List<dynamic> whereArgs = [int.parse(userId)];

      if (startDate != null) {
        whereClause += ' AND date >= ?';
        whereArgs.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        whereClause += ' AND date <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM $_expensesTable WHERE $whereClause',
        whereArgs,
      );

      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Get total money out (expenses + money lent to others)
  static Future<double> getMonthlyMoneyOut(String userId, DateTime month) async {
    try {
      final db = await database;
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      // Get expenses for the month
      final expensesResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM $_expensesTable WHERE userId = ? AND date BETWEEN ? AND ?',
        [int.parse(userId), startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      );

      double totalExpenses = 0.0;
      if (expensesResult.isNotEmpty && expensesResult.first['total'] != null) {
        totalExpenses = (expensesResult.first['total'] as num).toDouble();
      }

      // Get money lent to others (debts with direction 'owed') created in this month
      final debtsLentResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM $_debtsTable WHERE userId = ? AND direction = ? AND createdAt BETWEEN ? AND ?',
        [int.parse(userId), 'owed', startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      );

      double totalLent = 0.0;
      if (debtsLentResult.isNotEmpty && debtsLentResult.first['total'] != null) {
        totalLent = (debtsLentResult.first['total'] as num).toDouble();
      }

      // Get debt payments made (paying others back - direction 'owe') in this month
      final debtPaymentsResult = await db.rawQuery(
        'SELECT SUM(paidAmount) as total FROM $_debtsTable WHERE userId = ? AND direction = ? AND updatedAt BETWEEN ? AND ? AND paidAmount > 0',
        [int.parse(userId), 'owe', startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      );

      double debtPaymentsMade = 0.0;
      if (debtPaymentsResult.isNotEmpty && debtPaymentsResult.first['total'] != null) {
        debtPaymentsMade = (debtPaymentsResult.first['total'] as num).toDouble();
      }

      return totalExpenses + totalLent + debtPaymentsMade;
    } catch (e) {
      print('Error getting monthly money out: $e');
      return 0.0;
    }
  }

  // Get net balance for the month: (Income + Debt repayments) - (Expenses + Money lent)
  static Future<double> getMonthlyNetBalance(String userId, DateTime month) async {
    try {
      final moneyIn = await getMonthlyIncomeForUser(userId, month);
      final moneyOut = await getMonthlyMoneyOut(userId, month);
      return moneyIn - moneyOut;
    } catch (e) {
      print('Error getting net balance: $e');
      return 0.0;
    }
  }

  // DEBT METHODS

  // Add debt
  static Future<Map<String, dynamic>> addDebt(Debt debt) async {
    try {
      final db = await database;
      final id = await db.insert(_debtsTable, debt.toJson());
      
      return {
        'success': true,
        'debt': debt.copyWith(id: id.toString()),
        'message': 'Debt added successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add debt: ${e.toString()}'
      };
    }
  }

  // Get debts for user
  static Future<List<Debt>> getDebtsForUser(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        _debtsTable,
        where: 'userId = ?',
        whereArgs: [int.parse(userId)],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => Debt.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get total debt amounts for user
  static Future<Map<String, double>> getDebtSummary(String userId) async {
    try {
      final db = await database;

      // Total owed to others
      final owedResult = await db.rawQuery(
        'SELECT SUM(amount - paidAmount) as total FROM $_debtsTable WHERE userId = ? AND direction = ? AND isSettled = 0',
        [int.parse(userId), 'owe'],
      );

      // Total owed by others  
      final owedByResult = await db.rawQuery(
        'SELECT SUM(amount - paidAmount) as total FROM $_debtsTable WHERE userId = ? AND direction = ? AND isSettled = 0',
        [int.parse(userId), 'owed'],
      );

      return {
        'totalOwed': (owedResult.first['total'] as num?)?.toDouble() ?? 0.0,
        'totalOwedBy': (owedByResult.first['total'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      return {'totalOwed': 0.0, 'totalOwedBy': 0.0};
    }
  }

  // Update debt payment
  static Future<Map<String, dynamic>> updateDebtPayment({
    required String debtId,
    required double paymentAmount,
  }) async {
    try {
      final db = await database;
      
      // Get current debt
      final debtMaps = await db.query(
        _debtsTable,
        where: 'id = ?',
        whereArgs: [int.parse(debtId)],
      );

      if (debtMaps.isEmpty) {
        return {
          'success': false,
          'message': 'Debt not found'
        };
      }

      final debtMap = debtMaps.first;
      final currentPaidAmount = (debtMap['paidAmount'] as num?)?.toDouble() ?? 0.0;
      final totalAmount = (debtMap['amount'] as num).toDouble();
      final newPaidAmount = currentPaidAmount + paymentAmount;

      // Check if payment exceeds debt amount
      if (newPaidAmount > totalAmount) {
        return {
          'success': false,
          'message': 'Payment amount exceeds remaining debt'
        };
      }

      // Check if debt is fully paid
      final isSettled = newPaidAmount >= totalAmount;

      // Update debt
      await db.update(
        _debtsTable,
        {
          'paidAmount': newPaidAmount,
          'isSettled': isSettled ? 1 : 0,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [int.parse(debtId)],
      );

      return {
        'success': true,
        'message': isSettled ? 'Debt fully paid!' : 'Payment recorded successfully',
        'isSettled': isSettled,
        'newPaidAmount': newPaidAmount,
        'remainingAmount': totalAmount - newPaidAmount,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update payment: ${e.toString()}'
      };
    }
  }

  // Get debt by ID
  static Future<Debt?> getDebtById(String debtId) async {
    try {
      final db = await database;
      final debtMaps = await db.query(
        _debtsTable,
        where: 'id = ?',
        whereArgs: [int.parse(debtId)],
      );

      if (debtMaps.isEmpty) return null;

      return Debt.fromJson(debtMaps.first);
    } catch (e) {
      return null;
    }
  }

  // Income Methods
  static Future<bool> addIncome(Income income) async {
    try {
      final db = await database;
      await db.insert(_incomeTable, income.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Income>> getIncomeForUser(String userId) async {
    try {
      final db = await database;
      final incomeMaps = await db.query(
        _incomeTable,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );

      return incomeMaps.map((map) => Income.fromJson(map)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<double> getTotalIncomeForUser(String userId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM $_incomeTable WHERE userId = ?',
        [userId],
      );

      if (result.isNotEmpty && result.first['total'] != null) {
        return (result.first['total'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  static Future<double> getMonthlyIncomeForUser(String userId, DateTime month) async {
    try {
      final db = await database;
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final today = DateTime.now();
      final currentDay = today.day;

      // Get NON-RECURRING income entries for the month
      final incomeResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM $_incomeTable WHERE userId = ? AND date BETWEEN ? AND ? AND (isRecurring = 0 OR isRecurring IS NULL)',
        [userId, startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      );

      double monthlyIncomeFromEntries = 0.0;
      if (incomeResult.isNotEmpty && incomeResult.first['total'] != null) {
        monthlyIncomeFromEntries = (incomeResult.first['total'] as num).toDouble();
      }

      // Get RECURRING income entries - only if their recurring day has arrived
      final recurringIncomeResult = await db.query(
        _incomeTable,
        where: 'userId = ? AND isRecurring = 1 AND frequency = ?',
        whereArgs: [userId, 'monthly'],
      );

      double recurringIncome = 0.0;
      for (var incomeMap in recurringIncomeResult) {
        final recurringDay = incomeMap['recurringDay'] as int?;
        if (recurringDay != null) {
          // Only add recurring income if:
          // 1. We're in the current month AND today's date >= recurring day
          // 2. OR we're viewing a past month (always include it)
          final isCurrentMonth = month.year == today.year && month.month == today.month;
          final isFutureMonth = month.isAfter(DateTime(today.year, today.month));
          
          if (isFutureMonth) {
            // Don't include recurring income for future months
            continue;
          } else if (isCurrentMonth) {
            // Current month: only include if today >= recurring day
            // Handle edge case: if recurring day is 31 but month has fewer days
            final maxDayInMonth = DateTime(month.year, month.month + 1, 0).day;
            final effectiveRecurringDay = recurringDay > maxDayInMonth ? maxDayInMonth : recurringDay;
            
            if (currentDay >= effectiveRecurringDay) {
              recurringIncome += (incomeMap['amount'] as num).toDouble();
            }
          } else {
            // Past month: always include
            recurringIncome += (incomeMap['amount'] as num).toDouble();
          }
        }
      }

      // Get user's set monthly income (legacy field - treat as recurring on day 1)
      final userResult = await db.query(
        _usersTable,
        columns: ['monthlyIncome'],
        where: 'id = ?',
        whereArgs: [userId],
      );

      double userMonthlyIncome = 0.0;
      if (userResult.isNotEmpty && userResult.first['monthlyIncome'] != null) {
        final isCurrentMonth = month.year == today.year && month.month == today.month;
        final isFutureMonth = month.isAfter(DateTime(today.year, today.month));
        
        if (!isFutureMonth && (!isCurrentMonth || currentDay >= 1)) {
          // Include if not future month and (past month or current month with day >= 1)
          userMonthlyIncome = (userResult.first['monthlyIncome'] as num).toDouble();
        }
      }

      // Get debt repayments received (money lent that was paid back)
      // This includes payments on debts where user lent money (direction='owed') updated in this month
      final debtsResult = await db.rawQuery(
        'SELECT SUM(paidAmount) as total FROM $_debtsTable WHERE userId = ? AND direction = ? AND updatedAt BETWEEN ? AND ? AND paidAmount > 0',
        [int.parse(userId), 'owed', startOfMonth.toIso8601String(), endOfMonth.toIso8601String()],
      );

      double debtRepaymentsReceived = 0.0;
      if (debtsResult.isNotEmpty && debtsResult.first['total'] != null) {
        debtRepaymentsReceived = (debtsResult.first['total'] as num).toDouble();
      }

      // Return the sum of all income sources
      return monthlyIncomeFromEntries + recurringIncome + userMonthlyIncome + debtRepaymentsReceived;
    } catch (e) {
      print('Error getting monthly income: $e');
      return 0.0;
    }
  }

  static Future<bool> deleteIncome(String incomeId) async {
    try {
      final db = await database;
      final result = await db.delete(
        _incomeTable,
        where: 'id = ?',
        whereArgs: [incomeId],
      );
      return result > 0;
    } catch (e) {
      return false;
    }
  }

  // Clear all data (for testing purposes)
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_expensesTable);
    await db.delete(_debtsTable);
    await db.delete(_incomeTable);
    await db.delete(_usersTable);
  }

  // Close database
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
