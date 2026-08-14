import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF2563EB),
                    const Color(0xFF7C3AED),
                    controller.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF06B6D4),
                    const Color(0xFF9333EA),
                    controller.value,
                  )!,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder(
                    duration: const Duration(seconds: 2),
                    tween: Tween(begin: 0.7, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.6),
                            blurRadius: 35,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "LifeOS AI",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Your Smart Life Companion",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 50),
                  const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
