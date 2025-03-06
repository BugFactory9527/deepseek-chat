import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

class DeepSeekClient {
  final Dio _dio = Dio();
  final String _apiKey;

  // DeepSeek API 端点
  static const String _baseUrl = 'https://api.deepseek.com';

  DeepSeekClient(this._apiKey) {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    // 默认响应类型设为JSON (非流式时使用)
    _dio.options.responseType = ResponseType.json;

    // 添加日志拦截器以便调试
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (log) => print('DEEPSEEK LOG: $log'),
    ));
  }

  // 普通的非流式请求
  Future<String> chatCompletion(
    String userMessage, {
    String model = 'deepseek-chat',
    double temperature = 0.7,
    int maxTokens = 1000,
    List<Map<String, dynamic>>? systemMessages,
  }) async {
    try {
      // 构建消息列表
      final List<Map<String, dynamic>> messages = [];

      // 添加系统消息（如果提供的话）
      if (systemMessages != null && systemMessages.isNotEmpty) {
        messages.addAll(systemMessages);
      }

      // 添加用户消息
      messages.add({'role': 'user', 'content': userMessage});

      print('发送请求到 DeepSeek API: ${jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': temperature,
            'max_tokens': maxTokens,
          })}');

      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        },
      );

      print('收到响应: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('响应数据: ${response.data}');

        // 根据 DeepSeek API 文档解析响应
        final choices = response.data['choices'] as List;
        if (choices.isNotEmpty) {
          return choices[0]['message']['content'] as String;
        } else {
          return '未获取到响应内容';
        }
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Dio错误: ${e.message}');
      if (e.response != null) {
        print('错误响应: ${e.response?.data}');
      }
      throw Exception('API 调用失败: ${e.message}');
    } catch (e) {
      print('其他错误: $e');
      throw Exception('API 调用失败: $e');
    }
  }

  // 改进的流式响应方法
  Stream<String> streamChatCompletion(
    String userMessage, {
    String model = 'deepseek-chat',
    double temperature = 0.7,
    int maxTokens = 1000,
    List<Map<String, dynamic>>? systemMessages,
  }) async* {
    final responseStream = StreamController<String>();

    try {
      final List<Map<String, dynamic>> messages = [];

      if (systemMessages != null && systemMessages.isNotEmpty) {
        messages.addAll(systemMessages);
      }

      messages.add({'role': 'user', 'content': userMessage});

      print('开始发送流式请求');

      // 设置流式响应
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': true, // 启用流式响应
        },
        options: Options(
          responseType: ResponseType.stream,
          // 添加特定的请求头
          headers: {
            'Accept': 'text/event-stream',
          },
        ),
      );

      print('获取到流响应');

      final responseData = response.data as ResponseBody;
      final Stream<List<int>> stream = responseData.stream;

      String buffer = '';

      await for (final chunk in stream) {
        // 将字节转换为字符串
        final String decodedChunk = utf8.decode(chunk);
        print('收到流数据块: $decodedChunk');

        buffer += decodedChunk;

        // 处理可能包含多个SSE事件的数据
        final List<String> lines = buffer.split('\n');

        // 保留最后一个可能不完整的行
        buffer = lines.last;

        // 处理所有完整的行
        for (var i = 0; i < lines.length - 1; i++) {
          final String line = lines[i];

          if (line.startsWith('data: ')) {
            if (line.contains('[DONE]')) {
              print('流式传输完成');
              continue;
            }

            try {
              final String jsonStr = line.substring(6);
              print('解析JSON: $jsonStr');

              final Map<String, dynamic> jsonData = jsonDecode(jsonStr);

              if (jsonData['choices'] != null &&
                  jsonData['choices'].isNotEmpty &&
                  jsonData['choices'][0]['delta'] != null &&
                  jsonData['choices'][0]['delta']['content'] != null) {
                final String content =
                    jsonData['choices'][0]['delta']['content'];
                print('生成内容: $content');
                yield content;
              }
            } catch (e) {
              print('JSON解析错误: $e');
              continue;
            }
          }
        }
      }
    } on DioException catch (e) {
      print('流式请求Dio错误: ${e.message}');
      if (e.response != null) {
        print('流式请求错误响应: ${e.response?.data}');
      }
      throw Exception('流式API调用失败: ${e.message}');
    } catch (e) {
      print('流式请求其他错误: $e');
      throw Exception('流式API调用失败: $e');
    }
  }
}
