import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const ExpenseHomePage(),
    );
  }
}

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  final List<Map<String, dynamic>> expenses = [];

  final TextEditingController titleController = TextEditingController();

  final TextEditingController amountController = TextEditingController();

  String selectedCategory = 'Food';
  String selectedFilter = 'All';

  final List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Education',
    'Other',
  ];

  // ---------------- STORAGE ----------------

  Future<void> saveExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('saved_expenses', jsonEncode(expenses));
    } catch (error) {
      debugPrint('Failed to save expenses: $error');
    }
  }

  Future<void> loadExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('saved_expenses');

      if (savedData == null) return;

      final decoded = jsonDecode(savedData) as List<dynamic>;

      final loadedExpenses = decoded.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();

      if (!mounted) return;

      setState(() {
        expenses
          ..clear()
          ..addAll(loadedExpenses);
      });
    } catch (error) {
      debugPrint('Failed to load expenses: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  // ---------------- CALCULATIONS ----------------

  double get totalExpenses {
    return expenses.fold<double>(
      0.0,
      (sum, expense) => sum + (expense['amount'] as num).toDouble(),
    );
  }

  Map<String, double> get categoryTotals {
    final totals = <String, double>{
      for (final category in categories) category: 0.0,
    };

    for (final expense in expenses) {
      final category = expense['category'] as String;
      final amount = (expense['amount'] as num).toDouble();

      totals[category] = (totals[category] ?? 0.0) + amount;
    }

    return totals;
  }

  List<Map<String, dynamic>> get filteredExpenses {
    if (selectedFilter == 'All') {
      return expenses;
    }

    return expenses.where((expense) {
      return expense['category'] == selectedFilter;
    }).toList();
  }

  // ---------------- ADD EXPENSE ----------------

  void addExpense(BuildContext dialogContext) {
    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text.trim());

    if (title.isEmpty || amount == null || !amount.isFinite || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid title and amount')),
      );
      return;
    }

    setState(() {
      expenses.add({
        'title': title,
        'amount': amount,
        'category': selectedCategory,
        'date': DateTime.now().toIso8601String(),
      });
    });

    saveExpenses();

    titleController.clear();
    amountController.clear();

    Navigator.pop(dialogContext);
  }

  void showAddExpenseDialog() {
    selectedCategory = 'Food';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    titleController.clear();
                    amountController.clear();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => addExpense(dialogContext),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- EDIT EXPENSE ----------------

  void editExpense(int index) {
    final expense = expenses[index];

    final editTitleController = TextEditingController(
      text: expense['title'] as String,
    );

    final editAmountController = TextEditingController(
      text: (expense['amount'] as num).toString(),
    );

    String editCategory = expense['category'] as String;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: editTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: editCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            editCategory = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final updatedTitle = editTitleController.text.trim();

                    final updatedAmount = double.tryParse(
                      editAmountController.text.trim(),
                    );

                    if (updatedTitle.isEmpty ||
                        updatedAmount == null ||
                        !updatedAmount.isFinite ||
                        updatedAmount <= 0) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a valid title and amount'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      expenses[index] = {
                        ...expense,
                        'title': updatedTitle,
                        'amount': updatedAmount,
                        'category': editCategory,
                      };
                    });

                    saveExpenses();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      editTitleController.dispose();
      editAmountController.dispose();
    });
  }

  // ---------------- DELETE EXPENSE ----------------

  void deleteExpense(int index) {
    setState(() {
      expenses.removeAt(index);
    });

    saveExpenses();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  // ---------------- USER INTERFACE ----------------

  @override
  Widget build(BuildContext context) {
    final totals = categoryTotals;
    final visibleExpenses = filteredExpenses;
    final total = totalExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),

      // A single scrollable dashboard prevents vertical overflow.
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // -------- TOTAL EXPENSES CARD --------

            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.indigo,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Expenses',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // -------- SPENDING CHART --------
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spending by Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    for (final category in categories) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(category),
                          Text(
                            '₹${(totals[category] ?? 0).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: total == 0
                            ? 0.0
                            : (totals[category] ?? 0.0) / total,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),

            // -------- RECENT EXPENSES HEADING --------
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Recent Expenses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // -------- CATEGORY FILTERS --------
            SizedBox(
              height: 55,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final category in ['All', ...categories])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selectedFilter == category,
                        onSelected: (_) {
                          setState(() {
                            selectedFilter = category;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // -------- EXPENSE LIST --------
            if (visibleExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    expenses.isEmpty
                        ? 'No expenses yet. Add your first expense!'
                        : 'No expenses in this category.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              for (final expense in visibleExpenses)
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.currency_rupee),
                    ),
                    title: Text(expense['title'] as String),
                    subtitle: Text(expense['category'] as String),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${(expense['amount'] as num).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit expense',
                          onPressed: () {
                            final originalIndex = expenses.indexOf(expense);

                            editExpense(originalIndex);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete expense',
                          onPressed: () {
                            final originalIndex = expenses.indexOf(expense);

                            deleteExpense(originalIndex);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}
