import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/api_service.dart';
import '../services/chat_history_service.dart';
import '../widgets/dynamic_island.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _typing = false;

  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final chats = await ChatHistoryService.loadChats();

    if (!mounted) return;

    setState(() {
      _messages.addAll(chats);
    });

    _scrollToBottom();
  }

  Future<void> _saveChatHistory() async {
    final chats = _messages
        .map(
          (e) => {
            "role": e["role"].toString(),
            "text": e["text"].toString(),
            "time": e["time"].toString(),
          },
        )
        .toList();

    await ChatHistoryService.saveChats(chats);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _timeNow() {
    final now = DateTime.now();

    int hour = now.hour > 12 ? now.hour - 12 : now.hour;
    hour = hour == 0 ? 12 : hour;

    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $ampm";
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();

      if (available) {
        setState(() => _isListening = true);

        _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });

            if (result.finalResult) {
              setState(() => _isListening = false);
              _speech.stop();
              sendMessage();
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty || _typing) return;

    String question = _controller.text.trim();

    setState(() {
      _messages.add({"role": "user", "text": question, "time": _timeNow()});

      _controller.clear();
      _typing = true;
    });

    await _saveChatHistory();
    _scrollToBottom();

    try {
      String reply = await ApiService.askAI(question);

      if (!mounted) return;

      setState(() {
        _typing = false;

        _messages.add({"role": "ai", "text": reply, "time": _timeNow()});
      });

      await _saveChatHistory();
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _typing = false;

        _messages.add({
          "role": "ai",
          "text": "Sorry, I couldn't get a response.",
          "time": _timeNow(),
        });
      });

      await _saveChatHistory();
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget messageBubble(Map<String, dynamic> msg) {
    final bool isUser = msg["role"] == "user";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF06B6D4),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),

          if (!isUser) const SizedBox(width: 8),

          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg["text"]));

                DynamicIsland.show(
                  context,
                  icon: Icons.copy,
                  title: "Message Copied",
                  color: Colors.cyan,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                        )
                      : null,
                  color: isUser ? null : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg["text"],
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      msg["time"],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isUser) const SizedBox(width: 8),

          if (isUser)
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF334155),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF06B6D4),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Text("LifeOS AI"),
          ],
        ),
      ),

      body: Column(
        children: [
          if (_messages.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.smart_toy,
                          size: 70,
                          color: Color(0xFF06B6D4),
                        ),
                      ),

                      const SizedBox(height: 28),

                      AnimatedTextKit(
                        repeatForever: false,
                        totalRepeatCount: 1,
                        animatedTexts: [
                          TypewriterAnimatedText(
                            "Hello Joyson 👋\nI'm LifeOS AI.\nAsk me anything.",
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                            speed: const Duration(milliseconds: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_typing ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_typing && index == _messages.length) {
                    return Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFF06B6D4),
                          child: Icon(Icons.smart_toy, color: Colors.white),
                        ),

                        const SizedBox(width: 10),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "LifeOS AI is thinking...",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    );
                  }

                  return messageBubble(_messages[index]);
                },
              ),
            ),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.cyan,
                  ),
                  onPressed: _listen,
                ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Message LifeOS AI...",
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
