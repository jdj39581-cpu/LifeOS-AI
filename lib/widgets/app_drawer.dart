import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Widget menu(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text("LifeOS User"),
            accountEmail: Text("user@example.com"),
            currentAccountPicture: CircleAvatar(
              child: Icon(Icons.person, size: 40),
            ),
          ),

          menu(context, Icons.home, "Home", "/home"),
          menu(context, Icons.person, "Profile", "/profile"),
          menu(context, Icons.task, "Tasks", "/tasks"),
          menu(context, Icons.note, "Notes", "/notes"),
          menu(context, Icons.alarm, "Reminders", "/reminders"),
          menu(context, Icons.account_balance_wallet, "Expenses", "/expenses"),

          // NEW
          menu(context, Icons.local_fire_department, "Habits", "/habits"),

          menu(context, Icons.flag, "Goals", "/goals"),
          menu(context, Icons.smart_toy, "AI Assistant", "/ai"),
          menu(context, Icons.event, "Events", "/events"),
          menu(context, Icons.notifications, "Notifications", "/notifications"),
          menu(context, Icons.folder, "Files", "/files"),
          menu(context, Icons.analytics, "Analytics", "/analytics"),
          menu(context, Icons.settings, "Settings", "/settings"),
          menu(context, Icons.folder, "Documents", "/documents"),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
