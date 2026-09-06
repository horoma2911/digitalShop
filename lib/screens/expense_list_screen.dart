import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_colors.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  final List<String> _categories = const ['Transport', 'Food', 'Electricity', 'Rent', 'Others'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expenseProv = context.watch<ExpenseProvider>();
    final expenses = expenseProv.expenses;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: expenses.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text(l10n.noExpensesRecorded, style: TextStyle(color: Colors.grey.shade500)),
              ],
            ))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final expense = expenses[expenses.length - 1 - index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.outbox, color: Colors.red),
                    ),
                    title: Text(expense.category, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expense.description),
                        Text(DateFormat('MMM dd, yyyy').format(expense.date), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('TZS ${CurrencyFormatter.format(expense.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'edit') _showExpenseForm(context, expense: expense);
                            if (val == 'delete') _showDeleteConfirmation(context, expense);
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                            PopupMenuItem(value: 'delete', child: Text(l10n.delete, style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseForm(context),
        backgroundColor: Colors.red.shade800,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l10n.addExpense, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Expense expense) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.delete}?'),
        content: const Text('Are you sure you want to delete this expense record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              context.read<ExpenseProvider>().deleteExpense(expense.id);
              Navigator.pop(context);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showExpenseForm(BuildContext context, {Expense? expense}) {
    final l10n = AppLocalizations.of(context)!;
    final amountCtrl = TextEditingController(text: expense?.amount.toString());
    final descCtrl = TextEditingController(text: expense?.description);
    String category = expense?.category ?? _categories[0];
    DateTime selectedDate = expense?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(expense == null ? l10n.addExpense : l10n.edit),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 10),
                TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (TZS)'), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 10),
                ListTile(
                  title: Text(l10n.day),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setDialogState(() => selectedDate = date);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: const TextStyle(color: Colors.red))),
            ElevatedButton(
              onPressed: () async {
                final prov = context.read<ExpenseProvider>();
                try {
                  if (expense == null) {
                    await prov.addExpense(
                      category: category,
                      description: descCtrl.text,
                      amount: double.parse(amountCtrl.text),
                      date: selectedDate,
                    );
                  } else {
                    await prov.updateExpense(Expense(
                      id: expense.id,
                      shopId: expense.shopId,
                      category: category,
                      description: descCtrl.text,
                      amount: double.parse(amountCtrl.text),
                      date: selectedDate,
                    ));
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text(expense == null ? l10n.save : l10n.update),
            ),
          ],
        ),
      ),
    );
  }
}
