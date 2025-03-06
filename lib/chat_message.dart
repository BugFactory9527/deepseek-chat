import 'package:flutter/material.dart';
import 'dart:async';

class ChatMessage {
  final String text;
  final bool isAI;
  final StreamController<String>? streamController; // 新增流控制器

  ChatMessage({
    required this.text,
    required this.isAI,
    this.streamController,
  });
}

class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;

  const ChatMessageWidget({Key? key, required this.message}) : super(key: key);

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  String _displayText = '';
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _displayText = widget.message.isAI ? '' : widget.message.text;

    // 如果是AI消息并且有流控制器，开始监听流事件
    if (widget.message.isAI && widget.message.streamController != null) {
      print('开始监听流事件');
      _subscription = widget.message.streamController!.stream.listen(
        (chunk) {
          print('收到字符: "$chunk"');
          setState(() {
            _displayText += chunk;
          });
        },
        onError: (error) {
          print('流错误: $error');
        },
        onDone: () {
          print('流结束');
        },
      );
    } else if (widget.message.isAI) {
      // 如果没有流控制器但是是AI消息，直接显示完整文本
      _displayText = widget.message.text;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          widget.message.isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: widget.message.isAI
              ? Colors.grey.shade200
              : Theme.of(context).colorScheme.primary.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16.0),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Text(
          _displayText,
          style: TextStyle(
            color: widget.message.isAI ? Colors.black87 : Colors.white,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }
}
