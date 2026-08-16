import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/task_screens.dart';
import 'screens/notes_screen.dart';
import 'screens/reminder_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/habit_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/events_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/search_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  runApp(const LifeOSAI()); // ✅ Fixed
}

class LifeOSAI extends StatelessWidget {
  const LifeOSAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifeOS AI',
      home: const SplashScreen(),
      routes: {
        "/dashboard": (context) => const DashboardScreen(),
        "/tasks": (context) => const TaskScreen(),
        "/notes": (context) => const NotesScreen(),
        "/reminders": (context) => const ReminderScreen(),
        "/expenses": (context) => const ExpenseScreen(),
        "/goals": (context) => const GoalsScreen(),
        "/habits": (context) => const HabitScreen(),
        "/notifications": (context) => const NotificationScreen(),
        "/analytics": (context) => const AnalyticsScreen(),
        "/ai": (context) => const AIScreen(),
        "/events": (context) => const EventsScreen(),
        "/documents": (context) => const DocumentsScreen(),
        "/profile": (context) => const ProfileScreen(),
        "/calendar": (context) => const CalendarScreen(),
        "/search": (context) => const SearchScreen(),
      },
    );
  }
}
