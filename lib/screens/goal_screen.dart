import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  List goals = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  Future<void> loadGoals() async {
    setState(() {
      loading = true;
    });

    goals = await ApiService.getGoals();

    setState(() {
      loading = false;
    });
  }

  Future<void> showAddGoalDialog() async {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add Goal"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Goal Title"),
                ),

                const SizedBox(height: 15),

                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(selectedDate.toString().split(" ")[0]),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2035),
                    );

                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),

              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;

                  bool success = await ApiService.addGoal(
                    titleController.text,
                    selectedDate.toString().split(" ")[0],
                  );

                  Navigator.pop(context);

                  if (success) {
                    await loadGoals();

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Goal Added Successfully")),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Goals"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : goals.isEmpty
          ? const Center(child: Text("No Goals Found"))
          : ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: Icon(
                      goals[index]["status"] == "Completed"
                          ? Icons.check_circle
                          : Icons.flag,
                      color: goals[index]["status"] == "Completed"
                          ? Colors.green
                          : Colors.orange,
                    ),
                    title: Text(goals[index]["title"]),
                    subtitle: Text("Target: ${goals[index]["target_date"]}"),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == "complete") {
                          bool success = await ApiService.completeGoal(
                            goals[index]["id"],
                          );

                          if (success) {
                            await loadGoals();
                          }
                        }

                        if (value == "delete") {
                          bool success = await ApiService.deleteGoal(
                            goals[index]["id"],
                          );

                          if (success) {
                            await loadGoals();
                          }
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "complete",
                          child: Text("Complete"),
                        ),
                        PopupMenuItem(value: "delete", child: Text("Delete")),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddGoalDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
