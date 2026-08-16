import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../services/api_service.dart';
import '../services/backup_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> profile = {};
  bool loading = true;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

  Future<void> loadProfile() async {
    profile = await ApiService.getProfile();

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> backupData() async {
    await BackupService.createBackup(
      tasks: [],
      notes: [],
      reminders: [],
      expenses: [],
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Backup Created Successfully")),
    );
  }

  Future<void> restoreData() async {
    final backup = await BackupService.getBackup();

    if (!mounted) return;

    if (backup == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No Backup Found")));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Backup Restored (${backup["time"]})")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      drawer: const AppDrawer(),
      appBar: AppBar(backgroundColor: const Color(0xFF0F172A), elevation: 0, title: const Text("Profile"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 60),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    profile["name"] ?? "",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    profile["email"] ?? "",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 30),

                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.dark_mode),
                    title: const Text("Dark Mode"),
                    value: isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        isDarkMode = value;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.backup, color: Colors.blue),
                    title: const Text("Create Backup"),
                    onTap: backupData,
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.restore, color: Colors.green),
                    title: const Text("Restore Backup"),
                    onTap: restoreData,
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text("Logout"),
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
