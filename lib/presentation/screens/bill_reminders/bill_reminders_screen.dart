import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bill_reminder_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../data/models/bill_reminder_model.dart';
import '../../../core/theme/app_theme.dart';
import 'add_bill_reminder_screen.dart';
import 'edit_bill_reminder_screen.dart';

class BillRemindersScreen extends StatefulWidget {
  const BillRemindersScreen({super.key});

  @override
  State<BillRemindersScreen> createState() => _BillRemindersScreenState();
}

class _BillRemindersScreenState extends State<BillRemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      final billProvider = context.read<BillReminderProvider>();
      billProvider.loadBills(userId);
      billProvider.loadUpcomingBills(userId);
      billProvider.loadOverdueBills(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillReminderProvider>();
    final billsByStatus = billProvider.getBillsByStatus();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Reminders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Upcoming'),
                  if (billsByStatus['upcoming']!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${billsByStatus['upcoming']!.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Overdue'),
                  if (billsByStatus['overdue']!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${billsByStatus['overdue']!.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Tab(text: 'Paid'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary Card
          _buildSummaryCard(billProvider),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBillsList(billsByStatus['upcoming']!, 'upcoming'),
                _buildBillsList(billsByStatus['overdue']!, 'overdue'),
                _buildBillsList(billsByStatus['paid']!, 'paid'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBillReminderScreen()),
          );
          _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Bill'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSummaryCard(BillReminderProvider billProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                'Upcoming',
                billProvider.upcomingBills.length.toString(),
                '₹${billProvider.totalUpcomingAmount.toStringAsFixed(0)}',
                Colors.white,
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildStat(
                'Overdue',
                billProvider.overdueBills.length.toString(),
                '₹${billProvider.totalOverdueAmount.toStringAsFixed(0)}',
                Colors.red.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String count, String amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBillsList(List<BillReminderModel> bills, String type) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'paid' ? Icons.check_circle_outline : Icons.receipt_long,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'upcoming'
                  ? 'No upcoming bills'
                  : type == 'overdue'
                  ? 'No overdue bills'
                  : 'No paid bills this month',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return _buildBillCard(bill, type);
      },
    );
  }

  Widget _buildBillCard(BillReminderModel bill, String type) {
    final authProvider = context.read<AuthProvider>();
    final billProvider = context.read<BillReminderProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    final daysUntilDue = bill.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = type == 'overdue';
    final isPaid = type == 'paid';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditBillReminderScreen(bill: bill),
            ),
          );
          _loadData();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          (isOverdue
                                  ? Colors.red
                                  : isPaid
                                  ? Colors.green
                                  : AppTheme.primaryColor)
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt,
                      color: isOverdue
                          ? Colors.red
                          : isPaid
                          ? Colors.green
                          : AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.billName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(bill.dueDate),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            if (!isPaid) ...[
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  isOverdue
                                      ? '${-daysUntilDue} days overdue'
                                      : daysUntilDue == 0
                                      ? 'Due today!'
                                      : 'In $daysUntilDue ${daysUntilDue == 1 ? 'day' : 'days'}',
                                  style: TextStyle(
                                    color: isOverdue
                                        ? Colors.red
                                        : daysUntilDue <= 3
                                        ? Colors.orange
                                        : Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${bill.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isOverdue
                              ? Colors.red
                              : isPaid
                              ? Colors.green
                              : AppTheme.primaryColor,
                        ),
                      ),
                      if (bill.recurrenceType != RecurrenceType.none)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getRecurrenceLabel(bill.recurrenceType),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (bill.notes != null && bill.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  bill.notes!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
              if (!isPaid) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isOverdue)
                      TextButton.icon(
                        icon: const Icon(Icons.snooze, size: 16),
                        label: const Text(
                          'Snooze 7d',
                          style: TextStyle(fontSize: 13),
                        ),
                        onPressed: () async {
                          await billProvider.snoozeBill(bill, 7);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bill snoozed for 7 days'),
                              ),
                            );
                          }
                        },
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text(
                        'Mark As Paid',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        await billProvider.markBillAsPaid(
                          bill,
                          expenseProvider,
                          authProvider.currentUser!.id,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                bill.autoCreateExpense
                                    ? 'Bill marked as paid & expense added!'
                                    : 'Bill marked as paid!',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getRecurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.quarterly:
        return 'Quarterly';
      case RecurrenceType.yearly:
        return 'Yearly';
      case RecurrenceType.custom:
        return 'Custom';
      default:
        return '';
    }
  }
}
