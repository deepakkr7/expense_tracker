import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/split_expense_provider.dart';
import '../../../providers/friend_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'create_split_expense_screen.dart';
import 'split_expense_detail_screen.dart';

class SplitExpensesScreen extends StatefulWidget {
  const SplitExpensesScreen({super.key});

  @override
  State<SplitExpensesScreen> createState() => _SplitExpensesScreenState();
}

class _SplitExpensesScreenState extends State<SplitExpensesScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule data loading after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final splitProvider = context.read<SplitExpenseProvider>();
    final friendProvider = context.read<FriendProvider>();

    if (authProvider.currentUser != null) {
      splitProvider.loadSplitExpenses(authProvider.currentUser!.id);
      friendProvider.loadFriends(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final splitProvider = context.watch<SplitExpenseProvider>();
    final friendProvider = context.watch<FriendProvider>();
    final authProvider = context.read<AuthProvider>();

    final balances = splitProvider.calculateBalances(
      authProvider.currentUser?.id ?? '',
    );
    final totalOwed = splitProvider.getTotalOwed(
      authProvider.currentUser?.id ?? '',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Split Expenses'), elevation: 0),
      body: splitProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Summary Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Balance',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${totalOwed.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalOwed > 0
                              ? 'Others owe you'
                              : totalOwed < 0
                              ? 'You owe others'
                              : 'All settled!',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Balances List
                  if (balances.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Balances',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${balances.length} ${balances.length == 1 ? 'person' : 'people'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...balances.entries.map((entry) {
                      final friendId = entry.key;
                      final amount = entry.value;

                      // Find friend name - handle case where friend might not be in list
                      final friend = friendProvider.friends.isNotEmpty
                          ? friendProvider.friends.firstWhere(
                              (f) => f.id == friendId,
                              orElse: () => friendProvider.friends.first,
                            )
                          : null;

                      // Skip if no friend data available
                      if (friend == null) {
                        return const SizedBox.shrink();
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: amount > 0
                                ? AppTheme.successColor
                                : Colors.orange,
                            child: Text(
                              friend.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(friend.name),
                          subtitle: Text(
                            amount > 0 ? 'Owes you' : 'You owe',
                            style: TextStyle(
                              color: amount > 0
                                  ? AppTheme.successColor
                                  : Colors.orange,
                            ),
                          ),
                          trailing: Text(
                            '₹${amount.abs().toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: amount > 0
                                  ? AppTheme.successColor
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      );
                    }),
                  ] else
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Split Expenses',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create your first split expense',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Recent Expenses
                  if (splitProvider.pendingSplitExpenses.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pending Expenses',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${splitProvider.pendingSplitExpenses.length}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...splitProvider.pendingSplitExpenses.map((expense) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.2,
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(expense.description),
                          subtitle: Text(
                            DateFormat('MMM dd, yyyy').format(expense.date),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${expense.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${expense.splits.length} people',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SplitExpenseDetailScreen(expense: expense),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSplitExpenseScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Split Expense'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
