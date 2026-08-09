import 'package:flutter/material.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Map<String, dynamic>> goals = [
    {"goal": "Complete LifeOS AI Project", "progress": 0.70},
    {"goal": "Learn Flutter", "progress": 0.50},
    {"goal": "Get BCA Degree", "progress": 0.90},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Goals"), centerTitle: true),
      body: ListView.builder(
        itemCount: goals.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goals[index]["goal"],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: goals[index]["progress"]),
                  const SizedBox(height: 5),
                  Text(
                    "${(goals[index]["progress"] * 100).toInt()}% Completed",
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Add Goal feature coming next")),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
