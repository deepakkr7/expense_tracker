import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/split_expense_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/friend_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../data/models/split_expense_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../core/theme/app_theme.dart';

class CreateSplitExpenseScreen extends StatefulWidget {
  const CreateSplitExpenseScreen({super.key});

  @override
  State<CreateSplitExpenseScreen> createState() =>
      _CreateSplitExpenseScreenState();
}

class _CreateSplitExpenseScreenState extends State<CreateSplitExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _splitMethod = 'equal'; // 'equal' or 'custom'
  final Set<String> _selectedFriendIds = {};
  String? _selectedGroupId;
  final Map<String, TextEditingController> _customAmountControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      context.read<FriendProvider>().loadFriends(authProvider.currentUser!.id);
      context.read<GroupProvider>().loadGroups(authProvider.currentUser!.id);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    for (var controller in _customAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onGroupSelected(String? groupId) {
    if (groupId == null) return;

    final groupProvider = context.read<GroupProvider>();
    final group = groupProvider.getGroupById(groupId);

    if (group != null) {
      setState(() {
        _selectedGroupId = groupId;
        _selectedFriendIds.clear();
        _selectedFriendIds.addAll(group.memberIds);
      });
    }
  }

  double _calculateUserShare() {
    // Calculate user's share based on total amount minus friends' amounts
    if (_splitMethod != 'custom' || _amountController.text.isEmpty) {
      return 0.0;
    }

    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    double friendsTotal = 0.0;

    for (var friendId in _selectedFriendIds) {
      final controller = _customAmountControllers[friendId];
      final amount = double.tryParse(controller?.text ?? '0') ?? 0.0;
      friendsTotal += amount;
    }

    return (totalAmount - friendsTotal).clamp(0.0, totalAmount);
  }

  Future<void> _saveSplitExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one friend')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final splitProvider = context.read<SplitExpenseProvider>();

      final totalAmount = double.parse(_amountController.text);
      final splits = <String, double>{};
      final settled = <String, bool>{};

      if (_splitMethod == 'equal') {
        final amountPerPerson = totalAmount / (_selectedFriendIds.length + 1);
        for (var friendId in _selectedFriendIds) {
          splits[friendId] = amountPerPerson;
          settled[friendId] = false;
        }
      } else {
        // Custom split
        double friendsTotal = 0;
        for (var friendId in _selectedFriendIds) {
          final controller = _customAmountControllers[friendId];
          final amount = double.tryParse(controller?.text ?? '0') ?? 0;
          splits[friendId] = amount;
          settled[friendId] = false;
          friendsTotal += amount;
        }

        // Check if friends' total exceeds the total amount
        if (friendsTotal > totalAmount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Friends\' total (₹${friendsTotal.toStringAsFixed(0)}) exceeds total amount (₹${totalAmount.toStringAsFixed(0)})',
              ),
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        // User's share is the remaining amount
        final userShare = totalAmount - friendsTotal;

        // Validate that there's a valid split (user share should be >= 0)
        if (userShare < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid split amounts')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final splitExpense = SplitExpenseModel(
        id: const Uuid().v4(),
        expenseId: const Uuid().v4(),
        creatorId: authProvider.currentUser!.id,
        totalAmount: totalAmount,
        category: 'General',
        description: _descriptionController.text.trim(),
        date: DateTime.now(),
        splits: splits,
        settled: settled,
      );

      await splitProvider.addSplitExpense(splitExpense);

      // Calculate user's share
      double userShare;
      if (_splitMethod == 'equal') {
        userShare = totalAmount / (_selectedFriendIds.length + 1);
      } else {
        // Custom split - user's share is remaining amount
        double friendsTotal = splits.values.fold(
          0.0,
          (sum, amount) => sum + amount,
        );
        userShare = totalAmount - friendsTotal;
      }

      // Create a regular expense for user's share
      if (userShare > 0) {
        final expenseProvider = context.read<ExpenseProvider>();
        final userExpense = ExpenseModel(
          id: const Uuid().v4(),
          userId: authProvider.currentUser!.id,
          amount: userShare,
          category: 'General',
          description: '${_descriptionController.text.trim()} (Your share)',
          date: DateTime.now(),
          isSplit: false,
        );

        await expenseProvider.addExpense(userExpense);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Split expense created! Your share (₹${userShare.toStringAsFixed(0)}) added to expenses.',
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
    final friendProvider = context.watch<FriendProvider>();
    final groupProvider = context.watch<GroupProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Split Expense')),
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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  labelText: 'Total Amount',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                    fontSize: 24,
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
              const SizedBox(height: 20),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Dinner, Movie, etc.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Group Selection
              if (groupProvider.groups.isNotEmpty) ...[
                const Text(
                  'Quick Select Group',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: groupProvider.groups.map((group) {
                    final isSelected = _selectedGroupId == group.id;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(group.emoji ?? '👥'),
                          const SizedBox(width: 6),
                          Text(group.name),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        _onGroupSelected(selected ? group.id : null);
                      },
                      selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Friend Selection
              const Text(
                'Split With',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (friendProvider.friends.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No friends available. Add friends first from Friends & Groups screen.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...friendProvider.friends.map((friend) {
                  final isSelected = _selectedFriendIds.contains(friend.id);
                  return CheckboxListTile(
                    title: Text(friend.name),
                    subtitle: friend.email.isNotEmpty
                        ? Text(friend.email)
                        : null,
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedFriendIds.add(friend.id);
                          if (_splitMethod == 'custom') {
                            _customAmountControllers[friend.id] =
                                TextEditingController();
                          }
                        } else {
                          _selectedFriendIds.remove(friend.id);
                          _customAmountControllers[friend.id]?.dispose();
                          _customAmountControllers.remove(friend.id);
                        }
                      });
                    },
                  );
                }),

              const SizedBox(height: 24),

              // Split Method
              const Text(
                'Split Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'equal',
                    label: Text('Equal'),
                    icon: Icon(Icons.pie_chart),
                  ),
                  ButtonSegment(
                    value: 'custom',
                    label: Text('Custom'),
                    icon: Icon(Icons.edit),
                  ),
                ],
                selected: {_splitMethod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _splitMethod = newSelection.first;
                    if (_splitMethod == 'custom') {
                      for (var friendId in _selectedFriendIds) {
                        _customAmountControllers[friendId] ??=
                            TextEditingController();
                      }
                    }
                  });
                },
              ),

              // Custom amounts
              if (_splitMethod == 'custom' &&
                  _selectedFriendIds.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Enter amounts for each friend:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                ...friendProvider.friends
                    .where((f) => _selectedFriendIds.contains(f.id))
                    .map((friend) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _customAmountControllers[friend.id],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: friend.name,
                            prefixText: '₹ ',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter amount';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            // Schedule rebuild after current frame to update user's share
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {});
                              }
                            });
                          },
                        ),
                      );
                    }),
                const SizedBox(height: 16),
                // Show user's calculated share
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Your share:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${_calculateUserShare().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSplitExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Split Expense',
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
