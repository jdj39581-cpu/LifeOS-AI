import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../services/api_service.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String question = _controller.text.trim();

    setState(() {
      _messages.add({"role": "user", "text": question});
      _controller.clear();
    });

    try {
      String reply = await ApiService.askAI(question);

      if (!mounted) return;

      setState(() {
        _messages.add({"role": "ai", "text": reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "ai",
          "text": "Sorry, I couldn't get a response.",
        });
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text("LifeOS AI"),
      ),
      body: Column(
        children: [
          if (_messages.isEmpty) ...[
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                size: 70,
                color: Color(0xFF06B6D4),
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedTextKit(
                repeatForever: false,
                totalRepeatCount: 1,
                animatedTexts: [
                  TypewriterAnimatedText(
                    "Hello Joyson 👋\nI'm LifeOS AI.\nHow can I help you today?",
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    speed: const Duration(milliseconds: 45),
                  ),
                ],
              ),
            ),
          ],

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF06B6D4)
                          : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 18),
            decoration: const BoxDecoration(color: Color(0xFF111827)),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.mic, color: Colors.cyan),
                  onPressed: () {},
                ),

                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Ask anything...",
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyan),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
