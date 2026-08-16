import 'package:flutter/material.dart';

import '../screens/ai_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/task_screens.dart';
import '../screens/expense_screen.dart';
import '../screens/profile_screen.dart';

class CommandPalette {
  static void open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CommandPaletteView(),
    );
  }
}

class _CommandPaletteView extends StatefulWidget {
  const _CommandPaletteView();

  @override
  State<_CommandPaletteView> createState() => _CommandPaletteViewState();
}

class _CommandPaletteViewState extends State<_CommandPaletteView> {
  final TextEditingController controller = TextEditingController();

  final List<Map<String, dynamic>> commands = [
    {"title": "Open AI", "keyword": "ai", "page": const AIScreen()},
    {"title": "Open Tasks", "keyword": "task", "page": const TaskScreen()},
    {"title": "Open Notes", "keyword": "note", "page": const NotesScreen()},
    {
      "title": "Open Calendar",
      "keyword": "calendar",
      "page": const CalendarScreen(),
    },
    {
      "title": "Open Expense",
      "keyword": "expense",
      "page": const ExpenseScreen(),
    },
    {
      "title": "Open Profile",
      "keyword": "profile",
      "page": const ProfileScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final query = controller.text.toLowerCase();

    final filtered = commands.where((item) {
      return item["title"].toLowerCase().contains(query) ||
          item["keyword"].toLowerCase().contains(query);
    }).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                hintText: "Type a command...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, index) {
                  final item = filtered[index];

                  return ListTile(
                    leading: const Icon(
                      Icons.flash_on,
                      color: Colors.cyanAccent,
                    ),
                    title: Text(
                      item["title"],
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => item["page"]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
