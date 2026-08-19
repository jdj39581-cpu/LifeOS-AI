import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/lifeos_card.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  List expenses = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    setState(() => loading = true);
    expenses = await ApiService.getExpenses();
    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> showAddExpenseDialog() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();

    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add Expense"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Expense Title",
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: "Category",
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(selectedDate.toString().split(" ")[0]),
                trailing: const Icon(Icons.edit_calendar),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) selectedDate = picked;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  amountController.text.isEmpty ||
                  categoryController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all fields")),
                );
                return;
              }

              bool success = await ApiService.addExpense(
                titleController.text,
                double.tryParse(amountController.text) ?? 0,
                categoryController.text,
                selectedDate.toString().split(" ")[0],
              );

              Navigator.pop(context);

              if (success) {
                await loadExpenses();
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Expense Added Successfully")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  double get totalExpense {
    double total = 0;
    for (var expense in expenses) {
      total += double.parse(expense["amount"].toString());
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Expenses"),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: LifeOSCard(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x2206B6D4),
                  child: Icon(Icons.account_balance_wallet, color: Colors.cyan),
                ),
                title: const Text(
                  "Total Expenses",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "₹${totalExpense.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.cyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : expenses.isEmpty
                ? const Center(child: Text("No Expenses Found"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LifeOSCard(
                          child: ListTile(
                            isThreeLine: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0x2206B6D4),
                              child: Icon(
                                Icons.currency_rupee,
                                color: Colors.cyan,
                              ),
                            ),
                            title: Text(expense["title"]),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text("Category: ${expense["category"]}"),
                                Text("Date: ${expense["expense_date"]}"),
                              ],
                            ),
                            trailing: SizedBox(
                              width: 70,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "₹${expense["amount"]}",
                                    style: const TextStyle(
                                      color: Colors.cyan,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      bool success =
                                          await ApiService.deleteExpense(
                                            expense["id"],
                                          );
                                      if (success) {
                                        await loadExpenses();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)],
          ),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: showAddExpenseDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
