import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/expense.dart';
import '../models/income.dart';

/// Service for generating AI-powered insights using OpenRouter API
class AIInsightsService {
  static final String _apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  /// Generate AI insights from spending data
  static Future<Map<String, dynamic>> generateAIInsights({
    required List<Expense> expenses,
    required List<Income> incomes,
    required Map<String, double> categoryBreakdown,
    required double monthlyTotal,
    required double dailyAverage,
  }) async {
    try {
      // Prepare spending summary for AI
      final spendingSummary = _prepareSummary(
        expenses: expenses,
        incomes: incomes,
        categoryBreakdown: categoryBreakdown,
        monthlyTotal: monthlyTotal,
        dailyAverage: dailyAverage,
      );

      // Call OpenRouter API
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://rupaya.app',
          'X-Title': 'Rupaya Finance App',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-3.1-8b-instruct:free', // Free tier model
          'messages': [
            {
              'role': 'system',
              'content': '''You are a helpful financial advisor for a budgeting app called Rupaya. 
Analyze user spending data and provide 3-4 concise, actionable insights in JSON format.
Each insight should have: type (tip/warning/success/info), title (short), description (1 sentence), category (relevant spending category if applicable).
Be encouraging and practical. Use Indian Rupees (₹) in examples.'''
            },
            {
              'role': 'user',
              'content': 'Analyze my spending and give me insights:\n$spendingSummary'
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        
        // Parse AI response into structured insights
        return {
          'success': true,
          'insights': _parseAIResponse(aiResponse),
          'rawResponse': aiResponse,
        };
      } else {
        return {
          'success': false,
          'error': 'API Error: ${response.statusCode}',
          'insights': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'insights': [],
      };
    }
  }

  /// Prepare spending summary for AI
  static String _prepareSummary({
    required List<Expense> expenses,
    required List<Income> incomes,
    required Map<String, double> categoryBreakdown,
    required double monthlyTotal,
    required double dailyAverage,
  }) {
    final buffer = StringBuffer();
    
    // Overall stats
    buffer.writeln('Monthly Spending: ₹${monthlyTotal.toStringAsFixed(0)}');
    buffer.writeln('Daily Average: ₹${dailyAverage.toStringAsFixed(0)}');
    buffer.writeln('Total Transactions: ${expenses.length}');
    
    // Income
    if (incomes.isNotEmpty) {
      final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
      final savings = totalIncome - monthlyTotal;
      buffer.writeln('Monthly Income: ₹${totalIncome.toStringAsFixed(0)}');
      buffer.writeln('Savings: ₹${savings.toStringAsFixed(0)}');
    }
    
    // Category breakdown
    buffer.writeln('\nCategory Breakdown:');
    for (var entry in categoryBreakdown.entries.take(5)) {
      final percentage = monthlyTotal > 0 ? (entry.value / monthlyTotal * 100) : 0;
      buffer.writeln('- ${entry.key}: ₹${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%)');
    }
    
    // Recent pattern (last 5 expenses)
    if (expenses.length >= 5) {
      buffer.writeln('\nRecent Expenses:');
      final recent = expenses.take(5).toList();
      for (var expense in recent) {
        buffer.writeln('- ${expense.category}: ₹${expense.amount.toStringAsFixed(0)}');
      }
    }
    
    return buffer.toString();
  }

  /// Parse AI response into structured insights
  static List<Map<String, String>> _parseAIResponse(String response) {
    final insights = <Map<String, String>>[];
    
    try {
      // Try to parse as JSON first
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0);
        final parsed = jsonDecode(jsonStr!) as List;
        
        for (var item in parsed) {
          insights.add({
            'type': item['type'] ?? 'info',
            'title': item['title'] ?? 'Insight',
            'description': item['description'] ?? '',
            'icon': _getIconForType(item['type'] ?? 'info'),
            'category': item['category'] ?? '',
          });
        }
        
        return insights;
      }
      
      // Fallback: Parse as text blocks
      final lines = response.split('\n');
      Map<String, String>? currentInsight;
      
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;
        
        // Detect new insight
        if (line.toLowerCase().contains('tip:') || 
            line.toLowerCase().contains('warning:') ||
            line.toLowerCase().contains('success:') ||
            line.toLowerCase().contains('insight:')) {
          
          if (currentInsight != null) {
            insights.add(currentInsight);
          }
          
          currentInsight = {
            'type': _detectType(line),
            'title': line.replaceAll(RegExp(r'(tip:|warning:|success:|insight:)', caseSensitive: false), '').trim(),
            'description': '',
            'icon': 'lightbulb',
          };
        } else if (currentInsight != null) {
          // Add to description
          currentInsight['description'] = 
              (currentInsight['description']! + ' ' + line).trim();
        }
      }
      
      if (currentInsight != null) {
        insights.add(currentInsight);
      }
      
      // If still no insights, create a generic one from the response
      if (insights.isEmpty && response.isNotEmpty) {
        insights.add({
          'type': 'info',
          'title': 'AI Insight',
          'description': response.split('\n').first.trim(),
          'icon': 'psychology',
        });
      }
      
    } catch (e) {
      // Return error insight
      insights.add({
        'type': 'error',
        'title': 'Could not parse AI response',
        'description': response.substring(0, response.length > 100 ? 100 : response.length),
        'icon': 'error',
      });
    }
    
    return insights;
  }

  /// Detect insight type from text
  static String _detectType(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('warning') || lower.contains('alert') || lower.contains('overspend')) {
      return 'warning';
    } else if (lower.contains('success') || lower.contains('great') || lower.contains('good')) {
      return 'success';
    } else if (lower.contains('tip') || lower.contains('try') || lower.contains('consider')) {
      return 'tip';
    }
    return 'info';
  }

  /// Get icon for insight type
  static String _getIconForType(String type) {
    switch (type) {
      case 'warning':
        return 'warning';
      case 'success':
        return 'check_circle';
      case 'tip':
        return 'lightbulb';
      case 'info':
      default:
        return 'info';
    }
  }

  /// Generate personalized saving tips based on category
  static Future<List<String>> generateSavingTips(
    String category,
    double amount,
    double percentage,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://rupaya.app',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-3.1-8b-instruct:free',
          'messages': [
            {
              'role': 'user',
              'content': '''Give me 3 specific, actionable tips to reduce spending on $category. 
Currently spending ₹${amount.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}% of budget).
Return only the tips as a JSON array of strings. Be practical and India-specific.'''
            }
          ],
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        
        // Try to parse as JSON array
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(aiResponse);
        if (jsonMatch != null) {
          final tips = jsonDecode(jsonMatch.group(0)!) as List;
          return tips.map((t) => t.toString()).toList();
        }
        
        // Fallback: split by newlines
        return aiResponse
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .take(3)
            .toList();
      }
    } catch (e) {
      // Return generic tips as fallback
    }
    
    // Fallback tips
    return [
      'Track all expenses in $category to identify patterns',
      'Set a weekly budget limit for $category',
      'Look for alternatives or discounts in $category'
    ];
  }
}
