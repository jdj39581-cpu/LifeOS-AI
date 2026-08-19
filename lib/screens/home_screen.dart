import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> dashboard = {};
  Map<String, dynamic>? weather;
  bool loading = true;
  String userName = "User";

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    loadDashboard();
    loadWeather();
  }

  Future<void> loadDashboard() async {
    dashboard = await ApiService.getDashboard();

    final profile = await ApiService.getProfile();

    if (!mounted) return;

    setState(() {
      userName = profile["name"] ?? "User";
      loading = false;
    });
  }

  Future<void> loadWeather() async {
    final position = await LocationService.getLocation();

    if (position == null) return;

    weather = await WeatherService.getWeather(
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Widget glassCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget buildCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
    );
  }

  Widget welcomeCard() {
    return glassCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "👋 Welcome, $userName",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your AI-powered life companion",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          "LifeOS AI",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, "/search"),
          ),
        ],
      ),

      floatingActionButton: ScaleTransition(
        scale: _pulseAnimation,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF06B6D4),
          onPressed: () => Navigator.pushNamed(context, "/ai"),
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : RefreshIndicator(
                onRefresh: loadDashboard,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      welcomeCard(),

                      const SizedBox(height: 20),

                      if (weather != null)
                        glassCard(
                          Row(
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: -6, end: 6),
                                duration: const Duration(seconds: 2),
                                curve: Curves.easeInOut,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(value, 0),
                                    child: child,
                                  );
                                },
                                onEnd: () {},
                                child: const Icon(
                                  Icons.wb_cloudy,
                                  color: Color(0xFF7DD3FC),
                                  size: 50,
                                ),
                              ),

                              const SizedBox(width: 15),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    weather!["name"],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  Text(
                                    "${weather!["main"]["temp"]}°C",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18,
                                    ),
                                  ),

                                  Text(
                                    weather!["weather"][0]["description"],
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      const Text(
                        "Dashboard",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: DashboardCard(
                              title: "Tasks",
                              value: "${dashboard["total_tasks"] ?? 0}",
                              icon: Icons.task,
                              color: Colors.orange,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: DashboardCard(
                              title: "Done",
                              value: "${dashboard["completed_tasks"] ?? 0}",
                              icon: Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: DashboardCard(
                              title: "Pending",
                              value: "${dashboard["pending_tasks"] ?? 0}",
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

                      const SizedBox(height: 25),

                      const Center(
                        child: Text(
                          "LifeOS AI v1.0",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
