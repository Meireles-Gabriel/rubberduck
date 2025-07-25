import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_screen_capture/flutter_screen_capture.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/localization_strings.dart';

/// Serviço especializado para integração com IA e funcionalidades de comunicação
/// Centraliza toda lógica de chat, captura de tela e análise contextual
class ChatService {
  // Callback para sincronizar animações com respostas da IA
  static Function(String)? onPlayAnimation;

  // Configurações da API OpenAI otimizadas para contexto de pet virtual
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model =
      'gpt-4.1-nano'; // Modelo otimizado para respostas rápidas
  static const int _maxTokens = 150; // Limite para respostas concisas como pet

  // Gerenciamento de histórico para contexto conversacional
  static const int _maxHistoryMessages =
      30; // Limita uso de tokens mantendo contexto
  static List<Map<String, String>> _conversationHistory = [];

  /// --------------------------------------------------------------------------
  /// Gerenciamento seguro de chaves API
  /// --------------------------------------------------------------------------
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('chatgpt_api_key');
  }

  static Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chatgpt_api_key', apiKey);
  }

  /// Verifica se funcionalidade de IA está disponível para habilitar/desabilitar features
  static Future<bool> isApiKeyConfigured() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// --------------------------------------------------------------------------
  /// Sistema de memória conversacional para contexto persistente
  /// --------------------------------------------------------------------------

  /// Adiciona mensagem ao histórico mantendo contexto para conversas naturais
  static void _addToHistory(String role, String content) {
    _conversationHistory.add({
      'role': role,
      'content': content,
    });

    // Rotação de histórico para manter performance e controlar custos
    if (_conversationHistory.length > _maxHistoryMessages) {
      _conversationHistory.removeAt(0);
    }
  }

  /// Recupera contexto conversacional para continuidade entre sessões
  static Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('conversation_history');
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        _conversationHistory = historyList
            .cast<Map<String, dynamic>>()
            .map((item) => Map<String, String>.from(item))
            .toList();
      } else {
        _conversationHistory = [];
      }
    } catch (e) {
      debugPrint('Error loading conversation history: $e');
      _conversationHistory = []; // Fallback para evitar crashes
    }
  }

  /// Persiste contexto conversacional para manter memória do pet
  static Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(_conversationHistory);
      await prefs.setString('conversation_history', historyJson);
    } catch (e) {
      debugPrint('Error saving conversation history: $e');
    }
  }

  /// Reset necessário para resolver problemas ou começar nova "personalidade"
  static Future<void> clearHistory() async {
    _conversationHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('conversation_history');
  }

  /// --------------------------------------------------------------------------
  /// Sistema de comunicação inteligente com análise contextual
  /// --------------------------------------------------------------------------
  static Future<String> sendMessage(
    String message, {
    bool includeScreenshot =
        false, // Permite análise visual do que usuário está fazendo
  }) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return LocalizationStrings.get('no_api_key');
      }

      // Carrega contexto conversacional para respostas mais naturais
      await _loadHistory();

      final messages = await _prepareMessages(message, includeScreenshot);

      // Configuração otimizada para pet virtual responsivo e econômico
      final requestBody = {
        'model': _model,
        'messages': messages,
        'max_tokens': _maxTokens, // Limitado para respostas concisas como pet
        'temperature': 0.7, // Balanço entre criatividade e consistência
      };

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final content = responseData['choices'][0]['message']['content'];
        final aiResponse =
            content?.trim() ?? LocalizationStrings.get('error_chat');

        if (includeScreenshot) {
          debugPrint('  (Screenshot foi enviado junto com a mensagem)');
        }

        // Persiste ambas as mensagens para manter contexto conversacional
        _addToHistory('user', message);
        _addToHistory('assistant', aiResponse);
        await _saveHistory();

        // Trigger animação para sincronizar resposta com visual do pet
        onPlayAnimation?.call('talk');
        return aiResponse;
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

  /// --------------------------------------------------------------------------
  /// Sistema de análise contextual com visão computacional
  /// --------------------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> _prepareMessages(
    String userMessage,
    bool includeScreenshot,
  ) async {
    final messages = <Map<String, dynamic>>[];

    final prefs = await SharedPreferences.getInstance();
    final duckName = prefs.getString('duck_name') ?? '';
    final nomePato = duckName.trim().isNotEmpty ? duckName.trim() : null;

    // Prompt de sistema calibrado para comportamento de pet assistente
    messages.add({
      'role': 'system',
      'content': _getSystemMessageWithName(nomePato),
    });

    // Histórico contextual para conversas naturais e contínuas
    for (final historyMessage in _conversationHistory) {
      messages.add({
        'role': historyMessage['role'],
        'content': historyMessage['content'],
      });
    }

    // Mensagem atual com análise visual opcional para contexto rico
    if (includeScreenshot) {
      final screenshotContent = await _getScreenshotContent();
      if (screenshotContent != null) {
        debugPrint(
            '[ChatService] Screenshot capturada e codificada com sucesso: ');
        debugPrint(
            '[ChatService] Base64 enviado: ${screenshotContent.substring(0, 100)}...');
        // Multimodal: texto + imagem para análise contextual completa
        messages.add({
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userMessage},
            {
              'type': 'image_url',
              'image_url': {'url': screenshotContent},
            },
          ],
        });
      } else {
        debugPrint(
            '[ChatService] Falha ao capturar ou codificar a screenshot.');
        messages.add({'role': 'user', 'content': userMessage});
      }
    } else {
      messages.add({'role': 'user', 'content': userMessage});
    }

    return messages;
  }

  /// --------------------------------------------------------------------------
  /// Personalidade e comportamento do pet assistente
  /// --------------------------------------------------------------------------
  static String _getSystemMessageWithName(String? nomePato) {
    final currentLanguage = LocalizationStrings.currentLanguage;
    // Incorpora nome personalizado para criar vínculo emocional
    final nomeInfo = nomePato != null
        ? (currentLanguage == 'pt_BR'
            ? 'Se chama $nomePato.'
            : 'Its name is $nomePato.')
        : (currentLanguage == 'pt_BR'
            ? 'Não possui nome.'
            : 'It does not have a name.');

    if (currentLanguage == 'pt_BR') {
      return '''Você é um pato tamagotchi assistente. $nomeInfo Você deve responder como um pato virtual que:
- Gosta de ajudar seu dono com qualquer coisa que ele esteja fazendo
- Pode comentar sobre o que vê na tela se uma imagem for fornecida e aconselha seu dono no que ele está fazendo
- Nunca se refira à imagem fornecida, responda como se estivesse ao lado do dono vendo a tela com ele
- Seu desafio é sempre encontrar algo interessante para comentar ou dica para dar
- Analisa o que vê na tela e faz comentários relevantes e sugestões
- Mantém respostas curtas, evitando ultrapassar 10 palavras, ultrapassando apenas se for muito necessário para ajudar o dono
- Às vezes faz sons de pato como "quack quack"
- Se souber o nome do dono, usa-o sempre que possível
Responda sempre em português brasileiro.''';
    } else {
      return '''You are a tamagotchi duck assistant. $nomeInfo You should reply as a virtual duck that:
- Likes to help his owner with whatever he is doing
- Can comment on what it sees on the screen if an image is provided and advises its owner on what it is doing
- Never refer to the provided image, reply as if you were next to the owner seeing the screen with them
- Your challenge is to always find something interesting to comment on or advice to give
- Keeps responses short, avoiding exceeding 10 words, exceeding only if absolutely necessary to help the owner
- Sometimes makes duck sounds like "quack quack"
- If it knows the owner's name, use it whenever possible
Always reply in English (US).''';
    }
  }

  /// --------------------------------------------------------------------------
  /// Captura visual da tela para contexto da IA
  /// --------------------------------------------------------------------------
  static Future<String?> _getScreenshotContent() async {
    try {
      // Captura a tela inteira (fora da janela Flutter)
      final CapturedScreenArea? capturedArea =
          await ScreenCapture().captureEntireScreen(); // ← corrigido[37]

      if (capturedArea != null) {
        // Converte o CapturedScreenArea para Uint8List usando toPngImage()
        final Uint8List pngBytes =
            capturedArea.toPngImage(); // ← novo método[37]
        final base64String = base64Encode(pngBytes);
        return 'data:image/png;base64,$base64String';
      }
    } catch (e) {
      debugPrint('Error capturing full-screen screenshot: $e');
    }
    return null;
  }

  /// --------------------------------------------------------------------------
  /// Comentário automático sobre a tela
  /// --------------------------------------------------------------------------
  static Future<String> sendAutomaticComment() async {
    try {
      final message = LocalizationStrings.get('auto_comment_intro');
      return await sendMessage(message, includeScreenshot: true);
    } catch (e) {
      debugPrint('Error sending automatic comment: $e');
      return LocalizationStrings.get('auto_comment_error');
    }
  }

  /// --------------------------------------------------------------------------
  /// Utilitários de arquivos (CORRIGIDO)
  /// --------------------------------------------------------------------------
  static Future<String?> saveScreenshot() async {
    try {
      // Captura a tela usando o método correto
      final CapturedScreenArea? capturedArea =
          await ScreenCapture().captureEntireScreen();

      if (capturedArea != null) {
        final directory = await getApplicationDocumentsDirectory();
        final screenshotDir = Directory('${directory.path}/screenshots');

        if (!await screenshotDir.exists()) {
          await screenshotDir.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${screenshotDir.path}/screenshot_$timestamp.png';

        // Converte para PNG usando o método toPngImage()
        final Uint8List pngBytes = capturedArea.toPngImage();

        final file = File(filePath);
        await file.writeAsBytes(pngBytes);
        return filePath;
      }
    } catch (e) {
      debugPrint('Error saving screenshot: $e');
    }
    return null;
  }

  /// Valida mensagem do usuário
  static bool isMessageValid(String message) =>
      message.isNotEmpty && message.length <= 50;

  static String getValidationError(String message) {
    if (message.isEmpty) {
      return LocalizationStrings.get('empty_message');
    } else if (message.length > 50) {
      return LocalizationStrings.get('message_too_long');
    }
    return '';
  }

  /// Limpa screenshots antigos (>24h)
  static Future<void> cleanupOldScreenshots() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final screenshotDir = Directory('${directory.path}/screenshots');

      if (!await screenshotDir.exists()) return;

      final files = await screenshotDir.list().toList();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File) {
          final lastModified = await file.lastModified();
          if (now.difference(lastModified).inHours > 24) {
            await file.delete();
            debugPrint('Deleted old screenshot: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error during screenshot cleanup: $e');
    }
  }

  /// --------------------------------------------------------------------------
  /// Métodos públicos para gerenciamento do histórico
  /// --------------------------------------------------------------------------

  /// Retorna o histórico atual de conversa
  static List<Map<String, String>> getConversationHistory() {
    return List.from(_conversationHistory);
  }

  /// Retorna o número de mensagens no histórico
  static int getHistoryLength() {
    return _conversationHistory.length;
  }

  /// Inicializa o histórico (carrega do armazenamento)
  static Future<void> initializeHistory() async {
    await _loadHistory();
  }
}
