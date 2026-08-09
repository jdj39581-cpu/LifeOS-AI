import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  List habits = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHabits();
  }

  Future<void> loadHabits() async {
    setState(() {
      loading = true;
    });

    habits = await ApiService.getHabits();

    setState(() {
      loading = false;
    });
  }

  Future<void> showAddHabitDialog() async {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Habit"),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: "Habit Title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;

              bool success = await ApiService.addHabit(titleController.text);

              Navigator.pop(context);

              if (success) {
                await loadHabits();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Habit Added Successfully")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Habits"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : habits.isEmpty
          ? const Center(child: Text("No Habits Found"))
          : ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: Icon(
                      habits[index]["completed_today"]
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: habits[index]["completed_today"]
                          ? Colors.green
                          : Colors.grey,
                    ),
                    title: Text(habits[index]["title"]),
                    subtitle: Text(
                      "🔥 Streak: ${habits[index]["streak"]} days",
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        bool success = false;

                        if (value == "complete") {
                          success = await ApiService.completeHabit(
                            habits[index]["id"],
                          );
                        } else if (value == "reset") {
                          success = await ApiService.resetHabit(
                            habits[index]["id"],
                          );
                        } else if (value == "delete") {
                          success = await ApiService.deleteHabit(
                            habits[index]["id"],
                          );
                        }

                        if (success) {
                          await loadHabits();

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value == "delete"
                                    ? "Habit Deleted"
                                    : value == "reset"
                                    ? "Habit Reset"
                                    : "Habit Completed",
                              ),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "complete",
                          child: Text("Complete"),
                        ),
                        PopupMenuItem(value: "reset", child: Text("Reset")),
                        PopupMenuItem(value: "delete", child: Text("Delete")),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddHabitDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
