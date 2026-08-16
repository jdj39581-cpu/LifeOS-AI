import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatHistoryService {
  static const String _key = "lifeos_ai_chat_history";

  // Save all chats
  static Future<void> saveChats(List<Map<String, String>> chats) async {
    final prefs = await SharedPreferences.getInstance();
    final data = chats.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList(_key, data);
  }

  // Load all chats
  static Future<List<Map<String, String>>> loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key);

    if (data == null) return [];

    return data.map((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(key, value.toString()));
    }).toList();
  }

  // Clear chat history
  static Future<void> clearChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
