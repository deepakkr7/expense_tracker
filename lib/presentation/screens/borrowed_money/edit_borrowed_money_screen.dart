import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/borrowed_money_provider.dart';
import '../../../data/models/borrowed_money_model.dart';
import '../../../core/theme/app_theme.dart';

class EditBorrowedMoneyScreen extends StatefulWidget {
  final BorrowedMoneyModel transaction;

  const EditBorrowedMoneyScreen({super.key, required this.transaction});

  @override
  State<EditBorrowedMoneyScreen> createState() =>
      _EditBorrowedMoneyScreenState();
}

class _EditBorrowedMoneyScreenState extends State<EditBorrowedMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _personNameController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late bool _isPaid;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _personNameController = TextEditingController(
      text: widget.transaction.personName,
    );
    _amountController = TextEditingController(
      text: widget.transaction.amount.toStringAsFixed(0),
    );
    _descriptionController = TextEditingController(
      text: widget.transaction.description ?? '',
    );
    _selectedDate = widget.transaction.date;
    _isPaid = widget.transaction.isPaid;
  }

  @override
  void dispose() {
    _personNameController.dispose();
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

  Future<void> _updateBorrowedMoney() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final borrowedMoneyProvider = context.read<BorrowedMoneyProvider>();

      final updated = widget.transaction.copyWith(
        personName: _personNameController.text.trim(),
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isPaid: _isPaid,
        paidDate: _isPaid && widget.transaction.paidDate == null
            ? DateTime.now()
            : widget.transaction.paidDate,
      );

      await borrowedMoneyProvider.updateBorrowedMoney(
        updated,
        previousState: widget.transaction,
      );

      if (mounted) {
        Navigator.pop(context);

        // Show appropriate message based on whether it was marked as paid
        final wasMarkedAsPaid = !widget.transaction.isPaid && _isPaid;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasMarkedAsPaid
                  ? 'Transaction updated and added to expenses!'
                  : 'Transaction updated successfully!',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Borrowed Money')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Person Name
              TextFormField(
                controller: _personNameController,
                decoration: const InputDecoration(
                  labelText: 'Person Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter person name';
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

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Date Picker
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Paid Status
              SwitchListTile(
                title: const Text('Mark as Paid'),
                subtitle: Text(
                  _isPaid
                      ? 'This transaction is paid'
                      : 'This transaction is unpaid',
                ),
                value: _isPaid,
                onChanged: (value) {
                  setState(() => _isPaid = value);
                },
                activeColor: AppTheme.successColor,
              ),
              const SizedBox(height: 40),

              // Update Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateBorrowedMoney,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
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
