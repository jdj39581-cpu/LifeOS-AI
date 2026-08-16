import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool loading = true;

  int completedTasks = 0;
  int pendingTasks = 0;
  int totalNotes = 0;
  int totalReminders = 0;
  int totalEvents = 0;
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    setState(() => loading = true);

    try {
      final tasks = await ApiService.getTasks();
      final notes = await ApiService.getNotes();
      final reminders = await ApiService.getReminders();
      final expenses = await ApiService.getExpenses();
      final events = await ApiService.getEvents();

      completedTasks = tasks.where((t) => t["status"] == "Completed").length;
      pendingTasks = tasks.length - completedTasks;
      totalNotes = notes.length;
      totalReminders = reminders.length;
      totalEvents = events.length;

      totalExpense = 0;
      for (var e in expenses) {
        totalExpense += double.tryParse(e["amount"].toString()) ?? 0;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => loading = false);
  }

  Widget statCard(IconData icon, String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(backgroundColor: const Color(0xFF0F172A), elevation: 0, title: const Text("Analytics")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.3,
                    children: [
                      statCard(
                        Icons.check_circle,
                        "Completed",
                        "$completedTasks",
                        Colors.green,
                      ),
                      statCard(
                        Icons.pending_actions,
                        "Pending",
                        "$pendingTasks",
                        Colors.orange,
                      ),
                      statCard(Icons.note, "Notes", "$totalNotes", Colors.blue),
                      statCard(
                        Icons.alarm,
                        "Reminders",
                        "$totalReminders",
                        Colors.purple,
                      ),
                      statCard(
                        Icons.event,
                        "Events",
                        "$totalEvents",
                        Colors.teal,
                      ),
                      statCard(
                        Icons.account_balance_wallet,
                        "Expenses",
                        "₹${totalExpense.toInt()}",
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
