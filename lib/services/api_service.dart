import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.105:8000";

  static String token = "";

  // LOGIN
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"username": email, "password": password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data["access_token"];
      return true;
    }
    return false;
  }

  // GET TASKS
  static Future<List<dynamic>> getTasks() async {
    final response = await http.get(
      Uri.parse("$baseUrl/tasks"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["tasks"];
    }

    return [];
  }

  // ADD TASK
  static Future<bool> addTask(String title, String description) async {
    final response = await http.post(
      Uri.parse("$baseUrl/tasks"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"title": title, "description": description}),
    );

    return response.statusCode == 200;
  }

  // UPDATE TASK
  static Future<bool> updateTask(
    int id,
    String title,
    String description,
    String status,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/tasks/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "title": title,
        "description": description,
        "status": status,
      }),
    );

    return response.statusCode == 200;
  }

  // DELETE TASK
  static Future<bool> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/tasks/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  // GET NOTES
  static Future<List<dynamic>> getNotes() async {
    final response = await http.get(
      Uri.parse("$baseUrl/notes"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["notes"];
    }

    return [];
  }

  // GET NOTES
  // ADD NOTE
  static Future<bool> addNote(String title, String content) async {
    final response = await http.post(
      Uri.parse("$baseUrl/notes"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"title": title, "content": content}),
    );

    return response.statusCode == 200;
  }

  // UPDATE NOTE
  static Future<bool> updateNote(int id, String title, String content) async {
    final response = await http.put(
      Uri.parse("$baseUrl/notes/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"title": title, "content": content}),
    );

    return response.statusCode == 200;
  }

  // DELETE NOTE
  static Future<bool> deleteNote(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/notes/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  // AI CHAT
  static Future<String> askAI(String message) async {
    final response = await http.post(
      Uri.parse("$baseUrl/ai"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"message": message}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["reply"];
    }

    return "Unable to connect.";
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse("$baseUrl/dashboard"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {"total_tasks": 0, "completed_tasks": 0, "pending_tasks": 0};
  }

  // GET REMINDERS
  static Future<List<dynamic>> getReminders() async {
    final response = await http.get(
      Uri.parse("$baseUrl/reminders"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["reminders"];
    }

    return [];
  }

  // ADD REMINDER
  static Future<bool> addReminder(String title, String reminderTime) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reminders"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"title": title, "reminder_time": reminderTime}),
    );

    print(response.statusCode);
    print(response.body);

    return response.statusCode == 200;
  }

  static Future<bool> deleteReminder(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/reminders/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  // GET EXPENSES
  static Future<List<dynamic>> getExpenses() async {
    final response = await http.get(
      Uri.parse("$baseUrl/expenses"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["expenses"];
    }

    return [];
  }

  // GET GOALS
  static Future<List<dynamic>> getGoals() async {
    final response = await http.get(
      Uri.parse("$baseUrl/goals"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["goals"];
    }

    return [];
  }

  // ADD GOAL
  static Future<bool> addGoal(String title, String targetDate) async {
    final response = await http.post(
      Uri.parse("$baseUrl/goals"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"title": title, "target_date": targetDate}),
    );

    return response.statusCode == 200;
  }

  // COMPLETE GOAL
  static Future<bool> completeGoal(int id) async {
    final response = await http.put(
      Uri.parse("$baseUrl/goals/$id/complete"),
      headers: {"Authorization": "Bearer $token"},
    );
    return response.statusCode == 200;
  }

  // DELETE GOAL
  static Future<bool> deleteGoal(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/goals/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  // ADD EXPENSE
  static Future<bool> addExpense(
    String title,
    double amount,
    String category,
    String date,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/expenses"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "title": title,
        "amount": amount,
        "category": category,
        "expense_date": date,
      }),
    );

    return response.statusCode == 200;
  }

  // UPDATE EXPENSE
  static Future<bool> updateExpense(
    int id,
    String title,
    double amount,
    String category,
    String date,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/expenses/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "title": title,
        "amount": amount,
        "category": category,
        "expense_date": date,
      }),
    );

    return response.statusCode == 200;
  }

  // DELETE EXPENSE
  static Future<bool> deleteExpense(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/expenses/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  // GET HABITS
  static Future<List<dynamic>> getHabits() async {
    final response = await http.get(
      Uri.parse("$baseUrl/habits"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["habits"];
    }

    return [];
  }

  // ADD HABIT
  static Future<bool> addHabit(String title) async {
    final response = await http.post(
      Uri.parse("$baseUrl/habits"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"title": title}),
    );

    return response.statusCode == 200;
  }

  // COMPLETE HABIT
  static Future<bool> completeHabit(int id) async {
    final response = await http.put(
      Uri.parse("$baseUrl/habits/$id/complete"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  // RESET HABIT
  static Future<bool> resetHabit(int id) async {
    final response = await http.put(
      Uri.parse("$baseUrl/habits/$id/reset"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  // DELETE HABIT
  static Future<bool> deleteHabit(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/habits/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  // GET NOTIFICATIONS
  static Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse("$baseUrl/notifications"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["notifications"];
    }

    return [];
  }

  // DELETE NOTIFICATION
  static Future<bool> deleteNotification(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/notifications/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  // GET ANALYTICS
  static Future<Map<String, dynamic>> getAnalytics() async {
    final response = await http.get(
      Uri.parse("$baseUrl/analytics"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {
      "total_tasks": 0,
      "completed_tasks": 0,
      "pending_tasks": 0,
      "total_goals": 0,
      "completed_goals": 0,
      "total_expense": 0,
    };
  }

  static Future<List<dynamic>> search(String query) async {
    final response = await http.get(
      Uri.parse("$baseUrl/search?query=$query"),
      headers: {"Authorization": "Bearer $token"},
    );

    print("Search Status: ${response.statusCode}");
    print("Search Response:");
    print(response.body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  // GET PROFILE
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {"name": "", "email": ""};
  }

  // GET SETTINGS PROFILE
  static Future<Map<String, dynamic>> getSettingsProfile() async {
    final response = await http.get(
      Uri.parse("$baseUrl/settings/profile"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {};
  }

  // UPDATE SETTINGS PROFILE
  static Future<bool> updateSettingsProfile(String name, String email) async {
    final response = await http.put(
      Uri.parse("$baseUrl/settings/profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"name": name, "email": email}),
    );

    return response.statusCode == 200;
  }

  // CHANGE PASSWORD
  static Future<bool> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final response = await http.put(
      Uri.parse("$baseUrl/settings/password"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "old_password": oldPassword,
        "new_password": newPassword,
      }),
    );

    return response.statusCode == 200;
  }

  // GET DOCUMENTS
  static Future<List<dynamic>> getDocuments() async {
    final response = await http.get(
      Uri.parse("$baseUrl/documents"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["documents"];
    }

    return [];
  }

  // DELETE DOCUMENT
  static Future<bool> deleteDocument(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/documents/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  // UPLOAD DOCUMENT
  static Future<bool> uploadDocument(String filePath) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/documents"),
    );

    request.headers["Authorization"] = "Bearer $token";

    request.files.add(await http.MultipartFile.fromPath("file", filePath));

    var response = await request.send();

    return response.statusCode == 200;
  }

  static Future<String?> downloadDocument(int id, String fileName) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/documents/$id/download"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode != 200) {
        return null;
      }

      final directory = Directory.systemTemp;

      final file = File("${directory.path}/$fileName");

      await file.writeAsBytes(response.bodyBytes);

      return file.path;
    } catch (e) {
      print("Download error: $e");
      return null;
    }
  }

  // GET EVENTS
  static Future<List<dynamic>> getEvents() async {
    final response = await http.get(
      Uri.parse("$baseUrl/events"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["events"];
    }

    return [];
  }

  // ADD EVENT
  static Future<bool> addEvent(
    String title,
    String description,
    String eventDate,
    String eventTime,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/events"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "title": title,
        "description": description,
        "event_date": eventDate,
        "event_time": eventTime,
      }),
    );

    print("EVENT STATUS: ${response.statusCode}");
    print("EVENT RESPONSE: ${response.body}");
    return response.statusCode == 200;
  }

  // DELETE EVENT
  static Future<bool> deleteEvent(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/events/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getWeather(
    double lat,
    double lon,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl/weather?lat=$lat&lon=$lon"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    print("Weather error: ${response.statusCode}");
    print(response.body);

    return null;
  }
}
