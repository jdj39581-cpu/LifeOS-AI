import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const String _backupKey = "lifeos_backup";

  // Create Backup
  static Future<bool> createBackup({
    required List tasks,
    required List notes,
    required List reminders,
    required List expenses,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final backup = {
      "time": DateTime.now().toIso8601String(),
      "tasks": tasks,
      "notes": notes,
      "reminders": reminders,
      "expenses": expenses,
    };

    return await prefs.setString(_backupKey, jsonEncode(backup));
  }

  // Get Backup
  static Future<Map<String, dynamic>?> getBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_backupKey);

    if (data == null) return null;

    return jsonDecode(data) as Map<String, dynamic>;
  }

  // Check Backup
  static Future<bool> hasBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_backupKey);
  }

  // Delete Backup
  static Future<void> deleteBackup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backupKey);
  }
}
