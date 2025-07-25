import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:kisan_app/screens/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
 
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
  final File? image;
  final Uint8List? webImage;

  ChatMessage({
    required this.sender,
    required this.message,
    this.image,
    this.webImage,
  });
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
    _setTtsLanguage();
  }

  Future<void> _setTtsLanguage() async {
    String ttsLangCode = switch (widget.appStrings.locale) {
      'hi' => 'hi-IN',
      'mr' => 'mr-IN',
      'ta' => 'ta-IN',
      'kn' => 'kn-IN',
      'te' => 'te-IN',
      'ml' => 'ml-IN',
      _ => 'en-US',
    };
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
        _speech.listen(onResult: (val) {
          setState(() {
            _controller.text = val.recognizedWords;
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _sendRequestToBackend({
    String? queryText,
    File? imageFile,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final url = Uri.parse('http://127.0.0.1:8009/api/simple');
    var request = http.MultipartRequest('POST', url);

    if (queryText != null && queryText.trim().isNotEmpty) {
      request.fields['query'] = queryText.trim();
    }

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: basename(imageFile.path),
      ));
    } else if (imageBytes != null && imageName != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageName,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final agentReply = jsonResponse['response'];

        setState(() {
          _messages.add(ChatMessage(sender: 'agent', message: agentReply));
        });
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<String?> getBearerToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    return await user.getIdToken();
  }
  return null;
}

  Future<void> _sendTextToBackend() async {
    final queryText = _controller.text.trim();
      final token = await getBearerToken();
      if (token == null) {
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      const SnackBar(content: Text('Error: You must be signed in.')),
    );
    return;
  }
    if (queryText.isEmpty) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(content: Text("Please speak or type your query")),
      );
      return;
    }

    setState(() {
      _messages.add(ChatMessage(sender: 'user', message: queryText));
    });

    _controller.clear();
    await _sendRequestToBackend(queryText: queryText);
  }

  Future<void> _pickImageAndSend() async {
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final imageBytes = result.files.single.bytes!;
        final imageName = result.files.single.name;

        setState(() {
          _messages.add(ChatMessage(sender: 'user', message: '', webImage: imageBytes));
        });

        await _sendRequestToBackend(imageBytes: imageBytes, imageName: imageName);
        return;
      }
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        final imageFile = File(picked.path);

        setState(() {
          _messages.add(ChatMessage(sender: 'user', message: '', image: imageFile));
        });

        await _sendRequestToBackend(imageFile: imageFile);
        return;
      }
    }

    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      const SnackBar(content: Text("No image was selected.")),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.sender == 'user';
    final hasImage = message.image != null || message.webImage != null;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.green[100] : Colors.blue[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: message.image != null
                    ? Image.file(message.image!, height: 150)
                    : Image.memory(message.webImage!, height: 150),
              ),
            if (message.message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.message,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
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
              "Ask your Farm guide",
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
