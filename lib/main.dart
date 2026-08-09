import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/task_screens.dart';
import 'screens/notes_screen.dart';
import 'screens/reminder_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/goal_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/events_screen.dart';
import 'screens/files_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/habit_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/calendar_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const LifeOSAI(),
    ),
  );
}

class LifeOSAI extends StatelessWidget {
  const LifeOSAI({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LifeOS AI',

          theme: ThemeData.light(),

          darkTheme: ThemeData.dark(),

          themeMode: themeProvider.themeMode,

          home: const SplashScreen(),

          routes: {
            '/home': (context) => const HomeScreen(),
            '/tasks': (context) => const TaskScreen(),
            '/notes': (context) => const NotesScreen(),
            '/reminders': (context) => const ReminderScreen(),
            '/expenses': (context) => const ExpenseScreen(),
            '/goals': (context) => const GoalScreen(),
            '/ai': (context) => const AiScreen(),
            '/events': (context) => const EventsScreen(),
            '/files': (context) => const FilesScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/habits': (context) => const HabitScreen(),
            '/notifications': (context) => const NotificationScreen(),
            '/analytics': (context) => const AnalyticsScreen(),
            '/search': (context) => const SearchScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/documents': (context) => const DocumentsScreen(),
            '/calendar': (context) => const CalendarScreen(),
          },
        );
      },
    );
  }
}
