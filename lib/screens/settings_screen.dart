import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final profile = await ApiService.getSettingsProfile();

    nameController.text = profile["name"] ?? "";
    emailController.text = profile["email"] ?? "";

    setState(() {
      loading = false;
    });
  }

  Future<void> saveProfile() async {
    bool success = await ApiService.updateSettingsProfile(
      nameController.text,
      emailController.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Profile Updated Successfully" : "Failed to Update Profile",
        ),
      ),
    );
  }

  Future<void> changePasswordDialog() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Old Password"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              if (newController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Passwords do not match")),
                );
                return;
              }

              bool success = await ApiService.changePassword(
                oldController.text,
                newController.text,
              );

              if (!mounted) return;

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? "Password Changed Successfully"
                        : "Failed to Change Password",
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Name"),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: saveProfile,
            child: const Text("Save Profile"),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: changePasswordDialog,
            icon: const Icon(Icons.lock),
            label: const Text("Change Password"),
          ),
        ],
      ),
    );
  }
}
