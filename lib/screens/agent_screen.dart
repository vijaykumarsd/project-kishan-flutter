import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:kisan_app/screens/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';

// import 'package:path/path.dart' as path; // This import is duplicated, can be removed

class AgentScreen extends StatefulWidget {
  final String agentTitle;
  final AppLocalizations appStrings;

  const AgentScreen({super.key, required this.agentTitle, required this.appStrings});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

const Map<String, String> supportedSpeechLocales = {
  'hi': 'hi_IN',
  'ta': 'ta_IN',
  'te': 'te_IN',
  'ml': 'ml_IN',
  'kn': 'kn_IN',
  'mr': 'mr_IN',
  'en': 'en_US',
};

class ChatMessage {
  final String sender;
  final String message;
  final File? image;
  final Uint8List? webImage;
  final String? imageUrl; // Added for images from chat history

  ChatMessage({
    required this.sender,
    required this.message,
    this.image,
    this.webImage,
    this.imageUrl, // Added
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
    _fetchChatHistory(); // Call this to fetch chat history on screen load
  }

  Future<void> _setTtsLanguage() async {
    String ttsLangCode = supportedSpeechLocales[widget.appStrings.locale] ?? 'en_US';
    await _flutterTts.setLanguage(ttsLangCode);
  }

  void _listen() async {
    String micLocale = supportedSpeechLocales[widget.appStrings.locale] ?? 'en_US';
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('Speech status: $val'),
        onError: (val) => print('Speech error: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen( localeId: micLocale,
          onResult: (val) {
            setState(() {
              _controller.text = val.recognizedWords;
            });
          },
        );
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
    final token = await getBearerToken();

    if (!mounted) return;

    if (token == null) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar( // Removed as BuildContext
        const SnackBar(content: Text('Error: You must be signed in.')),
      );
      return;
    }

    final url = Uri.parse('http://127.0.0.1:8009/api/simple');
    var request = http.MultipartRequest('POST', url);

    // 🔐 Set the Authorization Bearer token
    request.headers['Authorization'] = 'Bearer $token';

    if (queryText != null && queryText.trim().isNotEmpty) {
      request.fields['query'] = queryText.trim();
      request.fields['lang'] = widget.appStrings.locale;
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

       // Proper UTF decoding
      final decoded = utf8.decode(response.bodyBytes);
      final jsonResponse = jsonDecode(decoded);
      final agentReply = jsonResponse['response'];

        setState(() {
          _messages.add(ChatMessage(sender: 'agent', message: agentReply));
        });
      await _flutterTts.speak(agentReply);
    } catch (e) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar( // Removed as BuildContext
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _fetchChatHistory() async {
    final token = await getBearerToken(); // Get the bearer token
    if (!mounted) return;

    if (token == null) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar( // Removed as BuildContext
        const SnackBar(content: Text('Error: You must be signed in to view chat history.')),
      );
      return;
    }

    // Ensure this URL is correct. Based on your JSON, it might be 'chat_history' with underscore.
    final url = Uri.parse('http://127.0.0.1:8009/api/chat-history'); // Your chat history endpoint
    // final url = Uri.parse(AppConfig.apiBaseUrl);
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token', // Pass the bearer token as a request header
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        // Access the 'history' key from the JSON response
        final Map<String, dynamic> jsonMap = jsonDecode(decoded);
        final List<dynamic> rawHistory = jsonMap['history'] ?? [];
        // Reverse to show oldest messages first
        final List<dynamic> reversedHistory = rawHistory.reversed.toList();

        setState(() {
          _messages.clear(); // Clear existing messages before adding history
          for (var chatEntry in reversedHistory) {
            final String? query = chatEntry['query'];
            final String? agentResponse = chatEntry['response'];
            final String? imageUrl = chatEntry['image_url'];

            // Add user message if query exists or if it's an image-only query
            if (query != null && query.isNotEmpty) {
              _messages.add(ChatMessage(
                sender: 'user',
                message: query,
                imageUrl: imageUrl, // Associate image with user's query if present
              ));
            } else if (imageUrl != null) { // Case: User sent an image only (query is null)
              _messages.add(ChatMessage(
                sender: 'user',
                message: '', // Message is empty as it's an image-only query
                imageUrl: imageUrl,
              ));
            }

            // Add agent message if response exists
            if (agentResponse != null && agentResponse.isNotEmpty) {
              _messages.add(ChatMessage(
                sender: 'agent',
                message: agentResponse,
                // If the agent sends an image, you'd add imageUrl here.
                // Based on your provided history, image_url is for user input.
              ));
            }
          }
        });
      } else {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar( // Removed as BuildContext
          SnackBar(content: Text('Failed to load chat history: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar( // Removed as BuildContext
        SnackBar(content: Text('Error fetching chat history: $e')),
      );
    }
  }

  Future<String?> getBearerToken() async {
     final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('bearer_token');
    print('Retrieved Bearer Token from SharedPreferences in AgentScreen: $token'); // For debugging
    return token;
  }

  Future<void> _sendTextToBackend() async {
    final queryText = _controller.text.trim();
    final token = await getBearerToken();
    if (token == null) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar( // Removed as BuildContext
        const SnackBar(content: Text('Error: You must be signed in.')),
      );
      return;
    }
    if (queryText.isEmpty) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar( // Removed as BuildContext
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

    ScaffoldMessenger.of(context as BuildContext).showSnackBar( // Removed as BuildContext
      const SnackBar(content: Text("No image was selected.")),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.sender == 'user';
    // Check for local image, web image bytes, OR network image URL
    final bool hasImage = message.image != null || message.webImage != null || message.imageUrl != null;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Use light green for user messages, light blue for agent messages
          color: isUser ? Colors.green[100] : Colors.blue[100],
          borderRadius: BorderRadius.circular(16), // Rounded corners
          boxShadow: [ // Subtle shadow
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: message.image != null
                    ? Image.file(message.image!, height: 150)
                    : message.webImage != null
                        ? Image.memory(message.webImage!, height: 150)
                        : message.imageUrl != null // This is the new part to display network image
                            ? Image.network(message.imageUrl!, height: 150,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                            )
                            : const SizedBox.shrink(), // Should not happen if hasImage is true
              ),
            if (message.message.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: hasImage ? 8 : 0),
                child: SelectableText(
                  message.message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal, // Regular sans-serif for body text
                    color: Colors.black87,
                  ),
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
      backgroundColor: const Color(0xFFD8F3DC), // Light green background from (1)
      appBar: AppBar(
        title: Text(
          widget.agentTitle, // Use agentTitle instead of hardcoded 'Agent'
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // Bold sans-serif for heading
          ),
        ),
        backgroundColor: const Color(0xFF40916C), // Dark green app bar from (1)
        foregroundColor: Colors.white,
        elevation: 4, // Add subtle shadow
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                widget.appStrings.get("ask your farm guide"), // Localized
                style: const TextStyle(
                  fontSize: 24, // Keep original font size
                  fontWeight: FontWeight.bold, // Bold sans-serif for heading
                  color: Colors.black87, // Keep original text color
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: widget.appStrings.get('type_your_question'), // Localized
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                    borderSide: BorderSide.none, // Remove default border
                  ),
                  filled: true,
                  fillColor: Colors.grey[100], // Light grey fill
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.normal, // Regular sans-serif
                  color: Colors.black87,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _listen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40916C), // Dark green button from (1)
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                        elevation: 4, // Subtle shadow
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold, // Bold sans-serif
                        ),
                      ),
                      child: Icon(_isListening ? Icons.mic_off : Icons.mic),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _pickImageAndSend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40916C), // Dark green button from (1)
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                        elevation: 4, // Subtle shadow
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold, // Bold sans-serif
                        ),
                      ),
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _sendTextToBackend,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF40916C), // Dark green button from (1)
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Rounded corners
                        ),
                        elevation: 4, // Subtle shadow
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold, // Bold sans-serif
                        ),
                      ),
                      child: const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}