import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/friend_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/friend_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/zero_budget_warning_dialog.dart';
import 'receipt_scan_button.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSplitExpense = false;
  List<FriendModel> _selectedFriends = [];
  Map<String, dynamic>? _ocrData; // Store OCR data

  @override
  void initState() {
    super.initState();
    // Load friends list
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      context.read<FriendProvider>().loadFriends(authProvider.currentUser!.id);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleOCRData(Map<String, dynamic> ocrData) {
    setState(() {
      _ocrData = ocrData;

      // Auto-fill amount if available
      if (ocrData['amount'] != null) {
        _amountController.text = ocrData['amount'].toString();
      }

      // Auto-fill description with merchant name if available
      if (ocrData['merchant'] != null) {
        _descriptionController.text = ocrData['merchant'];
      }

      // Auto-set date if available
      if (ocrData['date'] != null && ocrData['date'] is String) {
        try {
          _selectedDate = DateTime.parse(ocrData['date']);
        } catch (e) {
          // Keep current date if parsing fails
        }
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt data extracted! Please review and save.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showSplitExpenseDialog() async {
    final friendProvider = context.read<FriendProvider>();
    final authProvider = context.read<AuthProvider>();

    // Try to load contacts
    List<dynamic> contacts = [];
    bool isImportingContacts = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Friends',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedFriends = List.from(_selectedFriends);
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),

                // Import button
                if (contacts.isEmpty && !isImportingContacts)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        setModalState(() => isImportingContacts = true);
                        try {
                          final loadedContacts = await friendProvider
                              .importContacts();
                          setModalState(() {
                            contacts = loadedContacts;
                            isImportingContacts = false;
                          });
                        } catch (e) {
                          setModalState(() => isImportingContacts = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.contact_phone),
                      label: const Text('Import from Contacts'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),

                const Divider(),

                // Contact/Friend list
                if (isImportingContacts)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (contacts.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Import contacts to split expenses',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        final contactName = contact.displayName;
                        final contactEmail = contact.emails.isNotEmpty
                            ? contact.emails.first.address
                            : '';

                        // Check if already selected
                        final isSelected = _selectedFriends.any(
                          (f) => f.name == contactName,
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? value) async {
                            if (value == true) {
                              // Add friend on-the-fly
                              final newFriend = await friendProvider
                                  .addFriendFromContact(
                                    authProvider.currentUser!.id,
                                    contact,
                                  );

                              setState(() {
                                _selectedFriends.add(newFriend);
                              });
                              setModalState(() {});
                            } else {
                              setState(() {
                                _selectedFriends.removeWhere(
                                  (f) => f.name == contactName,
                                );
                              });
                              setModalState(() {});
                            }
                          },
                          title: Text(contactName),
                          subtitle: contactEmail.isNotEmpty
                              ? Text(contactEmail)
                              : null,
                          secondary: CircleAvatar(
                            child: Text(contactName[0].toUpperCase()),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // If split is enabled but no friends selected
    if (_isSplitExpense && _selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select friends to split with')),
      );
      return;
    }

    // Check if category has zero budget
    final budgetProvider = context.read<BudgetProvider>();
    final amount = double.parse(_amountController.text);

    if (budgetProvider.isZeroBudgetCategory(_selectedCategory!)) {
      // Show warning dialog
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => ZeroBudgetWarningDialog(
          category: _selectedCategory!,
          amount: amount,
          onIgnoreAndContinue: () {},
        ),
      );

      // If user cancelled, don't save the expense
      if (shouldContinue != true) {
        return;
      }
    }

    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final expenseProvider = context.read<ExpenseProvider>();

      final expense = ExpenseModel(
        id: const Uuid().v4(),
        userId: authProvider.currentUser!.id,
        amount: amount,
        category: _selectedCategory!,
        description: _descriptionController.text,
        date: _selectedDate,
        isSplit: _isSplitExpense,
        splitDetails: _isSplitExpense && _selectedFriends.isNotEmpty
            ? {
                'friendIds': _selectedFriends.map((f) => f.friendId).toList(),
                'splitAmount': amount / (_selectedFriends.length + 1),
              }
            : null,
        ocrData: _ocrData, // Include OCR data if receipt was scanned
      );

      await expenseProvider.addExpense(expense);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Amount *',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                validator: Validators.validateAmount,
              ),
              const SizedBox(height: 20),

              // Category Dropdown - Fixed for dark mode
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category *'),
                dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black,
                ),
                items: AppConstants.expenseCategories.map((category) {
                  final icon =
                      AppConstants.categoryIcons[category] ??
                      Icons.help_outline;
                  final color =
                      AppConstants.categoryColors[category] ?? Colors.grey;

                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          category,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: Validators.validateCategory,
              ),
              const SizedBox(height: 20),

              // Description
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'What did you spend on?',
                ),
                validator: (value) =>
                    Validators.validateRequired(value, 'Description'),
              ),
              const SizedBox(height: 20),

              // Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Receipt Scan Button
              ReceiptScanButton(onDataExtracted: _handleOCRData),
              const SizedBox(height: 24),

              // Split Expense Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[850]
                      : AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSplitExpense
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Split Expense',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Share this expense with friends',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isSplitExpense,
                          onChanged: (value) {
                            setState(() {
                              _isSplitExpense = value;
                              if (!value) {
                                _selectedFriends.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (_isSplitExpense) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      if (_selectedFriends.isEmpty)
                        OutlinedButton.icon(
                          onPressed: _showSplitExpenseDialog,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Select Friends'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        )
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedFriends.length} friend(s) selected',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: _showSplitExpenseDialog,
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedFriends.map((friend) {
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundImage: friend.photoUrl != null
                                    ? NetworkImage(friend.photoUrl!)
                                    : null,
                                child: friend.photoUrl == null
                                    ? Text(friend.name[0].toUpperCase())
                                    : null,
                              ),
                              label: Text(friend.name),
                              onDeleted: () {
                                setState(() {
                                  _selectedFriends.removeWhere(
                                    (f) => f.id == friend.id,
                                  );
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text(
                    'Save Expense',
                    style: TextStyle(
                      fontSize: 18,
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
