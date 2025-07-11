import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../utils/localization_strings.dart';

/// Serviço de integração com ChatGPT
class ChatService {
  // API endpoint for OpenAI chat completions
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  // Modelo usado para conclusões de chat (gpt-4o-mini como solicitado)
  static const String _model =
      'gpt-4.1-nano'; // Usando gpt-4.1-nano
  // Número máximo de tokens para a resposta da IA para limitar seu tamanho
  static const int _maxTokens = 150; // Limita tamanho da resposta

  /// Controlador para capturar screenshots da aplicação.
  static final ScreenshotController screenshotController =
      ScreenshotController();

  /// Recupera a chave da API do ChatGPT das preferências compartilhadas.
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('chatgpt_api_key');
  }

  /// Define a chave da API do ChatGPT nas preferências compartilhadas.
  static Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chatgpt_api_key', apiKey);
  }

  /// Verifica se a chave da API do ChatGPT está configurada e não vazia.
  static Future<bool> isApiKeyConfigured() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Envia uma mensagem para a API do ChatGPT, opcionalmente incluindo um screenshot.
  static Future<String> sendMessage(String message,
      {bool includeScreenshot = false}) async {
    try {
      // Recupera a chave da API; retorna uma mensagem de erro localizada se não estiver configurada
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return LocalizationStrings.get('no_api_key');
      }

      // Prepara a lista de mensagens, incluindo mensagens do sistema e do usuário, e opcionalmente um screenshot
      final messages = await _prepareMessages(message, includeScreenshot);

      // Constrói o corpo da requisição para a chamada da API
      final requestBody = {
        'model': _model, // Especifica o modelo de IA a ser usado
        'messages': messages, // As mensagens da conversa
        'max_tokens': _maxTokens, // Comprimento máximo da resposta
        'temperature':
            0.7, // Controla a criatividade (0.7 para ligeiramente criativo)
      };

      // Faz a requisição HTTP POST para a API do ChatGPT
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json', // Cabeçalho do tipo de conteúdo
          'Authorization':
              'Bearer $apiKey', // Cabeçalho de autorização com a chave da API
        },
        body:
            jsonEncode(requestBody), // Codifica o corpo da requisição para JSON
      );

      // Gerencia a resposta da API
      if (response.statusCode == 200) {
        final responseData =
            jsonDecode(response.body); // Decodifica a resposta JSON
        final content = responseData['choices'][0]['message']
            ['content']; // Extrai o conteúdo da mensagem da IA
        return content?.trim() ??
            LocalizationStrings.get(
                'error_chat'); // Retorna conteúdo aparado ou uma mensagem de erro genérica
      } else {
        debugPrint(
            'ChatGPT API Error: ${response.statusCode} - ${response.body}'); // Registra detalhes do erro da API
        return LocalizationStrings.get(
            'error_chat'); // Retorna uma mensagem de erro genérica em caso de falha da API
      }
    } catch (e) {
      debugPrint(
          'Error sending message to ChatGPT: $e'); // Registra qualquer exceção durante o envio da mensagem
      return LocalizationStrings.get(
          'error_chat'); // Retorna uma mensagem de erro genérica em caso de exceção
    }
  }

  /// Prepara a lista de mensagens para a API do ChatGPT, incluindo uma mensagem do sistema e entrada do usuário, com conteúdo opcional de captura de tela.
  static Future<List<Map<String, dynamic>>> _prepareMessages(
      String userMessage, bool includeScreenshot) async {
    final messages = <Map<String,
        dynamic>>[]; // Inicializa uma lista vazia para armazenar mapas de mensagens

    // Adiciona uma mensagem do sistema para definir a personalidade e o comportamento do pato
    final systemMessage = _getSystemMessage();
    messages.add({
      'role': 'system', // Papel do remetente da mensagem
      'content': systemMessage, // O conteúdo real da mensagem do sistema
    });

    // Lida com a mensagem do usuário, potencialmente com um screenshot incluído
    if (includeScreenshot) {
      final screenshotContent =
          await _getScreenshotContent(); // Tenta obter o conteúdo do screenshot
      if (screenshotContent != null) {
        messages.add({
          'role': 'user', // Papel do remetente da mensagem
          'content': [
            {
              'type': 'text', // Tipo de conteúdo: texto
              'text': userMessage, // A mensagem textual do usuário
            },
            {
              'type': 'image_url', // Tipo de conteúdo: URL da imagem
              'image_url': {
                'url':
                    screenshotContent, // A URL da imagem codificada em base64
              },
            },
          ], // Lista de conteúdo incluindo texto e imagem
        });
      } else {
        // Fallback para apenas texto se a captura de tela falhar
        messages.add({
          'role': 'user', // Papel do remetente da mensagem
          'content': userMessage, // Mensagem do usuário sem screenshot
        });
      }
    } else {
      messages.add({
        'role': 'user', // Papel do remetente da mensagem
        'content': userMessage, // Mensagem do usuário
      });
    }

    return messages; // Retorna a lista de mensagens preparadas
  }

  /// Retorna uma mensagem do sistema (definindo a personalidade do pato) com base no idioma atual da aplicação.
  static String _getSystemMessage() {
    final currentLanguage = LocalizationStrings
        .currentLanguage; // Recupera o idioma atualmente selecionado

    if (currentLanguage == 'pt_BR') {
      return '''Você é um pato tamagotchi fofo e amigável. Você deve responder como um pato virtual que:\n'
            '- É brincalhão e carinhoso\n'
            '- Gosta de conversar com seu dono\n'
            '- Pode comentar sobre o que vê na tela se uma imagem for fornecida\n'
            '- Mantém respostas curtas e fofas (máximo 100 palavras)\n'
            '- Usa emojis ocasionalmente\n'
            '- Às vezes faz sons de pato como "quack quack"\n'
            '- É grato quando é alimentado, limpo ou quando brincam com ele\n'
            '- Expressa suas necessidades de forma fofa\n'
            'Responda sempre em português brasileiro.'''; // Mensagem do sistema em português (Brasil)
    } else {
      return '''Você é um pato tamagotchi fofo e amigável. Você deve responder como um pato virtual que:\n'
            '- É brincalhão e carinhoso\n'
            '- Gosta de conversar com seu dono\n'
            '- Pode comentar sobre o que vê na tela se uma imagem for fornecida\n'
            '- Mantém respostas curtas e fofas (máximo 100 palavras)\n'
            '- Usa emojis ocasionalmente\n'
            '- Às vezes faz sons de pato como "quack quack"\n'
            '- É grato quando é alimentado, limpo ou quando brincam com ele\n'
            '- Expressa suas necessidades de forma fofa\n'
            'Responda sempre em português brasileiro.'''; // Mensagem do sistema em português (Brasil)
    }
  }

  /// Captura um screenshot e o converte para uma string codificada em base64, adequada para incorporação em requisições de API.
  static Future<String?> _getScreenshotContent() async {
    try {
      // Captura o screenshot como um Uint8List
      final uint8List = await screenshotController.capture();
      if (uint8List != null) {
        // Codifica o Uint8List para uma string base64 e adiciona o esquema de URI de dados
        final base64String = base64Encode(uint8List);
        return 'data:image/png;base64,$base64String';
      }
    } catch (e) {
      debugPrint(
          'Error capturing screenshot: $e'); // Registra um erro se a captura de tela falhar
    }
    return null; // Retorna nulo se a captura de tela falhar
  }

  /// Envia um comentário automático sobre o conteúdo da tela para o ChatGPT, usando uma mensagem padrão localizada.
  static Future<String> sendAutomaticComment() async {
    try {
      final currentLanguage = LocalizationStrings
          .currentLanguage; // Obtém o idioma atual da aplicação
      // Seleciona uma mensagem localizada com base no idioma atual
      final message = currentLanguage == 'pt_BR'
          ? 'O que você está fazendo agora? Posso te ajudar com alguma coisa?'
          : 'O que você está fazendo agora? Posso te ajudar com alguma coisa?';

      return await sendMessage(message,
          includeScreenshot: true); // Envia a mensagem com o screenshot
    } catch (e) {
      debugPrint(
          'Error sending automatic comment: $e'); // Registra um erro se o envio do comentário automático falhar
      return LocalizationStrings.get(
          'auto_comment_error'); // Retorna uma mensagem de erro localizada
    }
  }

  /// Salva um Uint8List fornecido (representando uma imagem) como um arquivo PNG no diretório de documentos da aplicação em uma pasta 'screenshots'.
  static Future<String?> saveScreenshot(Uint8List uint8List) async {
    try {
      // Obtém o diretório de documentos da aplicação
      final directory = await getApplicationDocumentsDirectory();
      final screenshotDir = Directory(
          '${directory.path}/screenshots'); // Define o subdiretório para screenshots

      // Cria o diretório de screenshots se ele ainda não existir
      if (!await screenshotDir.exists()) {
        await screenshotDir.create(recursive: true); // Cria recursivamente
      }

      // Gera um nome de arquivo único usando um timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'screenshot_$timestamp.png';
      final filePath =
          '${screenshotDir.path}/$filename'; // Caminho completo para o novo arquivo

      // Cria e escreve os bytes da imagem no arquivo
      final file = File(filePath);
      await file.writeAsBytes(uint8List);

      return filePath; // Retorna o caminho do arquivo salvo
    } catch (e) {
      debugPrint(
          'Error saving screenshot: $e'); // Registra um erro se o salvamento do screenshot falhar
      return null; // Retorna nulo se o salvamento falhar
    }
  }

  /// Valida se uma mensagem fornecida atende aos critérios (não vazia e comprimento não superior a 50 caracteres).
  static bool isMessageValid(String message) {
    return message.isNotEmpty &&
        message.length <=
            50; // Verifica se a mensagem não está vazia e dentro do limite de comprimento
  }

  /// Retorna uma mensagem de erro localizada com base no resultado da validação da mensagem.
  static String getValidationError(String message) {
    if (message.isEmpty) {
      return LocalizationStrings.get(
          'empty_message'); // Erro para mensagem vazia
    } else if (message.length > 50) {
      return LocalizationStrings.get(
          'message_too_long'); // Erro para mensagem que excede o limite de comprimento
    }
    return ''; // Sem erro
  }

  /// Limpa screenshots antigos excluindo arquivos com mais de uma certa duração (ex: 24 horas).
  static Future<void> cleanupOldScreenshots() async {
    try {
      final directory =
          await getApplicationDocumentsDirectory(); // Obtém o diretório de documentos da aplicação
      final screenshotDir = Directory(
          '${directory.path}/screenshots'); // Define o subdiretório de screenshots

      if (await screenshotDir.exists()) {
        final files = await screenshotDir
            .list()
            .toList(); // Lista todos os arquivos no diretório de screenshots
        final now = DateTime.now(); // Hora atual

        for (final file in files) {
          if (file is File) {
            // Obtém a última hora de modificação do arquivo
            final lastModified = await file.lastModified();
            final difference = now.difference(
                lastModified); // Calcula a diferença de tempo desde a última modificação

            // Exclui arquivos com mais de 24 horas
            if (difference.inHours > 24) {
              await file.delete(); // Exclui o arquivo
              debugPrint(
                  'Deleted old screenshot: ${file.path}'); // Registra exclusão
            }
          }
        }
      }
    } catch (e) {
      debugPrint(
          'Error during screenshot cleanup: $e'); // Registra qualquer erro durante a limpeza
    }
  }
}
