import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  
  const ChatInput({
    Key? key,
    required this.controller,
    required this.onSubmitted,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.mic),
              onPressed: () {
                // TODO: Implement voice input
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voice input coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Ask your AI health coach...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: onSubmitted,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              color: Colors.purple,
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onSubmitted(controller.text);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}