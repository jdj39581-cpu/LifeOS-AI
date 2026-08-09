import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    tasks = await ApiService.getTasks();

    setState(() {
      loading = false;
    });
  }

  Future<void> showAddTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Task Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Task Description"),
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
              bool success = await ApiService.addTask(
                titleController.text,
                descriptionController.text,
              );

              Navigator.pop(context);

              if (success) {
                await loadTasks();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Task Added Successfully")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> deleteTask(int id) async {
    bool success = await ApiService.deleteTask(id);

    if (success) {
      await loadTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task Deleted Successfully")),
      );
    }
  }

  Future<void> showEditTaskDialog(Map task) async {
    final titleController = TextEditingController(text: task["title"]);
    final descriptionController = TextEditingController(
      text: task["description"],
    );

    String status = task["status"];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Task"),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: status,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: "Pending", child: Text("Pending")),
                    DropdownMenuItem(
                      value: "Completed",
                      child: Text("Completed"),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      status = value!;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              bool success = await ApiService.updateTask(
                task["id"],
                titleController.text,
                descriptionController.text,
                status,
              );

              Navigator.pop(context);

              if (success) {
                await loadTasks();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Task Updated Successfully")),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Tasks"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
          ? const Center(child: Text("No Tasks Found"))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    onTap: () {
                      showEditTaskDialog(tasks[index]);
                    },
                    leading: Icon(
                      Icons.task_alt,
                      color: tasks[index]["status"] == "Completed"
                          ? Colors.green
                          : Colors.orange,
                    ),
                    title: Text(tasks[index]["title"]),
                    subtitle: Text(tasks[index]["status"]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteTask(tasks[index]["id"]);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
