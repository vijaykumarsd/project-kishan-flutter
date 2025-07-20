import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

// 🔹 ChatMessage model
class ChatMessage {
  final String sender;
  final String message;

  ChatMessage({required this.sender, required this.message});
}

class AgentScreen extends StatefulWidget {
  final String agentTitle;

  const AgentScreen({super.key, required this.agentTitle});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  // 🔸 Handle sending user message and agent response
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(sender: 'user', message: text));
      _controller.clear();
    });

    // Generate agent reply
    final agentReply = _getAgentReply(text);

    // Add reply and speak it after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(ChatMessage(sender: 'agent', message: agentReply));
      });
      _speak(agentReply);
    });
  }

  // 🤖 Hardcoded simulated replies
  String _getAgentReply(String userInput) {
    final input = userInput.toLowerCase();

    if (input.contains('hi') || input.contains('hello')) {
      return 'Hi, how can I help you?';
    } else if (input.contains('weather')) {
      return "Today's weather is sunny and clear.";
    } else if (input.contains('your name')) {
      return "I'm your assistant agent.";
    } else if (input.contains('thanks')) {
      return "You're welcome!";
    } else {
      return "Sorry, I didn't understand that. Can you rephrase?";
    }
  }

  // 🔉 Text-to-speech
  void _speak(String text) async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  // 🎤 Voice to text
  void _handleVoiceInput() async {
    final available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  // 📸 Placeholder for camera feature
  void _handleCameraInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📷 Camera input clicked')),
    );
  }

  // 💬 Chat bubble widget
  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.sender == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.green[100] : Colors.blue[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.message,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.agentTitle),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // Chat message list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildChatBubble(_messages[index]);
              },
            ),
          ),

          // Input section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.mic, color: Colors.green),
                  onPressed: _handleVoiceInput,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.green),
                  onPressed: _handleCameraInput,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your question...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
