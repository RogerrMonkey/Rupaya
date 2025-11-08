import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/debt.dart';

/// Service for exporting and importing all user data
class ExportImportService {
  
  /// Export all user data to JSON file
  static Future<Map<String, dynamic>> exportAllData() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null || currentUser.id == null) {
      throw Exception('No user logged in');
    }

    final userId = currentUser.id!;

    // Fetch all data
    final expenses = await DatabaseService.getExpensesForUser(userId);
    final incomes = await DatabaseService.getIncomeForUser(userId);
    final debts = await DatabaseService.getDebtsForUser(userId);

    // Create export data structure
    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'user': {
        'name': currentUser.name,
        'phoneNumber': currentUser.phoneNumber,
        'occupation': currentUser.occupation,
        'city': currentUser.city,
      },
      'expenses': expenses.map((e) => {
        'amount': e.amount,
        'category': e.category,
        'description': e.description,
        'date': e.date.toIso8601String(),
      }).toList(),
      'incomes': incomes.map((i) => {
        'amount': i.amount,
        'source': i.source,
        'fromWhom': i.fromWhom,
        'description': i.description,
        'date': i.date.toIso8601String(),
        'type': i.type,
        'isRecurring': i.isRecurring,
        'frequency': i.frequency,
        'recurringDay': i.recurringDay,
      }).toList(),
      'debts': debts.map((d) => {
        'personName': d.personName,
        'amount': d.amount,
        'paidAmount': d.paidAmount,
        'direction': d.direction,
        'description': d.description,
        'dueDate': d.dueDate?.toIso8601String(),
        'isSettled': d.isSettled,
      }).toList(),
      'statistics': {
        'totalExpenses': expenses.length,
        'totalIncomes': incomes.length,
        'totalDebts': debts.length,
        'totalExpenseAmount': expenses.fold(0.0, (sum, e) => sum + e.amount),
        'totalIncomeAmount': incomes.fold(0.0, (sum, i) => sum + i.amount),
      }
    };

    return exportData;
  }

  /// Save export data to file and share
  static Future<String> exportToFile() async {
    try {
      // Get export data
      final exportData = await exportAllData();
      
      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'rupaya_backup_$timestamp.json';
      final filePath = '${directory.path}/$fileName';
      
      // Write file
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return filePath;
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }

  /// Share export file
  static Future<void> shareExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Export file not found');
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Rupaya Backup',
        text: 'My Rupaya financial data backup',
      );
    } catch (e) {
      throw Exception('Share failed: $e');
    }
  }

  /// Pick and import data file
  static Future<Map<String, dynamic>> pickAndImportFile() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        throw Exception('Invalid file path');
      }

      // Read file
      final file = File(filePath);
      final jsonString = await file.readAsString();
      
      // Parse JSON
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate data structure
      _validateImportData(importData);
      
      return importData;
    } catch (e) {
      throw Exception('Import failed: $e');
    }
  }

  /// Validate import data structure
  static void _validateImportData(Map<String, dynamic> data) {
    if (!data.containsKey('version')) {
      throw Exception('Invalid backup file: missing version');
    }
    
    if (!data.containsKey('user')) {
      throw Exception('Invalid backup file: missing user data');
    }
    
    if (!data.containsKey('expenses') || !data.containsKey('incomes') || !data.containsKey('debts')) {
      throw Exception('Invalid backup file: missing financial data');
    }
  }

  /// Import data into database
  static Future<Map<String, int>> importData(Map<String, dynamic> importData) async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null || currentUser.id == null) {
      throw Exception('No user logged in');
    }

    final userId = currentUser.id!;
    int expensesImported = 0;
    int incomesImported = 0;
    int debtsImported = 0;

    try {
      // Import expenses
      final expenses = importData['expenses'] as List<dynamic>;
      for (var expenseData in expenses) {
        try {
          final expense = Expense(
            userId: userId,
            amount: (expenseData['amount'] as num).toDouble(),
            category: expenseData['category'] as String,
            description: expenseData['description'] as String?,
            date: DateTime.parse(expenseData['date'] as String),
            createdAt: DateTime.now(),
          );
          await DatabaseService.addExpense(expense);
          expensesImported++;
        } catch (e) {
          print('Failed to import expense: $e');
        }
      }

      // Import incomes
      final incomes = importData['incomes'] as List<dynamic>;
      for (var incomeData in incomes) {
        try {
          final income = Income(
            userId: userId,
            amount: (incomeData['amount'] as num).toDouble(),
            source: incomeData['source'] as String,
            fromWhom: incomeData['fromWhom'] as String?,
            description: incomeData['description'] as String?,
            date: DateTime.parse(incomeData['date'] as String),
            type: incomeData['type'] as String? ?? 'other',
            isRecurring: incomeData['isRecurring'] as bool? ?? false,
            frequency: incomeData['frequency'] as String?,
            recurringDay: incomeData['recurringDay'] as int?,
            createdAt: DateTime.now(),
          );
          await DatabaseService.addIncome(income);
          incomesImported++;
        } catch (e) {
          print('Failed to import income: $e');
        }
      }

      // Import debts
      final debts = importData['debts'] as List<dynamic>;
      for (var debtData in debts) {
        try {
          final dueDateStr = debtData['dueDate'] as String?;
          final debt = Debt(
            userId: userId,
            personName: debtData['personName'] as String,
            amount: (debtData['amount'] as num).toDouble(),
            paidAmount: (debtData['paidAmount'] as num).toDouble(),
            direction: debtData['direction'] as String,
            description: debtData['description'] as String?,
            dueDate: dueDateStr != null ? DateTime.parse(dueDateStr) : DateTime.now(),
            isSettled: debtData['isSettled'] as bool? ?? false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await DatabaseService.addDebt(debt);
          debtsImported++;
        } catch (e) {
          print('Failed to import debt: $e');
        }
      }

      return {
        'expenses': expensesImported,
        'incomes': incomesImported,
        'debts': debtsImported,
      };
    } catch (e) {
      throw Exception('Import failed: $e');
    }
  }

  /// Get import summary text
  static String getImportSummary(Map<String, int> results) {
    return '''Successfully imported:
• ${results['expenses']} expenses
• ${results['incomes']} incomes
• ${results['debts']} debts''';
  }

  /// Get export summary from data
  static String getExportSummary(Map<String, dynamic> exportData) {
    final stats = exportData['statistics'] as Map<String, dynamic>;
    return '''Backup created:
• ${stats['totalExpenses']} expenses
• ${stats['totalIncomes']} incomes
• ${stats['totalDebts']} debts
• Export date: ${_formatDate(exportData['exportDate'] as String)}''';
  }

  static String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
