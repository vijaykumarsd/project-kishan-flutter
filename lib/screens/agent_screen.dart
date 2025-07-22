import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'app_localizations.dart'; // Import AppLocalizations

// 🔹 ChatMessage model (no change needed here for localization)
class ChatMessage {
  final String sender;
  final String message;

  ChatMessage({required this.sender, required this.message});
}

class AgentScreen extends StatefulWidget {
  final String agentTitle;
  final AppLocalizations appStrings; // Receive AppLocalizations

  const AgentScreen({super.key, required this.agentTitle, required this.appStrings});

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
    _setTtsLanguage(); // Set TTS language based on selected app language
  }

  // Set the TTS language based on the current app language
  Future<void> _setTtsLanguage() async {
    String ttsLangCode = 'en-US'; // Default TTS language
    switch (widget.appStrings.locale) {
      case 'hi':
        ttsLangCode = 'hi-IN';
        break;
      case 'mr':
        ttsLangCode = 'mr-IN';
        break;
      case 'ta':
        ttsLangCode = 'ta-IN';
        break;
      case 'kn':
        ttsLangCode = 'kn-IN';
        break;
      case 'te':
        ttsLangCode = 'te-IN';
        break;
      case 'ml':
        ttsLangCode = 'ml-IN';
        break;
      case 'en':
      default:
        ttsLangCode = 'en-US'; // Fallback to en-US for English
        break;
    }
    await _flutterTts.setLanguage(ttsLangCode);
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

  // 🤖 Hardcoded simulated replies, now localized
  String _getAgentReply(String userInput) {
    final input = userInput.toLowerCase();
    final appStrings = widget.appStrings; // Access localized strings

    if (input.contains('hi') || input.contains('hello')) {
      return appStrings.get('hi_how_can_i_help');
    } else if (input.contains(appStrings.get('weather').toLowerCase())) { // Localize keyword for weather
      return appStrings.get('todays_weather');
    } else if (input.contains(appStrings.get('your_name').toLowerCase())) { // Localize keyword for name
      return appStrings.get('im_your_assistant_agent');
    } else if (input.contains(appStrings.get('thanks').toLowerCase())) { // Localize keyword for thanks
      return appStrings.get('youre_welcome');
    } else {
      return appStrings.get('sorry_didnt_understand');
    }
  }

  // 🔉 Text-to-speech
  void _speak(String text) async {
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
        SnackBar(content: Text(widget.appStrings.get('speech_recognition_not_available'))), // Localized
      );
    }
  }

  // 📸 Placeholder for camera feature
  void _handleCameraInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.appStrings.get('camera_input_clicked'))), // Localized
    );
  }

  // 💬 Chat bubble widget (no change needed here for localization of message content)
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
        title: Text(widget.agentTitle), // Title is passed from HomeScreen, already localized there
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
                    decoration: InputDecoration(
                      hintText: widget.appStrings.get('type_your_question'), // Localized hint text
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
