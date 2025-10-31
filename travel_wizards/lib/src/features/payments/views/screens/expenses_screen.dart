import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/services/payment_split_service.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends StatefulWidget {
  final String tripId;
  final List<String> tripBuddies;

  const ExpensesScreen({
    super.key,
    required this.tripId,
    required this.tripBuddies,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  void _showAddExpenseDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    
    // Get available members (either from tripBuddies or default to current user)
    final availableMembers = widget.tripBuddies.isNotEmpty
        ? widget.tripBuddies
        : ['You'];
    final selectedMembers = <String>{...availableMembers};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g., Dinner at restaurant',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text(
                  'Split among:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (availableMembers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No collaborators added yet. Expense will be added to your account.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ...availableMembers.map(
                    (buddy) => CheckboxListTile(
                      title: Text(buddy),
                      value: selectedMembers.contains(buddy),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedMembers.add(buddy);
                          } else {
                            selectedMembers.remove(buddy);
                          }
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (descriptionController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                    ),
                  );
                  return;
                }

                // Use selected members if any, otherwise default to current user
                final membersToSplit = selectedMembers.isNotEmpty
                    ? selectedMembers.toList()
                    : availableMembers;

                await PaymentSplitService.instance.addExpense(
                  tripId: widget.tripId,
                  description: descriptionController.text,
                  amount: amount,
                  splitAmong: membersToSplit,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense added successfully'),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ModernPageScaffold(
      pageTitle: 'Trip Expenses',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: PaymentSplitService.instance.getExpenses(widget.tripId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final expenses = snapshot.data ?? [];

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first expense',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final balances = PaymentSplitService.instance.calculateBalances(
            expenses,
            widget.tripBuddies,
          );
          final settlements = PaymentSplitService.instance.suggestSettlements(
            balances,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalancesCard(balances, colorScheme),
                const SizedBox(height: 16),
                _buildSettlementsCard(settlements, colorScheme),
                const SizedBox(height: 16),
                _buildExpensesCard(expenses, colorScheme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalancesCard(
    Map<String, double> balances,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Balances',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            ...balances.entries.map((entry) {
              final isPositive = entry.value > 0;
              final color = isPositive ? Colors.green : Colors.red;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      _currencyFormat.format(entry.value.abs()),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementsCard(
    List<PaymentSettlement> settlements,
    ColorScheme colorScheme,
  ) {
    if (settlements.isEmpty) return const SizedBox.shrink();

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Suggested Settlements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...settlements.map(
              (settlement) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${settlement.from} → ${settlement.to}',
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    Text(
                      _currencyFormat.format(settlement.amount),
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesCard(List<Expense> expenses, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'All Expenses',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            ...expenses.map(
              (expense) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(expense.description[0].toUpperCase()),
                ),
                title: Text(expense.description),
                subtitle: Text(
                  'Paid by ${expense.paidBy} • Split among ${expense.splitAmong.length}',
                ),
                trailing: Text(
                  _currencyFormat.format(expense.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
