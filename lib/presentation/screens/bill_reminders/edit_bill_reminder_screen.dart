import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/bill_reminder_provider.dart';
import '../../../data/models/bill_reminder_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class EditBillReminderScreen extends StatefulWidget {
  final BillReminderModel bill;

  const EditBillReminderScreen({super.key, required this.bill});

  @override
  State<EditBillReminderScreen> createState() => _EditBillReminderScreenState();
}

class _EditBillReminderScreenState extends State<EditBillReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _billNameController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late String _selectedCategory;
  late DateTime _dueDate;
  late RecurrenceType _recurrenceType;
  late int _reminderDaysBefore;
  int? _customIntervalDays;
  late bool _autoCreateExpense;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _billNameController = TextEditingController(text: widget.bill.billName);
    _amountController = TextEditingController(
      text: widget.bill.amount.toStringAsFixed(0),
    );
    _notesController = TextEditingController(text: widget.bill.notes ?? '');
    _selectedCategory = widget.bill.category;
    _dueDate = widget.bill.dueDate;
    _recurrenceType = widget.bill.recurrenceType;
    _reminderDaysBefore = widget.bill.reminderDaysBefore;
    _customIntervalDays = widget.bill.customIntervalDays;
    _autoCreateExpense = widget.bill.autoCreateExpense;
  }

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

  Future<void> _updateBillReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final billProvider = context.read<BillReminderProvider>();

      final updatedBill = widget.bill.copyWith(
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

      await billProvider.updateBillReminder(updatedBill);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill reminder updated successfully!'),
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
      appBar: AppBar(title: const Text('Edit Bill Reminder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _billNameController,
                decoration: const InputDecoration(
                  labelText: 'Bill Name',
                  prefixIcon: Icon(Icons.receipt),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter bill name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
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
                  DropdownMenuItem(
                    value: RecurrenceType.monthly,
                    child: Text('Monthly'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceType.quarterly,
                    child: Text('Quarterly'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceType.yearly,
                    child: Text('Yearly'),
                  ),
                  DropdownMenuItem(
                    value: RecurrenceType.custom,
                    child: Text('Custom Interval'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _recurrenceType = value!);
                },
              ),
              if (_recurrenceType == RecurrenceType.custom) ...[
                const SizedBox(height: 16),
                TextFormField(
                  keyboardType: TextInputType.number,
                  initialValue: _customIntervalDays?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Repeat every (days)',
                    prefixIcon: Icon(Icons.event_repeat),
                  ),
                  onChanged: (value) {
                    _customIntervalDays = int.tryParse(value);
                  },
                ),
              ],
              const SizedBox(height: 24),
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
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Auto-add to expenses when paid'),
                value: _autoCreateExpense,
                onChanged: (value) {
                  setState(() => _autoCreateExpense = value);
                },
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateBillReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Bill Reminder',
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
