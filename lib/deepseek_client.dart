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

    // 可选：添加日志拦截器以便调试
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (log) => print(log.toString()),
    ));
  }

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

      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        },
      );

      if (response.statusCode == 200) {
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
      // 处理 Dio 特定的错误
      if (e.response != null) {
        final errorData = e.response!.data;
        throw Exception(
            'API 错误: ${errorData['error']['message'] ?? errorData.toString()}');
      } else {
        throw Exception('网络错误: ${e.message}');
      }
    } catch (e) {
      throw Exception('请求过程中发生错误: $e');
    }
  }
}
