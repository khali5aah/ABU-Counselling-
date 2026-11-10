import 'package:flutter/material.dart';

class DummyChatScreen extends StatelessWidget {
  DummyChatScreen({super.key});

  final List<Map<String, String>> _dummyMessages = [
    {
      "sender": "Counselor",
      "text": "Hello! Welcome to Crownbird Counseling. How can I support you today?"
    },
    {
      "sender": "Me",
      "text": "Hi, I wanted to check up on my ongoing case and next steps."
    },
    {
      "sender": "Counselor",
      "text": "Your case details are secure and pseudonymous. A counselor will be assigned shortly."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Counselor Chat (Preview)"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _dummyMessages.length,
              itemBuilder: (context, index) {
                final message = _dummyMessages[index];
                final isMe = message['sender'] == 'Me';

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.indigo[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe 
                          ? CrossAxisAlignment.end 
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['sender']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isMe ? Colors.indigo[900] : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message['text']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: "Chat development stage pending...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.grey),
                  onPressed: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}