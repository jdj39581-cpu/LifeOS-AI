import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
    setState(() {
      loading = true;
    });

    expenses = await ApiService.getExpenses();

    setState(() {
      loading = false;
    });
  }

  Future<void> showAddExpenseDialog() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();

    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

              const SizedBox(height: 10),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: "Category",
                  prefixIcon: Icon(Icons.category),
                ),
              ),

              const SizedBox(height: 10),

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

                  if (picked != null) {
                    selectedDate = picked;
                  }
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
      appBar: AppBar(title: const Text("Expenses"), centerTitle: true),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(15),
            child: ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Colors.green,
              ),
              title: const Text(
                "Total Expenses",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("₹$totalExpense"),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : expenses.isEmpty
                ? const Center(child: Text("No Expenses Found"))
                : ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.green,
                          ),
                          title: Text(expenses[index]["title"]),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Category: ${expenses[index]["category"]}"),
                              Text("Date: ${expenses[index]["expense_date"]}"),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              bool success = await ApiService.deleteExpense(
                                expenses[index]["id"],
                              );

                              if (success) {
                                await loadExpenses();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddExpenseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
