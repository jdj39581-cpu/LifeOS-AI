import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'ai_screen.dart';
import 'calendar_screen.dart';
import 'notes_screen.dart';
import 'task_screens.dart';
import 'reminder_screen.dart';
import 'expense_screen.dart';
import 'goals_screen.dart';
import 'habit_screen.dart';
import 'events_screen.dart';
import 'documents_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../widgets/dynamic_island.dart';
import '../widgets/command_palette.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  String city = "Loading...";
  String temp = "--°C";
  String weather = "Loading...";
  String humidity = "--%";
  String wind = "-- m/s";
  String feelsLike = "--°C";
  int pendingTasks = 3;
  int todayEvents = 2;
  double todayExpense = 450;

  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  late AnimationController _orbController;
  late Animation<double> _orbAnimation;

  @override
  void initState() {
    super.initState();
    loadWeather();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _orbAnimation = Tween<double>(
      begin: 0.95,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _orbController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _orbController.dispose();
    super.dispose();
  }

  Future<void> loadWeather() async {
    try {
      final position = await LocationService.getCurrentLocation();

      final data = await ApiService.getWeather(
        position.latitude,
        position.longitude,
      );

      if (!mounted || data == null) return;

      setState(() {
        city = data["name"] ?? "Unknown";
        temp = "${data["main"]?["temp"] ?? "--"}°C";
        feelsLike = "${data["main"]?["feels_like"] ?? "--"}°C";
        humidity = "${data["main"]?["humidity"] ?? "--"}%";
        wind = "${data["wind"]?["speed"] ?? "--"} m/s";

        if (data["weather"] is List && data["weather"].isNotEmpty) {
          weather = data["weather"][0]["main"];
        } else {
          weather = "Unknown";
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        city = "Unknown";
        temp = "--°C";
        weather = "Unavailable";
        humidity = "--%";
        wind = "-- m/s";
        feelsLike = "--°C";
      });
    }
  }

  String getWeatherAnimation() {
    switch (weather.toLowerCase()) {
      case "rain":
        return "https://assets9.lottiefiles.com/packages/lf20_jmBauI.json";
      case "clouds":
      case "cloudy":
        return "https://assets2.lottiefiles.com/packages/lf20_xlKy4m.json";
      case "clear":
      case "sunny":
        return "https://assets2.lottiefiles.com/packages/lf20_Stt1R6.json";
      default:
        return "https://assets2.lottiefiles.com/packages/lf20_xlKy4m.json";
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    if (hour < 21) return "Good Evening";
    return "Good Night";
  }

  Widget info(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  Widget aiOrb() {
    return Center(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AIScreen()),
          );
        },
        child: AnimatedBuilder(
          animation: _orbAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _orbAnimation.value,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF67E8F9),
                      Color(0xFF2563EB),
                      Color(0xFF7C3AED),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withOpacity(.55),
                      blurRadius: 35,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(.35),
                      blurRadius: 55,
                      spreadRadius: 14,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 105,
                      height: 105,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(.12),
                      ),
                    ),
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 55,
                    ),
                    Positioned(
                      top: 28,
                      right: 36,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 34,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(.9),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget searchBar() {
    return GestureDetector(
      onTap: () {
        CommandPalette.open(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(.12),
              Colors.white.withOpacity(.06),
            ],
          ),
          border: Border.all(color: Colors.white24),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.cyanAccent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Search tasks, notes, AI...",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            Icon(Icons.mic, color: Colors.cyanAccent),
          ],
        ),
      ),
    );
  }

  Widget liveClockCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(.25), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              DateFormat('hh:mm:ss a').format(_now),
              key: ValueKey(_now.second),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('EEEE, dd MMMM yyyy').format(_now),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget aiDailyBriefCard() {
    String suggestion;

    if (_now.hour < 12) {
      suggestion = "Start with your highest-priority task.";
    } else if (_now.hour < 17) {
      suggestion = "You still have time to finish today's work.";
    } else {
      suggestion = "Finish important tasks before 9 PM.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(.12),
            Colors.white.withOpacity(.05),
          ],
        ),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(.18), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.cyanAccent),
              SizedBox(width: 8),
              Text(
                "AI Daily Brief",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              briefTile(Icons.check_circle, "$pendingTasks", "Tasks"),
              briefTile(Icons.calendar_today, "$todayEvents", "Events"),
              briefTile(
                Icons.account_balance_wallet,
                "₹${todayExpense.toInt()}",
                "Spent",
              ),
              briefTile(Icons.cloud, temp, weather),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.cyanAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    suggestion,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget briefTile(IconData icon, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "⚡ Quick Actions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            quickButton(Icons.add_task, "Task", const TaskScreen()),
            quickButton(Icons.mic, "AI", const AIScreen()),
            quickButton(
              Icons.account_balance_wallet,
              "Expense",
              const ExpenseScreen(),
            ),
            quickButton(Icons.note_add, "Note", const NotesScreen()),
          ],
        ),
      ],
    );
  }

  Widget quickButton(IconData icon, String label, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        width: 76,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(.15),
              Colors.white.withOpacity(.06),
            ],
          ),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(.25),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget module(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return AnimatedModuleButton(
      icon: icon,
      label: label,
      onTap: () => Navigator.pushNamed(context, route),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -80,
                    left: -60,
                    child: Transform.translate(
                      offset: Offset(25 * _orbController.value, 15),
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF06B6D4).withOpacity(0.18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF06B6D4).withOpacity(0.35),
                              blurRadius: 90,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: -90,
                    right: -70,
                    child: Transform.translate(
                      offset: Offset(-30 * _orbController.value, -15),
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF7C3AED).withOpacity(0.16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.35),
                              blurRadius: 100,
                              spreadRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          RefreshIndicator(
            onRefresh: loadWeather,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  AnimatedBuilder(
                    animation: _orbController,
                    builder: (context, child) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(
                                const Color(0xFF2563EB),
                                const Color(0xFF7C3AED),
                                _orbController.value,
                              )!,
                              Color.lerp(
                                const Color(0xFF06B6D4),
                                const Color(0xFF9333EA),
                                _orbController.value,
                              )!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(.25),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${getGreeting()} 👋",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    "Joyson",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat(
                                      'EEEE, dd MMM yyyy',
                                    ).format(_now),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.cyanAccent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(.45),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white24,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 18),
                  searchBar(),
                  const SizedBox(height: 22),
                  aiOrb(),
                  const SizedBox(height: 24),

                  // Weather Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(.18),
                          Colors.white.withOpacity(.08),
                        ],
                      ),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  city,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: Lottie.network(getWeatherAnimation()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          temp,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          weather,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            info(Icons.water_drop, "Humidity", humidity),
                            info(Icons.air, "Wind", wind),
                            info(Icons.thermostat, "Feels", feelsLike),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  liveClockCard(),

                  const SizedBox(height: 18),

                  aiDailyBriefCard(),

                  const SizedBox(height: 22),

                  quickActions(),

                  const SizedBox(height: 28),

                  const Text(
                    "Modules",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.25,
                    children: [
                      module(context, Icons.smart_toy, "AI", "/ai"),
                      module(
                        context,
                        Icons.calendar_month,
                        "Calendar",
                        "/calendar",
                      ),
                      module(context, Icons.note_alt, "Notes", "/notes"),
                      module(context, Icons.check_box, "Tasks", "/tasks"),
                      module(context, Icons.alarm, "Reminder", "/reminders"),
                      module(
                        context,
                        Icons.account_balance_wallet,
                        "Expense",
                        "/expenses",
                      ),
                      module(context, Icons.flag, "Goals", "/goals"),
                      module(
                        context,
                        Icons.local_fire_department,
                        "Habit",
                        "/habits",
                      ),
                      module(context, Icons.event, "Events", "/events"),
                      module(context, Icons.folder, "Documents", "/documents"),
                      module(
                        context,
                        Icons.analytics,
                        "Analytics",
                        "/analytics",
                      ),
                      module(context, Icons.person, "Profile", "/profile"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedModuleButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AnimatedModuleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<AnimatedModuleButton> createState() => _AnimatedModuleButtonState();
}

class _AnimatedModuleButtonState extends State<AnimatedModuleButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: pressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: pressed ? Colors.cyanAccent : Colors.white12,
            ),
            boxShadow: [
              BoxShadow(
                color: pressed
                    ? Colors.cyanAccent.withOpacity(.35)
                    : Colors.black.withOpacity(.25),
                blurRadius: pressed ? 20 : 10,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(pressed ? .20 : .10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.cyanAccent,
                  size: pressed ? 32 : 30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
