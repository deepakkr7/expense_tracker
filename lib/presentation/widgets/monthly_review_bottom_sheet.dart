import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class MonthlyReviewBottomSheet extends StatefulWidget {
  const MonthlyReviewBottomSheet({super.key});

  @override
  State<MonthlyReviewBottomSheet> createState() =>
      _MonthlyReviewBottomSheetState();
}

class _MonthlyReviewBottomSheetState extends State<MonthlyReviewBottomSheet> {
  final _savingsController = TextEditingController();
  bool _showSavingsInput = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _savingsController.dispose();
    super.dispose();
  }

  void _handleNo() {
    Navigator.pop(context);
    _markReviewComplete();
  }

  void _handleYes() {
    setState(() => _showSavingsInput = true);
  }

  Future<void> _submitSavings() async {
    final savedAmount = double.tryParse(_savingsController.text);

    if (savedAmount == null || savedAmount < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    setState(() => _isLoading = true);

    await _markReviewComplete();

    if (mounted) {
      Navigator.pop(context);
      _showFeedbackDialog(savedAmount);
    }
  }

  Future<void> _markReviewComplete() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;

      if (user != null) {
        final updatedUser = user.copyWith(
          lastMonthReviewCompleted: DateTime.now(),
        );
        await authProvider.updateUser(updatedUser);
      }
    } catch (e) {
      // Silent fail - review marked anyway
    }
  }

  void _showFeedbackDialog(double savedAmount) {
    final user = context.read<AuthProvider>().currentUser;
    final savingsGoal = user?.savingsGoal ?? 0;

    String title;
    String message;
    IconData icon;
    Color color;

    if (savedAmount >= savingsGoal && savingsGoal > 0) {
      // Met or exceeded goal
      if (savedAmount > savingsGoal) {
        title = '🎉 Outstanding!';
        message =
            'You saved ₹${savedAmount.toStringAsFixed(0)}, which is ₹${(savedAmount - savingsGoal).toStringAsFixed(0)} more than your goal! You\'re a savings superstar! 🌟';
        icon = Icons.celebration;
        color = AppTheme.successColor;
      } else {
        title = '🎯 Perfect!';
        message =
            'Congratulations! You achieved your savings goal of ₹${savingsGoal.toStringAsFixed(0)}! Keep up the excellent work! 💪';
        icon = Icons.check_circle;
        color = AppTheme.successColor;
      }
    } else if (savedAmount >= savingsGoal * 0.7 && savingsGoal > 0) {
      // 70-99% of goal
      title = '👏 Great Job!';
      message =
          'You saved ₹${savedAmount.toStringAsFixed(0)}! That\'s ${((savedAmount / savingsGoal) * 100).toStringAsFixed(0)}% of your goal. You\'re doing amazing! Just a little more effort next month! 💰';
      icon = Icons.thumb_up;
      color = AppTheme.primaryColor;
    } else if (savedAmount >= savingsGoal * 0.4 && savingsGoal > 0) {
      // 40-69% of goal
      title = '💛 Good Effort!';
      message =
          'You saved ₹${savedAmount.toStringAsFixed(0)}. Every rupee counts! Keep building this habit, and you\'ll reach your goal soon! 🌱';
      icon = Icons.trending_up;
      color = AppTheme.warningColor;
    } else if (savingsGoal > 0) {
      // Less than 40%
      title = '💪 Keep Going!';
      message =
          'You saved ₹${savedAmount.toStringAsFixed(0)}. Starting is the hardest part, and you\'ve already begun! Try reviewing your expenses and finding small cuts for next month. You\'ve got this! 🚀';
      icon = Icons.lightbulb_outline;
      color = AppTheme.accentColor;
    } else {
      // No goal set
      title = '🎊 Well Done!';
      message =
          'You saved ₹${savedAmount.toStringAsFixed(0)}! That\'s fantastic! Consider setting a monthly savings goal in your profile to track your progress. 📈';
      icon = Icons.stars;
      color = AppTheme.secondaryColor;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: color),
            ),
            SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.readableColor(context, color),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lastMonth = DateTime.now().subtract(Duration(days: 1));
    final monthName = DateFormat('MMMM').format(lastMonth);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _showSavingsInput
          ? _buildSavingsInput(monthName)
          : _buildInitialQuestion(monthName),
    );
  }

  Widget _buildInitialQuestion(String monthName) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 24),

          // Icon
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.savings, size: 48, color: Colors.white),
          ),
          SizedBox(height: 20),

          // Title
          Text(
            '$monthName Review 📊',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),

          // Question
          Text(
            'Did you follow your budget plan and save something this month?',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleNo,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Not Really', style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleYes,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Yes! 🎉',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsInput(String monthName) {
    final user = context.read<AuthProvider>().currentUser;
    final savingsGoal = user?.savingsGoal ?? 0;

    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 24),

          // Icon
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet,
              size: 48,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),

          // Title
          Text(
            'Great! 🎊',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),

          // Question
          Text(
            'How much did you save in $monthName?',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),

          // Goal reminder
          if (savingsGoal > 0)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag, color: AppTheme.successColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Your goal: ₹${savingsGoal.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: AppTheme.readableColor(
                        context,
                        AppTheme.successColor,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 20),

          // Input
          TextField(
            controller: _savingsController,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.readableColor(context, AppTheme.primaryColor),
            ),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.readableColor(context, AppTheme.primaryColor),
              ),
              hintText: '0',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitSavings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
