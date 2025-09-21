import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _spentController = TextEditingController();
  double _budget = 0;
  double _spent = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _spentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _budget = (prefs.getDouble('monthly_budget') ?? 0);
      _spent = (prefs.getDouble('monthly_spent') ?? 0);
      _budgetController.text = _budget == 0 ? '' : _budget.toStringAsFixed(0);
      _spentController.text = _spent == 0 ? '' : _spent.toStringAsFixed(0);
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', _budget);
    await prefs.setDouble('monthly_spent', _spent);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Budget saved')));
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_budget - _spent).clamp(-1000000, 100000000);
    final percent = _budget > 0 ? (_spent / _budget).clamp(0, 1) : 0.0;
    return ListView(
      padding: Insets.allMd,
      children: [
        Text(
          'Monthly Travel Budget',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Gaps.h8,
        TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Budget (₹)',
            hintText: 'e.g., 20000',
          ),
          onChanged: (v) {
            final d = double.tryParse(v) ?? 0;
            setState(() => _budget = d);
          },
        ),
        Gaps.h8,
        TextField(
          controller: _spentController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Spent so far (₹)',
            hintText: 'e.g., 5000',
          ),
          onChanged: (v) {
            final d = double.tryParse(v) ?? 0;
            setState(() => _spent = d);
          },
        ),
        Gaps.h16,
        LinearProgressIndicator(value: percent.toDouble()),
        Gaps.h8,
        Text('Remaining: ₹${remaining.toStringAsFixed(0)}'),
        Gaps.h16,
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
