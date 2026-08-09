import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<dynamic> events = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    setState(() {
      loading = true;
    });

    final data = await ApiService.getEvents();

    if (!mounted) return;

    setState(() {
      events = data;
      loading = false;
    });
  }

  Future<void> showAddEventDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Event"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Event Title",
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 12),

                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(selectedDate.toString().split(" ")[0]),
                      onTap: () async {
                        final picked = await showDatePicker(
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

                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(selectedTime.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );

                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
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
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }

                    final date = selectedDate.toString().split(" ")[0];

                    final time =
                        "${selectedTime.hour.toString().padLeft(2, '0')}:"
                        "${selectedTime.minute.toString().padLeft(2, '0')}:00";

                    final success = await ApiService.addEvent(
                      titleController.text.trim(),
                      descriptionController.text.trim(),
                      date,
                      time,
                    );

                    if (!mounted) return;

                    Navigator.pop(context);

                    if (success) {
                      await loadEvents();

                      if (!mounted) return;

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text("Event Added Successfully"),
                        ),
                      );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Events"), centerTitle: true),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
          ? const Center(child: Text("No Events Found"))
          : RefreshIndicator(
              onRefresh: loadEvents,
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const Icon(
                        Icons.event,
                        color: Colors.deepPurple,
                      ),
                      title: Text(event["title"] ?? ""),
                      subtitle: Text(
                        "${event["event_date"]} • ${event["event_time"]}"
                        "\n${event["description"] ?? ""}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final success = await ApiService.deleteEvent(
                            event["id"],
                          );

                          if (!mounted) return;

                          if (success) {
                            await loadEvents();

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Event Deleted Successfully"),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: showAddEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
