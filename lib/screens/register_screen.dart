import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

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
    super.dispose();
  }

  Future<void> register() async {
    setState(() => loading = true);

    bool ok = await ApiService.register(
      nameController.text.trim(),
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration failed")));
    }
  }

  Widget glowCircle(double size, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.1),
      duration: const Duration(seconds: 3),
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 60,
              spreadRadius: 10,
            ),
          ],
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
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
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
            child: Stack(
              children: [
                Positioned(
                  top: 80,
                  left: -30,
                  child: glowCircle(170, const Color(0xFF7C3AED)),
                ),
                Positioned(
                  bottom: 100,
                  right: -40,
                  child: glowCircle(220, const Color(0xFF06B6D4)),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.person_add_alt_1,
                            color: Colors.white,
                            size: 70,
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            "Create Account",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 25),
                          _field(nameController, "Name", Icons.person),
                          const SizedBox(height: 15),
                          _field(emailController, "Email", Icons.email),
                          const SizedBox(height: 15),
                          TextField(
                            controller: passwordController,
                            obscureText: hidePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Password",
                              hintStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.white,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                                onPressed: () => setState(
                                  () => hidePassword = !hidePassword,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF06B6D4,
                                  ).withOpacity(0.6),
                                  blurRadius: 25,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: loading ? null : register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF06B6D4),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Create Account",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Back to Login",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
