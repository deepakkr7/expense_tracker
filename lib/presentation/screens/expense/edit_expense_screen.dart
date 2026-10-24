import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../data/models/expense_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/zero_budget_warning_dialog.dart';

class EditExpenseScreen extends StatefulWidget {
  final ExpenseModel expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing expense data
    _amountController = TextEditingController(
      text: widget.expense.amount.toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(
      text: widget.expense.description,
    );
    _selectedCategory = widget.expense.category;
    _selectedDate = widget.expense.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text);
    final budgetProvider = context.read<BudgetProvider>();

    // Check if the new/edited category has zero budget and category changed
    // or amount increased
    final categoryChanged = _selectedCategory != widget.expense.category;
    final amountIncreased = amount > widget.expense.amount;

    if (!widget.expense.isIncome &&
        budgetProvider.isZeroBudgetCategory(_selectedCategory) &&
        (categoryChanged || amountIncreased)) {
      // Show warning dialog
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => ZeroBudgetWarningDialog(
          category: _selectedCategory,
          amount: amount,
          onIgnoreAndContinue: () {},
        ),
      );

      // If user cancelled, don't update the expense
      if (shouldContinue != true) {
        return;
      }
    }

    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final expenseProvider = context.read<ExpenseProvider>();

      final updatedExpense = widget.expense.copyWith(
        amount: amount,
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate,
      );

      final authProvider = context.read<AuthProvider>();

      await expenseProvider.updateExpense(updatedExpense);
      if (widget.expense.isIncome) await authProvider.refreshUser();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.expense.isIncome ? 'Income' : 'Expense'} updated successfully!',
            ),
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

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Transaction',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);

      try {
        final authProvider = context.read<AuthProvider>();
        final expenseProvider = context.read<ExpenseProvider>();

        await expenseProvider.deleteExpense(
          authProvider.currentUser!.id,
          widget.expense.id,
        );
        if (widget.expense.isIncome) await authProvider.refreshUser();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction deleted'),
              backgroundColor: AppTheme.errorColor,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Transaction'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: AppTheme.errorColor),
            onPressed: _isLoading ? null : _deleteExpense,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                validator: Validators.validateAmount,
              ),
              SizedBox(height: 24),

              // Category Dropdown (hide for income)
              if (!widget.expense.isIncome) ...[
                DropdownButtonFormField<String>(
                  value:
                      AppConstants.expenseCategories.contains(_selectedCategory)
                      ? _selectedCategory
                      : widget.expense.isIncome
                      ? 'Income'
                      : AppConstants.expenseCategories.first,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items:
                      (widget.expense.isIncome
                              ? [
                                  'Income',
                                  'Salary',
                                  'Business',
                                  'Interest',
                                  'Gift',
                                  'Other income',
                                ]
                              : AppConstants.expenseCategories)
                          .map((category) {
                            final icon =
                                AppConstants.categoryIcons[category] ??
                                Icons.help;
                            final color =
                                AppConstants.categoryColors[category] ??
                                Colors.grey;

                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(icon, color: color, size: 20),
                                  SizedBox(width: 12),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                ),
                SizedBox(height: 24),
              ],

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                validator: (value) =>
                    Validators.validateRequired(value, 'Description'),
              ),
              SizedBox(height: 24),

              // Date Picker
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40),

              // Update Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Update Transaction',
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
