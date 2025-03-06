这是一个基于 Flutter 构建的 AI 聊天应用，使用 DeepSeek API 提供智能对话能力，并通过流式响应实现打字机效果。

## 功能特点

- ✅ **实时打字效果**：AI 回复会以逐字显示的方式呈现，模拟真人打字体验
- ✅ **流式 API 集成**：使用 DeepSeek API 的流式响应功能，实现边生成边显示
- ✅ **多轮对话**：支持上下文记忆，实现连续对话体验
- ✅ **简洁 UI**：直观的聊天界面，区分用户和 AI 消息

## 技术实现

### 核心组件

1. **DeepSeekClient**：负责与 DeepSeek API 通信
   - 支持普通请求和流式请求
   - 处理认证和错误情况

2. **ChatMessage 与 ChatMessageWidget**：
   - 支持流式更新的消息组件
   - 通过 StreamController 接收实时字符流

3. **主界面**：
   - 用户输入处理
   - 消息历史记录管理
   - 自动滚动到最新消息

### 关键代码实现

#### 流式消息处理

```dart
// 创建流控制器接收 AI 响应
final streamController = StreamController<String>();

// 添加初始空消息
setState(() {
  _messages.add(ChatMessage(
    text: "",
    isAI: true,
    streamController: streamController,
  ));
});

// 处理流式响应
await for (String chunk in _deepSeekClient.streamChatCompletion(...)) {
  streamController.add(chunk);
  fullResponse += chunk;
}
```

#### 消息组件中的流监听

```dart
_subscription = widget.message.streamController!.stream.listen(
  (chunk) {
    setState(() {
      _displayText += chunk;
    });
  },
  onDone: () {
    print('流结束');
  },
);
```

#### DeepSeek API 流式调用

```dart
await for (final chunk in stream) {
  final String decodedChunk = utf8.decode(chunk);
  
  // 解析 SSE 格式数据
  if (line.startsWith('data: ')) {
    final Map<String, dynamic> jsonData = jsonDecode(jsonStr);
    final String content = jsonData['choices'][0]['delta']['content'];
    yield content;
  }
}
```

## 调试与问题解决

在开发过程中遇到并解决了以下问题：

1. **API 认证问题**：确保正确设置 Bearer Token
2. **流式数据解析**：处理 SSE 格式的数据流
3. **UI 更新**：确保 UI 在收到新字符时正确更新
4. **网络权限**：在 iOS 的 Info.plist 中添加网络请求权限
5. **乱码问题**：通过正确的 UTF-8 解码解决

## 未来改进方向

- [ ] 添加消息持久化存储
- [ ] 支持语音输入和语音播放
- [ ] 优化移动设备上的键盘交互
- [ ] 添加消息撤回功能
- [ ] 支持更多消息类型（图片、链接等）
- [ ] 添加设置页面，允许用户自定义 API 参数

## 开发环境

- Flutter 3.10.0+
- Dart 3.0.0+
- 依赖库：
  - dio: 用于 HTTP 请求
  - flutter: Flutter 框架

## 使用方法

1. 克隆仓库
2. 在 `config.dart` 中添加你的 DeepSeek API 密钥
3. 运行 `flutter pub get` 安装依赖
4. 运行 `flutter run` 启动应用

## 注意事项

- 确保有稳定的网络连接
- API 密钥应该妥善保管，不要提交到公开仓库
- 流式响应可能会占用更多的网络资源

---

这个项目展示了如何在 Flutter 应用中实现 AI 聊天功能，特别是如何通过流式响应实现打字机效果，提供更加自然的对话体验。