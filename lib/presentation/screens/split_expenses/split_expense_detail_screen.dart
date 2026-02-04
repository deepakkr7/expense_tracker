import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/split_expense_provider.dart';
import '../../../providers/friend_provider.dart';
import '../../../data/models/split_expense_model.dart';
import '../../../core/theme/app_theme.dart';

class SplitExpenseDetailScreen extends StatefulWidget {
  final SplitExpenseModel expense;

  const SplitExpenseDetailScreen({super.key, required this.expense});

  @override
  State<SplitExpenseDetailScreen> createState() =>
      _SplitExpenseDetailScreenState();
}

class _SplitExpenseDetailScreenState extends State<SplitExpenseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final friendProvider = context.watch<FriendProvider>();

    final totalSettled = widget.expense.settled.values
        .where((isSettled) => isSettled)
        .length;
    final totalPeople = widget.expense.splits.length;
    final isFullySettled = totalSettled == totalPeople;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteExpense(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFullySettled
                      ? [
                          AppTheme.successColor,
                          AppTheme.successColor.withOpacity(0.8),
                        ]
                      : [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.expense.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(widget.expense.date),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${widget.expense.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isFullySettled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'All Settled!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Split between ${totalPeople + 1} people',
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),

            // Settlement Progress
            if (!isFullySettled)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Settlement Progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '$totalSettled / $totalPeople',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: totalPeople > 0 ? totalSettled / totalPeople : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.successColor,
                      ),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),

            // People List
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Who Owes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...widget.expense.splits.entries.map((entry) {
                    final friendId = entry.key;
                    final amount = entry.value;
                    final isSettled = widget.expense.settled[friendId] ?? false;

                    // Find friend
                    final friend = friendProvider.friends.firstWhere(
                      (f) => f.id == friendId,
                      orElse: () => friendProvider.friends.first,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isSettled
                          ? AppTheme.successColor.withOpacity(0.1)
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSettled
                              ? AppTheme.successColor
                              : AppTheme.primaryColor,
                          child: Text(
                            friend.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          friend.name,
                          style: TextStyle(
                            decoration: isSettled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          isSettled ? 'Settled' : 'Pending',
                          style: TextStyle(
                            color: isSettled
                                ? AppTheme.successColor
                                : Colors.orange,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSettled
                                    ? AppTheme.successColor
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (!isSettled)
                              ElevatedButton(
                                onPressed: () => _settleAmount(
                                  context,
                                  friendId,
                                  friend.name,
                                  amount,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Settle',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            else
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.successColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _settleAmount(
    BuildContext context,
    String friendId,
    String friendName,
    double amount,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Settlement'),
        content: Text(
          'Mark ₹${amount.toStringAsFixed(0)} from $friendName as settled?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Settle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authProvider = context.read<AuthProvider>();
      final splitProvider = context.read<SplitExpenseProvider>();

      try {
        await splitProvider.markAsSettled(
          authProvider.currentUser!.id,
          widget.expense.id,
          friendId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Marked as settled with $friendName'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _deleteExpense(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('This action cannot be undone'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final authProvider = context.read<AuthProvider>();
      final splitProvider = context.read<SplitExpenseProvider>();

      try {
        await splitProvider.deleteSplitExpense(
          authProvider.currentUser!.id,
          widget.expense.id,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Expense deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
