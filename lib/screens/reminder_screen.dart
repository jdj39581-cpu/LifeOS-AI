import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List reminders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadReminders();
  }

  Future<void> loadReminders() async {
    setState(() {
      loading = true;
    });

    reminders = await ApiService.getReminders();

    setState(() {
      loading = false;
    });
  }

  Future<void> showAddReminderDialog() async {
    final titleController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Reminder"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Reminder Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: timeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Reminder Date & Time",
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2035),
                );

                if (pickedDate == null) return;

                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (pickedTime == null) return;

                DateTime reminder = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );

                timeController.text =
                    "${reminder.year}-${reminder.month.toString().padLeft(2, '0')}-${reminder.day.toString().padLeft(2, '0')} "
                    "${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}:00";
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
              if (titleController.text.trim().isEmpty ||
                  timeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter title and time")),
                );
                return;
              }

              bool success = await ApiService.addReminder(
                titleController.text.trim(),
                timeController.text,
              );

              if (success) {
                // Schedule local notification
                await NotificationService.scheduleNotification(
                  id: DateTime.now().millisecondsSinceEpoch % 100000,
                  title: titleController.text.trim(),
                  body: "Time to complete your reminder.",
                  dateTime: DateTime.parse(timeController.text),
                );

                Navigator.pop(context);
                await loadReminders();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reminder Added Successfully")),
                );
              } else {
                Navigator.pop(context);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to Add Reminder")),
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
      appBar: AppBar(title: const Text("Reminders"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : reminders.isEmpty
          ? const Center(child: Text("No Reminders Found"))
          : ListView.builder(
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.alarm)),
                    title: Text(reminders[index]["title"]),
                    subtitle: Text(reminders[index]["reminder_time"]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        bool success = await ApiService.deleteReminder(
                          reminders[index]["id"],
                        );

                        if (success) {
                          setState(() {
                            reminders.removeAt(index);
                          });

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Reminder Deleted Successfully"),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddReminderDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
