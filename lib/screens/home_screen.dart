import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/app_drawer.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> dashboard = {};
  bool loading = true;
  Map<String, dynamic>? weather;
  @override
  void initState() {
    super.initState();
    loadDashboard();
    loadWeather();
  }

  Future<void> loadDashboard() async {
    dashboard = await ApiService.getDashboard();

    setState(() {
      loading = false;
    });
  }

  Future<void> loadWeather() async {
    print("STEP 1: loadWeather called");

    final position = await LocationService.getLocation();
    print("STEP 2: Position = $position");

    if (position == null) {
      print("STEP 3: Location is null");
      return;
    }

    weather = await WeatherService.getWeather(
      position.latitude,
      position.longitude,
    );

    print("STEP 4: Weather = $weather");

    setState(() {});
  }

  Widget buildCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Colors.indigo, Colors.blue]),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "👋 Welcome to LifeOS AI",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Your personal productivity assistant.\nManage tasks, goals, expenses, reminders and much more.",
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("LifeOS AI"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, "/search");
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    welcomeCard(),

                    const SizedBox(height: 15),
                    if (weather != null)
                      Card(
                        elevation: 5,
                        child: ListTile(
                          leading: const Icon(
                            Icons.wb_sunny,
                            color: Colors.orange,
                            size: 40,
                          ),
                          title: Text(
                            "${weather!["main"]["temp"]}°C - ${weather!["weather"][0]["description"]}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(weather!["name"]),
                        ),
                      ),

                    const SizedBox(height: 15),

                    if (weather != null)
                      Card(
                        elevation: 5,
                        child: ListTile(
                          leading: const Icon(
                            Icons.wb_sunny,
                            color: Colors.orange,
                            size: 40,
                          ),
                          title: Text(
                            "${weather!["main"]["temp"]}°C",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          subtitle: Text(
                            "${weather!["name"]}\n${weather!["weather"][0]["description"]}",
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    const Text(
                      "Dashboard",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: "Tasks",
                            value: "${dashboard["total_tasks"]}",
                            icon: Icons.task,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DashboardCard(
                            title: "Completed",
                            value: "${dashboard["completed_tasks"]}",
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DashboardCard(
                            title: "Pending",
                            value: "${dashboard["pending_tasks"]}",
                            icon: Icons.pending_actions,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1,
                      children: [
                        buildCard(
                          context,
                          Icons.task,
                          "Tasks",
                          Colors.orange,
                          "/tasks",
                        ),
                        buildCard(
                          context,
                          Icons.note,
                          "Notes",
                          Colors.blue,
                          "/notes",
                        ),
                        buildCard(
                          context,
                          Icons.alarm,
                          "Reminders",
                          Colors.red,
                          "/reminders",
                        ),
                        buildCard(
                          context,
                          Icons.account_balance_wallet,
                          "Expenses",
                          Colors.green,
                          "/expenses",
                        ),
                        buildCard(
                          context,
                          Icons.flag,
                          "Goals",
                          Colors.purple,
                          "/goals",
                        ),
                        buildCard(
                          context,
                          Icons.local_fire_department,
                          "Habits",
                          Colors.deepOrange,
                          "/habits",
                        ),
                        buildCard(
                          context,
                          Icons.notifications,
                          "Notifications",
                          Colors.amber,
                          "/notifications",
                        ),
                        buildCard(
                          context,
                          Icons.analytics,
                          "Analytics",
                          Colors.cyan,
                          "/analytics",
                        ),
                        buildCard(
                          context,
                          Icons.smart_toy,
                          "AI Assistant",
                          Colors.teal,
                          "/ai",
                        ),
                        buildCard(
                          context,
                          Icons.event,
                          "Events",
                          Colors.deepPurple,
                          "/events",
                        ),
                        buildCard(
                          context,
                          Icons.folder,
                          "Documents",
                          Colors.indigo,
                          "/documents",
                        ),
                        buildCard(
                          context,
                          Icons.person,
                          "Profile",
                          Colors.brown,
                          "/profile",
                        ),
                        buildCard(
                          context,
                          Icons.calendar_month,
                          "Calendar",
                          Colors.blue,
                          "/calendar",
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        "LifeOS AI v1.0",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
