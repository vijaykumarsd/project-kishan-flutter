import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';


class AgentScreen extends StatefulWidget {
  final String agentTitle;

  const AgentScreen({super.key, required this.agentTitle});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  late stt.SpeechToText _speech;
  bool _isListening = false;
  late FlutterTts _flutterTts;

   @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
     _flutterTts = FlutterTts();
  }


// 1. This handles text message from the user via the input box (keyboard):
// Grabs the user-typed text.
// Shows it on screen.
// Speaks it back using _speak.

  void _sendMessage() {
    // final text = _controller.text.trim();
    // if (text.isNotEmpty) {
    //   setState(() {
    //     _messages.add(text);
    //     _controller.clear();
    //   });
    // }
      final text = _controller.text.trim();
  if (text.isNotEmpty) {
    setState(() {
      _messages.add(text);
      _controller.clear();
    });

    // Speak out the response (simulate agent reply)
    _speak("You said: $text"); // Replace with actual AI/response later
  }
  }

  //2. this method is for making the agent to talk back to the user
//   Converts a string to speech using device speaker.
// Useful for making the agent “talk back.”

  void _speak(String text) async {
  await _flutterTts.setLanguage("en-IN");
  await _flutterTts.setPitch(1);
  await _flutterTts.speak(text);
}


//3. This handles speech-to-text using speech_to_text():
// Starts mic.
// Converts voice to text.
// Automatically fills the text into _controller.text.
// 👉 You can then press the Send button to send the transcribed message (just like typing).
  void _handleVoiceInput() async{
      bool available = await _speech.initialize();
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

  void _handleCameraInput() {
    // TODO: Integrate camera input
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📷 Camera input clicked')),
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
          // 🧾 Message list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_messages[index]),
                  ),
                );
              },
            ),
          ),

          // 🎤 🎥 📝 Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
