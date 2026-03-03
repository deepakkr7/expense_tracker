import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/expense_provider.dart';
import '../../widgets/expense_card.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final allExpenses = expenseProvider.allExpenses;

    // Apply filters
    var filteredExpenses = allExpenses.where((expense) {
      if (_searchQuery.isNotEmpty) {
        if (!expense.category.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) &&
            !expense.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            )) {
          return false;
        }
      }
      return true;
    }).toList();

    // Sort by date descending
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: filteredExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ExpenseCard(expense: expense),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
