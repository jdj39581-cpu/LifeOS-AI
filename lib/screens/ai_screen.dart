import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController messageController = TextEditingController();

  final List<Map<String, String>> messages = [];

  bool loading = false;
  bool isListening = false;

  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();

  Future<void> startListening() async {
    bool available = await speech.initialize();

    if (available) {
      setState(() {
        isListening = true;
      });

      speech.listen(
        onResult: (result) {
          setState(() {
            messageController.text = result.recognizedWords;
          });
        },
      );
    }
  }

  Future<void> stopListening() async {
    await speech.stop();

    setState(() {
      isListening = false;
    });
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    String userMessage = messageController.text;

    setState(() {
      messages.add({"sender": "You", "message": userMessage});

      loading = true;
      messageController.clear();
    });

    String reply = await ApiService.askAI(userMessage);

    await flutterTts.stop();

    setState(() {
      loading = false;

      messages.add({"sender": "LifeOS AI", "message": reply});
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    flutterTts.stop();
    speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LifeOS AI Assistant"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool isUser = messages[index]["sender"] == "You";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      messages[index]["message"]!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (loading)
            const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Ask LifeOS AI...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    if (isListening) {
                      stopListening();
                    } else {
                      startListening();
                    }
                  },
                  icon: Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.red,
                  ),
                ),

                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
