import 'package:flutter/material.dart';

class GamificationScreen extends StatefulWidget {
  final String selectedLanguage;

  const GamificationScreen({super.key, required this.selectedLanguage});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> with TickerProviderStateMixin {
  late AnimationController _debtMonsterController;
  late AnimationController _piggyBankController;
  late Animation<double> _monsterScale;
  late Animation<double> _piggyBounce;

  // Mock data - replace with actual data
  double debtProgress = 0.6; // 60% debt repaid
  double savingsProgress = 0.3; // 30% savings goal achieved
  int totalDebt = 5000;
  int repaidDebt = 3000;
  int savingsTarget = 10000;
  int currentSavings = 3000;

  final List<Achievement> achievements = [
    Achievement(
      id: 'first_expense',
      title: 'First Step',
      description: 'Added your first expense',
      icon: Icons.add_circle,
      isUnlocked: true,
      points: 10,
    ),
    Achievement(
      id: 'debt_tracker',
      title: 'Debt Warrior',
      description: 'Started tracking debts',
      icon: Icons.shield,
      isUnlocked: true,
      points: 20,
    ),
    Achievement(
      id: 'savings_start',
      title: 'Savings Beginner',
      description: 'Saved ₹1000',
      icon: Icons.savings,
      isUnlocked: true,
      points: 50,
    ),
    Achievement(
      id: 'debt_slayer',
      title: 'Debt Slayer',
      description: 'Repaid 50% of debt',
      icon: Icons.military_tech,
      isUnlocked: true,
      points: 100,
    ),
    Achievement(
      id: 'savings_master',
      title: 'Savings Master',
      description: 'Save ₹5000',
      icon: Icons.star,
      isUnlocked: false,
      points: 200,
    ),
    Achievement(
      id: 'debt_free',
      title: 'Debt Free Hero',
      description: 'Completely debt free',
      icon: Icons.emoji_events,
      isUnlocked: false,
      points: 500,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _debtMonsterController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _piggyBankController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _monsterScale = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _debtMonsterController,
      curve: Curves.easeInOut,
    ));

    _piggyBounce = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _piggyBankController,
      curve: Curves.bounceIn,
    ));
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
          _getText('achievements'),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Overview
            Row(
              children: [
                Expanded(child: _buildDebtMonsterCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildPiggyBankCard()),
              ],
            ),

            const SizedBox(height: 24),

            // Achievement Points
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
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getText('totalPoints'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_calculateTotalPoints()} ${_getText('points')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Achievements List
            Text(
              _getText('yourAchievements'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            ...achievements.map((achievement) => _buildAchievementCard(achievement)).toList(),

            const SizedBox(height: 24),

            // Motivational Messages
            _buildMotivationalCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtMonsterCard() {
    final monsterSize = 1.0 - (debtProgress * 0.7); // Monster shrinks as debt is repaid

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
        children: [
          Text(
            _getText('debtMonster'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          AnimatedBuilder(
            animation: _monsterScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _monsterScale.value * monsterSize,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: debtProgress > 0.8
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF44336),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    debtProgress > 0.8
                        ? Icons.sentiment_very_satisfied
                        : Icons.sentiment_dissatisfied,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          LinearProgressIndicator(
            value: debtProgress,
            backgroundColor: Colors.red.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),

          const SizedBox(height: 8),

          Text(
            '₹$repaidDebt / ₹$totalDebt',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPiggyBankCard() {
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
        children: [
          Text(
            _getText('savingsPig'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          AnimatedBuilder(
            animation: _piggyBounce,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_piggyBounce.value),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.savings,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          LinearProgressIndicator(
            value: savingsProgress,
            backgroundColor: Colors.pink.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
          ),

          const SizedBox(height: 8),

          Text(
            '₹$currentSavings / ₹$savingsTarget',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement.isUnlocked ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: achievement.isUnlocked
            ? Border.all(color: const Color(0xFF46EC13), width: 2)
            : null,
        boxShadow: achievement.isUnlocked ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? const Color(0xFF46EC13).withOpacity(0.1)
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              achievement.icon,
              color: achievement.isUnlocked
                  ? const Color(0xFF46EC13)
                  : Colors.grey[500],
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getText(achievement.id),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: achievement.isUnlocked ? Colors.black : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getText('${achievement.id}_desc'),
                  style: TextStyle(
                    fontSize: 14,
                    color: achievement.isUnlocked ? Colors.grey[700] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: achievement.isUnlocked
                      ? const Color(0xFF46EC13).withOpacity(0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${achievement.points}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: achievement.isUnlocked
                        ? const Color(0xFF46EC13)
                        : Colors.grey[500],
                  ),
                ),
              ),

              if (!achievement.isUnlocked)
                const Icon(
                  Icons.lock,
                  color: Colors.grey,
                  size: 16,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 40,
          ),

          const SizedBox(height: 16),

          Text(
            _getText('keepGoing'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            _getText('motivationalMessage'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _calculateTotalPoints() {
    return achievements
        .where((achievement) => achievement.isUnlocked)
        .fold(0, (sum, achievement) => sum + achievement.points);
  }

  String _getText(String key) {
    final texts = {
      'hi': {
        'achievements': 'उपलब्धियां',
        'debtMonster': 'कर्ज राक्षस',
        'savingsPig': 'बचत सुअर',
        'totalPoints': 'कुल अंक',
        'points': 'अंक',
        'yourAchievements': 'आपकी उपलब्धियां',
        'keepGoing': 'बधाई हो!',
        'motivationalMessage': 'आप बहुत अच्छा कर रहे हैं! और भी उपलब्धियां अनलॉक करें।',
        'first_expense': 'पहला कदम',
        'first_expense_desc': 'पहला खर्च जोड़ा',
        'debt_tracker': 'कर्ज योद्धा',
        'debt_tracker_desc': 'कर्ज ट्रैक करना शुरू किया',
        'savings_start': 'बचत शुरुआती',
        'savings_start_desc': '₹1000 बचाए',
        'debt_slayer': 'कर्ज हत्यारा',
        'debt_slayer_desc': '50% कर्ज चुकता किया',
        'savings_master': 'बचत मास्टर',
        'savings_master_desc': '₹5000 बचाएं',
        'debt_free': 'कर्ज मुक्त हीरो',
        'debt_free_desc': 'पूरी तरह कर्ज मुक्त',
      },
      'mr': {
        'achievements': 'यश',
        'debtMonster': 'कर्ज राक्षस',
        'savingsPig': 'बचत डुक्कर',
        'totalPoints': 'एकूण गुण',
        'points': 'गुण',
        'yourAchievements': 'तुमच्या यशा',
        'keepGoing': 'अभिनंदन!',
        'motivationalMessage': 'तुम्ही खूप चांगले करत आहात! आणखी यशे अनलॉक करा.',
        'first_expense': 'पहिले पाऊल',
        'first_expense_desc': 'पहिला खर्च जोडला',
        'debt_tracker': 'कर्ज योद्धा',
        'debt_tracker_desc': 'कर्ज ट्रॅक करणे सुरू केले',
        'savings_start': 'बचत सुरुवात',
        'savings_start_desc': '₹1000 बचत केली',
        'debt_slayer': 'कर्ज संहारक',
        'debt_slayer_desc': '50% कर्ज फेडले',
        'savings_master': 'बचत मास्टर',
        'savings_master_desc': '₹5000 बचत करा',
        'debt_free': 'कर्ज मुक्त हिरो',
        'debt_free_desc': 'पूर्णपणे कर्ज मुक्त',
      },
      'en': {
        'achievements': 'Achievements',
        'debtMonster': 'Debt Monster',
        'savingsPig': 'Savings Pig',
        'totalPoints': 'Total Points',
        'points': 'Points',
        'yourAchievements': 'Your Achievements',
        'keepGoing': 'Congratulations!',
        'motivationalMessage': 'You\'re doing great! Unlock more achievements.',
        'first_expense': 'First Step',
        'first_expense_desc': 'Added your first expense',
        'debt_tracker': 'Debt Warrior',
        'debt_tracker_desc': 'Started tracking debts',
        'savings_start': 'Savings Beginner',
        'savings_start_desc': 'Saved ₹1000',
        'debt_slayer': 'Debt Slayer',
        'debt_slayer_desc': 'Repaid 50% of debt',
        'savings_master': 'Savings Master',
        'savings_master_desc': 'Save ₹5000',
        'debt_free': 'Debt Free Hero',
        'debt_free_desc': 'Completely debt free',
      },
    };

    return texts[widget.selectedLanguage]?[key] ?? texts['en']![key]!;
  }

  @override
  void dispose() {
    _debtMonsterController.dispose();
    _piggyBankController.dispose();
    super.dispose();
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final int points;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.points,
  });
}
