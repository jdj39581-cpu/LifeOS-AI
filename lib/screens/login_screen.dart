import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import 'register_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;
  bool rememberMe = true;

  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() => loading = true);

    bool ok = await ApiService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => loading = false);

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login failed")));
    }
  }

  Future<void> googleLogin() async {
    setState(() => loading = true);

    try {
      final user = await GoogleAuthService.signInWithGoogle();

      if (!mounted) return;

      setState(() => loading = false);

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google Sign-In cancelled")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Google Sign-In failed: $e")));
    }
  }

  Widget textBox({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool password = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: controller,
        obscureText: password ? hidePassword : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          prefixIcon: Icon(icon, color: Colors.white70),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          suffixIcon: password
              ? IconButton(
                  onPressed: () {
                    setState(() => hidePassword = !hidePassword);
                  },
                  icon: Icon(
                    hidePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF090B1A),
          body: Stack(
            children: [
              Positioned(
                top: -120,
                left: -80,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple.withOpacity(.25),
                  ),
                ),
              ),

              Positioned(
                bottom: -120,
                right: -80,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(.25),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: CircleAvatar(
                          backgroundColor: Colors.white12,
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.dark_mode,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.cyan,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Welcome to the Future",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF06B6D4),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "LifeOS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "Your Life. Organized. Powered by AI.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),

                      const SizedBox(height: 18),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: const [
                          Chip(
                            label: Text("Plan Smarter"),
                            avatar: Icon(Icons.calendar_today, size: 18),
                          ),
                          Chip(
                            label: Text("Stay Productive"),
                            avatar: Icon(Icons.trending_up, size: 18),
                          ),
                          Chip(
                            label: Text("Be Ahead"),
                            avatar: Icon(Icons.bolt, size: 18),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.08),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Welcome Back!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              "Login to continue your journey",
                              style: TextStyle(color: Colors.white60),
                            ),

                            const SizedBox(height: 24),

                            textBox(
                              controller: emailController,
                              hint: "Email",
                              icon: Icons.email_outlined,
                            ),

                            const SizedBox(height: 16),

                            textBox(
                              controller: passwordController,
                              hint: "Password",
                              icon: Icons.lock_outline,
                              password: true,
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Checkbox(
                                  value: rememberMe,
                                  onChanged: (v) {
                                    setState(() => rememberMe = v ?? false);
                                  },
                                ),
                                const Text(
                                  "Remember me",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text("Forgot Password?"),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Container(
                              width: double.infinity,
                              height: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFF2563EB),
                                  ],
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF2563EB),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: loading ? null : login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: loading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: loading ? null : googleLogin,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.g_mobiledata,
                                  color: Colors.white,
                                  size: 34,
                                ),
                                label: const Text(
                                  "Continue with Google",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text.rich(
                                TextSpan(
                                  text: "New to LifeOS AI? ",
                                  style: TextStyle(color: Colors.white70),
                                  children: [
                                    TextSpan(
                                      text: "Create an Account →",
                                      style: TextStyle(
                                        color: Colors.cyanAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, color: Colors.white38, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "Secure • Private • Always With You",
                            style: TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
