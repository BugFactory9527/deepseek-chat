import 'package:flutter/material.dart';
import 'typewriter_text.dart';

class ChatMessage {
  final String text;
  final bool isAI;

  ChatMessage({required this.text, required this.isAI});
}

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: message.isAI 
              ? Colors.grey.shade200 
              : Theme.of(context).colorScheme.primary.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16.0),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: message.isAI 
            ? TypewriterText(
                text: message.text,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16.0,
                ),
                // 可以调整打字速度
                typingSpeed: const Duration(milliseconds: 30),
              )
            : Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
      ),
    );
  }
}