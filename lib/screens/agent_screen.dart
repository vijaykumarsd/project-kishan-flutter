import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:kisan_app/screens/app_localizations.dart';

class AgentScreen extends StatefulWidget {
  final String agentTitle;
  final AppLocalizations appStrings;

  const AgentScreen({super.key, required this.agentTitle, required this.appStrings});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class ChatMessage {
  final String sender;
  final String message;

  ChatMessage({required this.sender, required this.message});
}

class _AgentScreenState extends State<AgentScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = '';
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _setTtsLanguage();
  }

  Future<void> _setTtsLanguage() async {
    String ttsLangCode = 'en-US';
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
        ttsLangCode = 'en-US';
        break;
    }
    await _flutterTts.setLanguage(ttsLangCode);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('Speech status: $val'),
        onError: (val) => print('Speech error: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
              _controller.text = _text;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }


  Future<void> _sendRequestToBackend({String? queryText, File? imageFile}) async {
    final url = Uri.parse('http://127.0.0.1:8009/api/simple');

    var request = http.MultipartRequest('POST', url);

    if (queryText != null && queryText.trim().isNotEmpty) {
      request.fields['query'] = queryText.trim();
    }

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path, filename: basename(imageFile.path)));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final agentReply = jsonResponse['response'];

        setState(() {
          if (queryText != null && queryText.trim().isNotEmpty) {
            _messages.add(ChatMessage(sender: 'user', message: queryText));
          } else {
            _messages.add(ChatMessage(sender: 'user', message: '📷 Sent an image'));
          }
          _messages.add(ChatMessage(sender: 'agent', message: agentReply));
        });
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('API error: $e');
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _sendTextToBackend() async {
    final queryText = _controller.text.trim();
    if (queryText.isEmpty) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(content: Text("Please speak or type your query")),
      );
      return;
    }
    await _sendRequestToBackend(queryText: queryText);
    _controller.clear();
  }

  Future<void> _pickImageAndSend() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      _selectedImage = File(picked.path);
      await _sendRequestToBackend(imageFile: _selectedImage);
    }
  }

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
      backgroundColor: const Color(0xFFD8F3DC),
      appBar: AppBar(
        title: const Text('Agent'),
        backgroundColor: const Color(0xFF40916C),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "Ask your agent",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildChatBubble(_messages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type your question...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _listen,
                  backgroundColor: const Color(0xFF40916C),
                  child: Icon(_isListening ? Icons.mic_off : Icons.mic),
                ),
                FloatingActionButton(
                  onPressed: _pickImageAndSend,
                  backgroundColor: const Color(0xFF40916C),
                  child: const Icon(Icons.camera_alt),
                ),
                FloatingActionButton(
                  onPressed: _sendTextToBackend,
                  backgroundColor: const Color(0xFF40916C),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
 