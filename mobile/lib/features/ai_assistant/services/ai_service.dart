import '../../../core/network/api_client.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  const ChatMessage(
      {required this.text, required this.isUser, this.isError = false});
}

class AiService {
  Future<String> sendMessage(
      {required String userMessage, required List<ChatMessage> history}) async {
    final result = await ApiClient().request('/api/ai/chat',
        method: 'POST', body: {'message': userMessage});
    return result['text'] as String;
  }
}
