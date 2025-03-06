import 'dart:async';

import 'package:flutter/material.dart';

import 'chat_message.dart';
import 'config.dart';
import 'deepseek_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TypeWriter Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // 初始化 DeepSeek 客户端
  final DeepSeekClient _deepSeekClient = DeepSeekClient(Config.deepseekApiKey);

  // 可选：保存对话上下文以实现连续对话
  final List<Map<String, dynamic>> _conversationHistory = [
    {'role': 'system', 'content': '你是一个有帮助的助手，请用中文回答用户问题。'}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DeepSeek Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ChatMessageWidget(message: _messages[index]);
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "AI正在输入中...",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    offset: const Offset(0, -1),
                    blurRadius: 3,
                  )
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: '输入消息...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                      ),
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FloatingActionButton(
                    onPressed: () => _handleSubmitted(_textController.text),
                    mini: true,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    // 添加用户消息到界面
    setState(() {
      _messages.add(ChatMessage(text: text, isAI: false));
      _isTyping = true;
    });

    _scrollToBottom();

    // 添加用户消息到历史记录
    _conversationHistory.add({'role': 'user', 'content': text});

    try {
      // 创建一个流控制器，用于流式接收AI回复
      final streamController = StreamController<String>();

      // 先添加一个空的AI消息，稍后会通过流更新
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "", // 初始为空
          isAI: true,
          streamController: streamController, // 传入流控制器
        ));
      });

      _scrollToBottom();

      // 启动流式请求
      String fullResponse = '';
      try {
        await for (String chunk in _deepSeekClient.streamChatCompletion(
          text,
          systemMessages: _conversationHistory
              .where((msg) => msg['role'] == 'system')
              .toList(),
        )) {
          // 添加新收到的文本到流
          streamController.add(chunk);
          fullResponse += chunk;

          // 确保滚动到底部，跟随新内容
          _scrollToBottom();
        }
      } finally {
        await streamController.close();
      }

      // 请求完成后，保存完整响应到历史记录
      _conversationHistory.add({'role': 'assistant', 'content': fullResponse});
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "抱歉，发生了错误：${e.toString()}",
          isAI: true,
        ));
      });

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
