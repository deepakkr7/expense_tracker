import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bill_reminder_provider.dart';
import '../../../data/models/bill_reminder_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class AddBillReminderScreen extends StatefulWidget {
  const AddBillReminderScreen({super.key});

  @override
  State<AddBillReminderScreen> createState() => _AddBillReminderScreenState();
}

class _AddBillReminderScreenState extends State<AddBillReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = AppConstants.expenseCategories.first;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  RecurrenceType _recurrenceType = RecurrenceType.monthly;
  int _reminderDaysBefore = 3;
  int? _customIntervalDays;
  bool _autoCreateExpense = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _billNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveBillReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_recurrenceType == RecurrenceType.custom &&
        _customIntervalDays == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter custom interval days')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final billProvider = context.read<BillReminderProvider>();

      final bill = BillReminderModel(
        id: const Uuid().v4(),
        userId: authProvider.currentUser!.id,
        billName: _billNameController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        dueDate: _dueDate,
        recurrenceType: _recurrenceType,
        customIntervalDays: _customIntervalDays,
        reminderDaysBefore: _reminderDaysBefore,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        autoCreateExpense: _autoCreateExpense,
      );

      await billProvider.addBillReminder(bill);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill reminder added successfully!'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Bill Reminder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bill Name
              TextFormField(
                controller: _billNameController,
                decoration: const InputDecoration(
                  labelText: 'Bill Name',
                  prefixIcon: Icon(Icons.receipt),
                  hintText: 'e.g., Rent, Electricity',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter bill name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                dropdownColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.white,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 16,
                ),
                items: AppConstants.expenseCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          AppConstants.categoryIcons[category],
                          size: 20,
                          color: AppConstants.categoryColors[category],
                        ),
                        const SizedBox(width: 12),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              const SizedBox(height: 24),

              // Due Date
              InkWell(
                onTap: _selectDueDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(_dueDate)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recurrence Type
              DropdownButtonFormField<RecurrenceType>(
                value: _recurrenceType,
                decoration: const InputDecoration(
                  labelText: 'Recurrence',
                  prefixIcon: Icon(Icons.repeat),
                ),
                dropdownColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.white,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 16,
                ),
                items: const [
                  DropdownMenuItem(
                    value: RecurrenceType.none,
                    child: Text('One-time only'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceType.weekly,
                    child: Text('Weekly'),
                  ),
                  const DropdownMenuItem(
                    value: RecurrenceType.monthly,
                    child: Text('Monthly'),
                  ),
                  const DropdownMenuItem(
                    value: RecurrenceType.quarterly,
                    child: Text('Quarterly (Every 3 months)'),
                  ),
                  const DropdownMenuItem(
                    value: RecurrenceType.yearly,
                    child: Text('Yearly'),
                  ),
                  const DropdownMenuItem(
                    value: RecurrenceType.custom,
                    child: Text('Custom Interval'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _recurrenceType = value!);
                },
              ),

              // Custom Interval (if selected)
              if (_recurrenceType == RecurrenceType.custom) ...[
                const SizedBox(height: 16),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repeat every (days)',
                    prefixIcon: Icon(Icons.event_repeat),
                    hintText: 'e.g., 14 for bi-weekly',
                  ),
                  onChanged: (value) {
                    _customIntervalDays = int.tryParse(value);
                  },
                  validator: (value) {
                    if (_recurrenceType == RecurrenceType.custom) {
                      final days = int.tryParse(value ?? '');
                      if (days == null || days <= 0) {
                        return 'Enter valid number of days';
                      }
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),

              // Reminder Days Before
              DropdownButtonFormField<int>(
                value: _reminderDaysBefore,
                decoration: const InputDecoration(
                  labelText: 'Remind Me',
                  prefixIcon: Icon(Icons.notifications_active),
                ),
                dropdownColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.white,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 16,
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('On due date')),
                  DropdownMenuItem(value: 1, child: Text('1 day before')),
                  DropdownMenuItem(value: 3, child: Text('3 days before')),
                  DropdownMenuItem(value: 7, child: Text('1 week before')),
                  DropdownMenuItem(value: 14, child: Text('2 weeks before')),
                ],
                onChanged: (value) {
                  setState(() => _reminderDaysBefore = value!);
                },
              ),
              const SizedBox(height: 24),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'Additional details',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Auto Create Expense
              SwitchListTile(
                title: const Text('Auto-add to expenses when paid'),
                subtitle: const Text(
                  'Automatically create an expense when you mark this bill as paid',
                ),
                value: _autoCreateExpense,
                onChanged: (value) {
                  setState(() => _autoCreateExpense = value);
                },
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBillReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Add Bill Reminder',
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
        ),
      ),
    );
  }
}
