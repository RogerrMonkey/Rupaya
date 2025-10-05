import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/achievements_service.dart';
import '../models/user.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/debt.dart';

class GamificationScreen extends StatefulWidget {
  final String selectedLanguage;

  const GamificationScreen({super.key, required this.selectedLanguage});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false; // Don't keep alive to force reload

  late AnimationController _debtMonsterController;
  late AnimationController _piggyBankController;
  late Animation<double> _monsterScale;
  late Animation<double> _piggyBounce;

  bool isLoading = true;
  User? currentUser;
  List<Expense> expenses = [];
  List<Income> incomes = [];
  List<Debt> debts = [];
  List<Achievement> achievements = [];

  double debtProgress = 0.0;
  double savingsProgress = 0.0;
  double totalDebt = 0.0;
  double repaidDebt = 0.0;
  double savingsTarget = 10000.0;
  double currentSavings = 0.0;
  int totalDays = 0;

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
    _monsterScale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _debtMonsterController, curve: Curves.easeInOut),
    );
    _piggyBounce = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _piggyBankController, curve: Curves.bounceIn),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final db = await DatabaseService.database;
      final userMaps = await db.query('users', limit: 1);
      if (userMaps.isEmpty) {
        setState(() => isLoading = false);
        return;
      }
      currentUser = User.fromJson(userMaps.first);
      final userId = currentUser?.id;
      if (userId == null) {
        debugPrint('User ID is null, cannot load data');
        setState(() => isLoading = false);
        return;
      }
      expenses = await DatabaseService.getExpensesForUser(userId);
      incomes = await DatabaseService.getIncomeForUser(userId);
      debts = await DatabaseService.getDebtsForUser(userId);
      currentSavings = expenses.where((e) => e.category == 'savings').fold(0.0, (sum, e) => sum + e.amount);
      savingsTarget = currentUser!.savingsGoal ?? (currentUser!.monthlyIncomeGoal != null && currentUser!.monthlyIncomeGoal! > 0 ? currentUser!.monthlyIncomeGoal! * 0.3 : 10000.0);
      savingsProgress = savingsTarget > 0 ? (currentSavings / savingsTarget).clamp(0.0, 1.0) : 0.0;
      final owedDebts = debts.where((d) => d.direction == 'owe').toList();
      totalDebt = owedDebts.fold(0.0, (sum, d) => sum + d.amount);
      repaidDebt = owedDebts.fold(0.0, (sum, d) => sum + d.paidAmount);
      debtProgress = totalDebt > 0 ? (repaidDebt / totalDebt).clamp(0.0, 1.0) : 1.0;
      totalDays = DateTime.now().difference(currentUser!.createdAt).inDays;
      achievements = AchievementsService.getAchievements(
        expenses: expenses,
        incomes: incomes,
        debts: debts,
        totalDays: totalDays,
      );
      debugPrint('=== ACHIEVEMENTS DEBUG ===');
      debugPrint('Total achievements: ${achievements.length}');
      debugPrint('Unlocked: ${achievements.where((a) => a.isUnlocked).length}');
      debugPrint('Expenses count: ${expenses.length}');
      debugPrint('Incomes count: ${incomes.length}');
      debugPrint('Debts count: ${debts.length}');
      debugPrint('Total days: $totalDays');
      if (achievements.isEmpty) {
        debugPrint('WARNING: No achievements loaded!');
      } else {
        for (var ach in achievements.take(3)) {
          debugPrint('Achievement: ${ach.id}, Unlocked: ${ach.isUnlocked}');
        }
      }
      debugPrint('=========================');
      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error loading gamification data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8F6),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(_getText('achievements'), style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF46EC13))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(_getText('achievements'), style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: _loadData)],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF46EC13),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicHeight(
                child: Row(children: [
                  Expanded(child: _buildDebtMonsterCard()), 
                  const SizedBox(width: 16), 
                  Expanded(child: _buildPiggyBankCard()),
                ]),
              ),
              const SizedBox(height: 24),
              _buildStatsCard(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_getText('yourAchievements'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF46EC13).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('${achievements.where((a) => a.isUnlocked).length}/${achievements.length}', style: const TextStyle(color: Color(0xFF46EC13), fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (achievements.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No achievements found. Please check the app logs.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...achievements.map((achievement) => _buildAchievementCard(achievement)).toList(),
              const SizedBox(height: 24),
              _buildMotivationalCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtMonsterCard() {
    final monsterSize = 1.0 - (debtProgress * 0.7);
    final remainingDebt = totalDebt - repaidDebt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: debtProgress > 0.8 ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)] : [const Color(0xFFF44336), const Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: (debtProgress > 0.8 ? const Color(0xFF4CAF50) : const Color(0xFFF44336)).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(_getText('debtMonster'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _monsterScale,
            builder: (context, child) => Transform.scale(
              scale: _monsterScale.value * monsterSize,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(40)),
                child: Icon(debtProgress > 0.8 ? Icons.sentiment_very_satisfied : Icons.sentiment_dissatisfied, size: 40, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: debtProgress, backgroundColor: Colors.white.withOpacity(0.3), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), minHeight: 6),
          const SizedBox(height: 12),
          Text(totalDebt > 0 ? '₹${repaidDebt.toStringAsFixed(0)} / ₹${totalDebt.toStringAsFixed(0)}' : _getText('noDebt'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(totalDebt > 0 && remainingDebt > 0 ? '₹${remainingDebt.toStringAsFixed(0)} ${_getText('remaining')}' : '${(debtProgress * 100).toStringAsFixed(0)}% ${_getText('cleared')}', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)))),
        ],
      ),
    );
  }

  Widget _buildPiggyBankCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFC2185B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFE91E63).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(_getText('savingsPig'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _piggyBounce,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -_piggyBounce.value),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(40)),
                child: const Icon(Icons.savings, size: 40, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: savingsProgress, backgroundColor: Colors.white.withOpacity(0.3), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), minHeight: 6),
          const SizedBox(height: 12),
          Text('₹${currentSavings.toStringAsFixed(0)} / ₹${savingsTarget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          Padding(padding: const EdgeInsets.only(top: 4), child: Text('${(savingsProgress * 100).toStringAsFixed(0)}% ${_getText('saved')}', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)))),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalPoints = AchievementsService.getTotalPoints(achievements);
    final completionPercentage = AchievementsService.getCompletionPercentage(achievements);
    final nextAchievement = AchievementsService.getNextAchievement(achievements);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF46EC13), Color(0xFF2E7D32)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF46EC13).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getText('totalPoints'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('$totalPoints ${_getText('points')}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text('${completionPercentage.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(_getText('complete'), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          if (nextAchievement != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(_getIconData(nextAchievement.icon), color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getText('nextGoal'), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                        Text(_getText(nextAchievement.id), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Text('${(nextAchievement.progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
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
        border: achievement.isUnlocked ? Border.all(color: const Color(0xFF46EC13), width: 2) : null,
        boxShadow: achievement.isUnlocked ? [BoxShadow(color: const Color(0xFF46EC13).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3))] : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: achievement.isUnlocked ? const LinearGradient(colors: [Color(0xFF46EC13), Color(0xFF2E7D32)]) : null,
                  color: achievement.isUnlocked ? null : Colors.grey[300],
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: achievement.isUnlocked ? [BoxShadow(color: const Color(0xFF46EC13).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                ),
                child: Icon(_getIconData(achievement.icon), color: achievement.isUnlocked ? Colors.white : Colors.grey[500], size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getText(achievement.id), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: achievement.isUnlocked ? Colors.black : Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(_getText('${achievement.id}_desc'), style: TextStyle(fontSize: 14, color: achievement.isUnlocked ? Colors.grey[700] : Colors.grey[500])),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: achievement.isUnlocked ? const LinearGradient(colors: [Color(0xFF46EC13), Color(0xFF2E7D32)]) : null,
                      color: achievement.isUnlocked ? null : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${achievement.points}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: achievement.isUnlocked ? Colors.white : Colors.grey[500])),
                  ),
                  if (!achievement.isUnlocked) ...[const SizedBox(height: 4), const Icon(Icons.lock, color: Colors.grey, size: 16)],
                ],
              ),
            ],
          ),
          if (!achievement.isUnlocked && achievement.progress > 0) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getText('progress'), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    Text('${(achievement.progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: achievement.progress, backgroundColor: Colors.grey[300], valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF46EC13)), minHeight: 4),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMotivationalCard() {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;
    String message;
    IconData icon;
    List<Color> colors;
    if (unlockedCount == 0) {
      message = _getText('motivationalStart');
      icon = Icons.flag;
      colors = [const Color(0xFF9C27B0), const Color(0xFF673AB7)];
    } else if (unlockedCount < totalCount * 0.3) {
      message = _getText('motivationalBeginner');
      icon = Icons.stars;
      colors = [const Color(0xFF2196F3), const Color(0xFF1976D2)];
    } else if (unlockedCount < totalCount * 0.7) {
      message = _getText('motivationalProgress');
      icon = Icons.trending_up;
      colors = [const Color(0xFFFF9800), const Color(0xFFF57C00)];
    } else if (unlockedCount < totalCount) {
      message = _getText('motivationalAlmost');
      icon = Icons.emoji_events;
      colors = [const Color(0xFFE91E63), const Color(0xFFC2185B)];
    } else {
      message = _getText('motivationalComplete');
      icon = Icons.military_tech;
      colors = [const Color(0xFFFFD700), const Color(0xFFFFA000)];
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(_getText('keepGoing'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('$unlockedCount / $totalCount ${_getText('unlocked')}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final Map<String, IconData> iconMap = {
      'add_circle': Icons.add_circle,
      'assignment': Icons.assignment,
      'trending_up': Icons.trending_up,
      'savings': Icons.savings,
      'account_balance': Icons.account_balance,
      'star': Icons.star,
      'shield': Icons.shield,
      'military_tech': Icons.military_tech,
      'check_circle': Icons.check_circle,
      'emoji_events': Icons.emoji_events,
      'payment': Icons.payment,
      'attach_money': Icons.attach_money,
      'date_range': Icons.date_range,
      'calendar_today': Icons.calendar_today,
      'explore': Icons.explore,
    };
    return iconMap[iconName] ?? Icons.star;
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
        'noDebt': 'कोई कर्ज नहीं!',
        'remaining': 'बाकी',
        'cleared': 'साफ़',
        'saved': 'बचत',
        'complete': 'पूर्ण',
        'nextGoal': 'अगला लक्ष्य',
        'progress': 'प्रगति',
        'unlocked': 'अनलॉक',
        'first_expense': 'पहला कदम',
        'first_expense_desc': 'पहला खर्च जोड़ा',
        'expense_tracker': 'खर्च ट्रैकर',
        'expense_tracker_desc': '10 खर्च ट्रैक करें',
        'dedicated_tracker': 'समर्पित ट्रैकर',
        'dedicated_tracker_desc': '50 खर्च ट्रैक करें',
        'savings_start': 'बचत शुरुआती',
        'savings_start_desc': '₹1,000 बचाएं',
        'savings_pro': 'बचत प्रो',
        'savings_pro_desc': '₹5,000 बचाएं',
        'savings_master': 'बचत मास्टर',
        'savings_master_desc': '₹10,000 बचाएं',
        'debt_warrior': 'कर्ज योद्धा',
        'debt_warrior_desc': 'कर्ज ट्रैक करना शुरू किया',
        'debt_slayer': 'कर्ज हत्यारा',
        'debt_slayer_desc': '50% कर्ज चुकता करें',
        'debt_crusher': 'कर्ज संहारक',
        'debt_crusher_desc': 'पहला कर्ज पूरी तरह चुकाएं',
        'debt_free': 'कर्ज मुक्त हीरो',
        'debt_free_desc': 'पूरी तरह कर्ज मुक्त',
        'income_tracker': 'आय ट्रैकर',
        'income_tracker_desc': 'पहली आय दर्ज करें',
        'earner': 'बड़ा कमाने वाला',
        'earner_desc': 'कुल ₹50,000 कमाएं',
        'week_streak': 'लगातार सप्ताह',
        'week_streak_desc': '7 दिनों तक खर्च ट्रैक करें',
        'month_streak': 'मासिक समर्पण',
        'month_streak_desc': '30 दिनों तक सक्रिय रहें',
        'category_explorer': 'श्रेणी खोजकर्ता',
        'category_explorer_desc': '5 विभिन्न श्रेणियों का उपयोग करें',
        'motivationalStart': 'अपनी यात्रा शुरू करें! पहली उपलब्धि अनलॉक करें।',
        'motivationalBeginner': 'शानदार शुरुआत! और उपलब्धियां अनलॉक करते रहें।',
        'motivationalProgress': 'बहुत बढ़िया! आप आधे रास्ते पर हैं!',
        'motivationalAlmost': 'लगभग पूरा! बस कुछ और उपलब्धियां बाकी हैं।',
        'motivationalComplete': 'अद्भुत! आपने सभी उपलब्धियां अनलॉक कर ली हैं!',
      },
      'mr': {
        'achievements': 'यश',
        'debtMonster': 'कर्ज राक्षस',
        'savingsPig': 'बचत डुक्कर',
        'totalPoints': 'एकूण गुण',
        'points': 'गुण',
        'yourAchievements': 'तुमच्या यशा',
        'keepGoing': 'अभिनंदन!',
        'noDebt': 'कर्ज नाही!',
        'remaining': 'उरलेले',
        'cleared': 'साफ',
        'saved': 'बचत',
        'complete': 'पूर्ण',
        'nextGoal': 'पुढील ध्येय',
        'progress': 'प्रगती',
        'unlocked': 'अनलॉक',
        'first_expense': 'पहिले पाऊल',
        'first_expense_desc': 'पहिला खर्च जोडला',
        'expense_tracker': 'खर्च ट्रॅकर',
        'expense_tracker_desc': '10 खर्च ट्रॅक करा',
        'dedicated_tracker': 'समर्पित ट्रॅकर',
        'dedicated_tracker_desc': '50 खर्च ट्रॅक करा',
        'savings_start': 'बचत सुरुवात',
        'savings_start_desc': '₹1,000 बचत करा',
        'savings_pro': 'बचत प्रो',
        'savings_pro_desc': '₹5,000 बचत करा',
        'savings_master': 'बचत मास्टर',
        'savings_master_desc': '₹10,000 बचत करा',
        'debt_warrior': 'कर्ज योद्धा',
        'debt_warrior_desc': 'कर्ज ट्रॅक करणे सुरू केले',
        'debt_slayer': 'कर्ज संहारक',
        'debt_slayer_desc': '50% कर्ज फेडा',
        'debt_crusher': 'कर्ज क्रशर',
        'debt_crusher_desc': 'पहिले कर्ज पूर्णपणे फेडा',
        'debt_free': 'कर्ज मुक्त हिरो',
        'debt_free_desc': 'पूर्णपणे कर्ज मुक्त',
        'income_tracker': 'उत्पन्न ट्रॅकर',
        'income_tracker_desc': 'पहिले उत्पन्न नोंदवा',
        'earner': 'मोठा कमावणारा',
        'earner_desc': 'एकूण ₹50,000 कमवा',
        'week_streak': 'सातत्यपूर्ण आठवडा',
        'week_streak_desc': '7 दिवसांपर्यंत खर्च ट्रॅक करा',
        'month_streak': 'मासिक समर्पण',
        'month_streak_desc': '30 दिवसांपर्यंत सक्रिय रहा',
        'category_explorer': 'श्रेणी अन्वेषक',
        'category_explorer_desc': '5 विविध श्रेण्या वापरा',
        'motivationalStart': 'तुमचा प्रवास सुरू करा! पहिले यश अनलॉक करा.',
        'motivationalBeginner': 'उत्तम सुरुवात! आणखी यशे अनलॉक करा.',
        'motivationalProgress': 'अप्रतिम! तुम्ही अर्ध्या मार्गावर आहात!',
        'motivationalAlmost': 'जवळजवळ पूर्ण! फक्त काही यशे शिल्लक आहेत.',
        'motivationalComplete': 'आश्चर्यकारक! तुम्ही सर्व यशे अनलॉक केलीत!',
      },
      'en': {
        'achievements': 'Achievements',
        'debtMonster': 'Debt Monster',
        'savingsPig': 'Savings Pig',
        'totalPoints': 'Total Points',
        'points': 'Points',
        'yourAchievements': 'Your Achievements',
        'keepGoing': 'Congratulations!',
        'noDebt': 'No Debt!',
        'remaining': 'remaining',
        'cleared': 'cleared',
        'saved': 'saved',
        'complete': 'Complete',
        'nextGoal': 'Next Goal',
        'progress': 'Progress',
        'unlocked': 'Unlocked',
        'first_expense': 'First Step',
        'first_expense_desc': 'Added your first expense',
        'expense_tracker': 'Expense Tracker',
        'expense_tracker_desc': 'Track 10 expenses',
        'dedicated_tracker': 'Dedicated Tracker',
        'dedicated_tracker_desc': 'Track 50 expenses',
        'savings_start': 'Savings Beginner',
        'savings_start_desc': 'Save ₹1,000',
        'savings_pro': 'Savings Pro',
        'savings_pro_desc': 'Save ₹5,000',
        'savings_master': 'Savings Master',
        'savings_master_desc': 'Save ₹10,000',
        'debt_warrior': 'Debt Warrior',
        'debt_warrior_desc': 'Started tracking debts',
        'debt_slayer': 'Debt Slayer',
        'debt_slayer_desc': 'Repaid 50% of debt',
        'debt_crusher': 'Debt Crusher',
        'debt_crusher_desc': 'Settle your first debt completely',
        'debt_free': 'Debt Free Hero',
        'debt_free_desc': 'Completely debt free',
        'income_tracker': 'Income Tracker',
        'income_tracker_desc': 'Record your first income',
        'earner': 'Big Earner',
        'earner_desc': 'Earn ₹50,000 in total',
        'week_streak': 'Consistent Week',
        'week_streak_desc': 'Track expenses for 7 consecutive days',
        'month_streak': 'Monthly Dedication',
        'month_streak_desc': 'Active for 30 days',
        'category_explorer': 'Category Explorer',
        'category_explorer_desc': 'Use 5 different expense categories',
        'motivationalStart': 'Start your journey! Unlock your first achievement.',
        'motivationalBeginner': 'Great start! Keep unlocking more achievements.',
        'motivationalProgress': 'Awesome! You\'re halfway there!',
        'motivationalAlmost': 'Almost there! Just a few more achievements.',
        'motivationalComplete': 'Amazing! You\'ve unlocked all achievements!',
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