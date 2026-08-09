import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic> analytics = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    setState(() {
      loading = true;
    });

    analytics = await ApiService.getAnalytics();

    setState(() {
      loading = false;
    });
  }

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analytics"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  statCard(
                    "Total Tasks",
                    analytics["total_tasks"].toString(),
                    Icons.task,
                    Colors.blue,
                  ),

                  statCard(
                    "Completed Tasks",
                    analytics["completed_tasks"].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),

                  statCard(
                    "Pending Tasks",
                    analytics["pending_tasks"].toString(),
                    Icons.pending_actions,
                    Colors.orange,
                  ),

                  statCard(
                    "Total Goals",
                    analytics["total_goals"].toString(),
                    Icons.flag,
                    Colors.purple,
                  ),

                  statCard(
                    "Completed Goals",
                    analytics["completed_goals"].toString(),
                    Icons.emoji_events,
                    Colors.teal,
                  ),

                  statCard(
                    "Total Expenses",
                    "₹${analytics["total_expense"]}",
                    Icons.account_balance_wallet,
                    Colors.red,
                  ),
                ],
              ),
            ),
    );
  }
}
