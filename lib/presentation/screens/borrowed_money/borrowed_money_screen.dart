import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/borrowed_money_provider.dart';
import '../../../data/models/borrowed_money_model.dart';
import '../../../core/theme/app_theme.dart';
import 'add_borrowed_money_screen.dart';
import 'edit_borrowed_money_screen.dart';

class BorrowedMoneyScreen extends StatefulWidget {
  const BorrowedMoneyScreen({super.key});

  @override
  State<BorrowedMoneyScreen> createState() => _BorrowedMoneyScreenState();
}

class _BorrowedMoneyScreenState extends State<BorrowedMoneyScreen> {
  bool _showOnlyUnpaid = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      if (_showOnlyUnpaid) {
        context.read<BorrowedMoneyProvider>().loadUnpaidBorrowedMoney(userId);
      } else {
        context.read<BorrowedMoneyProvider>().loadBorrowedMoney(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borrowedMoneyProvider = context.watch<BorrowedMoneyProvider>();
    final unpaidByPerson = borrowedMoneyProvider.unpaidByPerson;
    final totalsByPerson = borrowedMoneyProvider.totalsByPerson;
    final displayData = _showOnlyUnpaid ? unpaidByPerson : totalsByPerson;

    // Get total unpaid amount
    final totalUnpaid = unpaidByPerson.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrowed Money'),
        actions: [
          IconButton(
            icon: Icon(
              _showOnlyUnpaid ? Icons.check_circle : Icons.check_circle_outline,
            ),
            onPressed: () {
              setState(() {
                _showOnlyUnpaid = !_showOnlyUnpaid;
                _loadData();
              });
            },
            tooltip: _showOnlyUnpaid ? 'Show All' : 'Show Unpaid Only',
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Unpaid Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Total Unpaid',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${totalUnpaid.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${unpaidByPerson.length} ${unpaidByPerson.length == 1 ? 'person' : 'people'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Toggle Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      _showOnlyUnpaid
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                    ),
                    label: Text(
                      _showOnlyUnpaid ? 'Unpaid Only' : 'All Transactions',
                    ),
                    onPressed: () {
                      setState(() {
                        _showOnlyUnpaid = !_showOnlyUnpaid;
                        _loadData();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // List of people
          Expanded(
            child: displayData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showOnlyUnpaid
                              ? 'No unpaid borrowed money'
                              : 'No borrowed money records',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayData.length,
                    itemBuilder: (context, index) {
                      final personName = displayData.keys.elementAt(index);
                      final totalAmount = displayData[personName]!;
                      final transactions = borrowedMoneyProvider
                          .getTransactionsForPerson(personName);
                      final unpaidCount = transactions
                          .where((t) => !t.isPaid)
                          .length;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            _showPersonDetails(
                              context,
                              personName,
                              transactions,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppTheme.primaryColor
                                      .withOpacity(0.1),
                                  child: Text(
                                    personName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        personName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _showOnlyUnpaid
                                            ? '$unpaidCount unpaid ${unpaidCount == 1 ? 'transaction' : 'transactions'}'
                                            : '${transactions.length} total ${transactions.length == 1 ? 'transaction' : 'transactions'}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Amount
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${totalAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _showOnlyUnpaid
                                            ? Colors.red.shade600
                                            : AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBorrowedMoneyScreen()),
          );
          // Reload data when returning from add screen
          _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showPersonDetails(
    BuildContext context,
    String personName,
    List<BorrowedMoneyModel> transactions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Text(
                        personName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        personName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Transactions list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _buildTransactionCard(context, transaction);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    BorrowedMoneyModel transaction,
  ) {
    final authProvider = context.read<AuthProvider>();
    final borrowedMoneyProvider = context.read<BorrowedMoneyProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${transaction.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(transaction.date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: transaction.isPaid
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    transaction.isPaid ? 'Paid' : 'Unpaid',
                    style: TextStyle(
                      color: transaction.isPaid ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (transaction.description != null &&
                transaction.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                transaction.description!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!transaction.isPaid)
                    TextButton.icon(
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Paid', style: TextStyle(fontSize: 13)),
                      onPressed: () async {
                        // Close modal first
                        Navigator.pop(context);

                        final updated = transaction.copyWith(
                          isPaid: true,
                          paidDate: DateTime.now(),
                        );

                        await borrowedMoneyProvider.updateBorrowedMoney(
                          updated,
                          previousState: transaction,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Marked as paid and added to expenses',
                              ),
                            ),
                          );
                          // Reload data to reflect changes
                          _loadData();
                        }
                      },
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 13)),
                    onPressed: () async {
                      // Close modal first
                      Navigator.pop(context);

                      // Await the edit screen
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditBorrowedMoneyScreen(transaction: transaction),
                        ),
                      );

                      // Reload data after returning
                      if (context.mounted) {
                        _loadData();
                      }
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Transaction'),
                          content: const Text(
                            'Are you sure you want to delete this transaction?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && context.mounted) {
                        await borrowedMoneyProvider.deleteBorrowedMoney(
                          authProvider.currentUser!.id,
                          transaction.id,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaction deleted'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
