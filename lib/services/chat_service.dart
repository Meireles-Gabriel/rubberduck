import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../utils/localization_strings.dart';

/// ChatGPT integration service / Serviço de integração com ChatGPT
class ChatService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model =
      'gpt-4o-mini'; // Using gpt-4o-mini as requested / Usando gpt-4o-mini como solicitado
  static const int _maxTokens =
      150; // Limit response length / Limita tamanho da resposta

  /// Screenshot controller / Controlador de screenshot
  static final ScreenshotController screenshotController =
      ScreenshotController();

  /// Get API key from preferences / Obtém chave API das preferências
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('chatgpt_api_key');
  }

  /// Set API key in preferences / Define chave API nas preferências
  static Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chatgpt_api_key', apiKey);
  }

  /// Check if API key is configured / Verifica se chave API está configurada
  static Future<bool> isApiKeyConfigured() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Send message to ChatGPT / Envia mensagem para ChatGPT
  static Future<String> sendMessage(String message,
      {bool includeScreenshot = false}) async {
    try {
      // Check if API key is configured / Verifica se chave API está configurada
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return LocalizationStrings.get('no_api_key');
      }

      // Prepare messages / Prepara mensagens
      final messages = await _prepareMessages(message, includeScreenshot);

      // Prepare request body / Prepara corpo da requisição
      final requestBody = {
        'model': _model,
        'messages': messages,
        'max_tokens': _maxTokens,
        'temperature':
            0.7, // Slightly creative responses / Respostas ligeiramente criativas
      };

      // Make HTTP request / Faz requisição HTTP
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      // Handle response / Gerencia resposta
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final content = responseData['choices'][0]['message']['content'];
        return content?.trim() ?? LocalizationStrings.get('error_chat');
      } else {
        debugPrint(
            'ChatGPT API Error: ${response.statusCode} - ${response.body}');
        return LocalizationStrings.get('error_chat');
      }
    } catch (e) {
      debugPrint('Error sending message to ChatGPT: $e');
      return LocalizationStrings.get('error_chat');
    }
  }

  /// Prepare messages for ChatGPT API / Prepara mensagens para API do ChatGPT
  static Future<List<Map<String, dynamic>>> _prepareMessages(
      String userMessage, bool includeScreenshot) async {
    final messages = <Map<String, dynamic>>[];

    // System message to define duck personality / Mensagem do sistema para definir personalidade do pato
    final systemMessage = _getSystemMessage();
    messages.add({
      'role': 'system',
      'content': systemMessage,
    });

    // User message / Mensagem do usuário
    if (includeScreenshot) {
      final screenshotContent = await _getScreenshotContent();
      if (screenshotContent != null) {
        messages.add({
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': userMessage,
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': screenshotContent,
              },
            },
          ],
        });
      } else {
        // Fallback to text-only if screenshot fails / Fallback para apenas texto se screenshot falhar
        messages.add({
          'role': 'user',
          'content': userMessage,
        });
      }
    } else {
      messages.add({
        'role': 'user',
        'content': userMessage,
      });
    }

    return messages;
  }

  /// Get system message based on current language / Obtém mensagem do sistema baseada no idioma atual
  static String _getSystemMessage() {
    final currentLanguage = LocalizationStrings.currentLanguage;

    if (currentLanguage == 'pt_BR') {
      return '''Você é um pato tamagotchi fofo e amigável. Você deve responder como um pato virtual que:
- É brincalhão e carinhoso
- Gosta de conversar com seu dono
- Pode comentar sobre o que vê na tela se uma imagem for fornecida
- Mantém respostas curtas e fofas (máximo 100 palavras)
- Usa emojis ocasionalmente
- Às vezes faz sons de pato como "quack quack"
- É grato quando é alimentado, limpo ou quando brincam com ele
- Expressa suas necessidades de forma fofa
Responda sempre em português brasileiro.''';
    } else {
      return '''You are a cute and friendly tamagotchi duck. You should respond as a virtual duck that:
- Is playful and affectionate
- Likes to chat with its owner
- Can comment on what it sees on screen if an image is provided
- Keeps responses short and cute (max 100 words)
- Uses emojis occasionally
- Sometimes makes duck sounds like "quack quack"
- Is grateful when fed, cleaned, or played with
- Expresses its needs in a cute way
Always respond in English.''';
    }
  }

  /// Get screenshot content as base64 / Obtém conteúdo do screenshot como base64
  static Future<String?> _getScreenshotContent() async {
    try {
      // Take screenshot / Tira screenshot
      final uint8List = await screenshotController.capture();
      if (uint8List != null) {
        // Convert to base64 / Converte para base64
        final base64String = base64Encode(uint8List);
        return 'data:image/png;base64,$base64String';
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
    }
    return null;
  }

  /// Send automatic comment about screen / Envia comentário automático sobre a tela
  static Future<String> sendAutomaticComment() async {
    try {
      final currentLanguage = LocalizationStrings.currentLanguage;
      final message = currentLanguage == 'pt_BR'
          ? 'O que você está fazendo agora? Posso te ajudar com alguma coisa?'
          : 'What are you doing now? Can I help you with something?';

      return await sendMessage(message, includeScreenshot: true);
    } catch (e) {
      debugPrint('Error sending automatic comment: $e');
      return LocalizationStrings.get('auto_comment_error');
    }
  }

  /// Save screenshot to file / Salva screenshot em arquivo
  static Future<String?> saveScreenshot(Uint8List uint8List) async {
    try {
      // Get documents directory / Obtém diretório de documentos
      final directory = await getApplicationDocumentsDirectory();
      final screenshotDir = Directory('${directory.path}/screenshots');

      // Create directory if it doesn't exist / Cria diretório se não existir
      if (!await screenshotDir.exists()) {
        await screenshotDir.create(recursive: true);
      }

      // Generate filename / Gera nome do arquivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'screenshot_$timestamp.png';
      final filePath = '${screenshotDir.path}/$filename';

      // Save file / Salva arquivo
      final file = File(filePath);
      await file.writeAsBytes(uint8List);

      return filePath;
    } catch (e) {
      debugPrint('Error saving screenshot: $e');
      return null;
    }
  }

  /// Validate message length / Valida tamanho da mensagem
  static bool isMessageValid(String message) {
    return message.isNotEmpty && message.length <= 50;
  }

  /// Get validation error message / Obtém mensagem de erro de validação
  static String getValidationError(String message) {
    if (message.isEmpty) {
      return LocalizationStrings.get('empty_message');
    } else if (message.length > 50) {
      return LocalizationStrings.get('message_too_long');
    }
    return '';
  }

  /// Clean up old screenshots / Limpa screenshots antigos
  static Future<void> cleanupOldScreenshots() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final screenshotDir = Directory('${directory.path}/screenshots');

      if (await screenshotDir.exists()) {
        final files = await screenshotDir.list().toList();
        final now = DateTime.now();

        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            final age = now.difference(stat.modified).inDays;

            // Delete screenshots older than 7 days / Deleta screenshots com mais de 7 dias
            if (age > 7) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old screenshots: $e');
    }
  }
}
