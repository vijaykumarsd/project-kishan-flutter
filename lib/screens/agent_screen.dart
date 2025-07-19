import 'package:flutter/material.dart';

class AgentScreen extends StatefulWidget {
  final String agentTitle;

  const AgentScreen({super.key, required this.agentTitle});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(text);
        _controller.clear();
      });
    }
  }

  void _handleVoiceInput() {
    // TODO: Integrate mic input
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎙 Voice input clicked')),
    );
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
