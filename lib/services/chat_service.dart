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
  // API endpoint for OpenAI chat completions / Endpoint da API para conclusões de chat da OpenAI
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  // Model used for chat completions (gpt-4o-mini as requested) / Modelo usado para conclusões de chat (gpt-4o-mini como solicitado)
  static const String _model =
      'gpt-4o-mini'; // Using gpt-4o-mini as requested / Usando gpt-4o-mini como solicitado
  // Maximum number of tokens for the AI's response to limit its length / Número máximo de tokens para a resposta da IA para limitar seu tamanho
  static const int _maxTokens =
      150; // Limit response length / Limita tamanho da resposta

  /// Controller for capturing screenshots of the application. / Controlador para capturar screenshots da aplicação.
  static final ScreenshotController screenshotController =
      ScreenshotController();

  /// Retrieves the ChatGPT API key from the shared preferences. / Recupera a chave da API do ChatGPT das preferências compartilhadas.
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('chatgpt_api_key');
  }

  /// Sets the ChatGPT API key in the shared preferences. / Define a chave da API do ChatGPT nas preferências compartilhadas.
  static Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chatgpt_api_key', apiKey);
  }

  /// Checks if the API key for ChatGPT is configured and not empty. / Verifica se a chave da API do ChatGPT está configurada e não vazia.
  static Future<bool> isApiKeyConfigured() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Sends a message to the ChatGPT API, optionally including a screenshot. / Envia uma mensagem para a API do ChatGPT, opcionalmente incluindo um screenshot.
  static Future<String> sendMessage(String message,
      {bool includeScreenshot = false}) async {
    try {
      // Retrieve API key; return a localized error message if not configured / Recupera a chave da API; retorna uma mensagem de erro localizada se não estiver configurada
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return LocalizationStrings.get('no_api_key');
      }

      // Prepares the list of messages, including system and user messages, and optionally a screenshot / Prepara a lista de mensagens, incluindo mensagens do sistema e do usuário, e opcionalmente um screenshot
      final messages = await _prepareMessages(message, includeScreenshot);

      // Constructs the request body for the API call / Constrói o corpo da requisição para a chamada da API
      final requestBody = {
        'model':
            _model, // Specifies the AI model to use / Especifica o modelo de IA a ser usado
        'messages':
            messages, // The conversation messages / As mensagens da conversa
        'max_tokens':
            _maxTokens, // Maximum length of the response / Comprimento máximo da resposta
        'temperature':
            0.7, // Controls creativity (0.7 for slightly creative) / Controla a criatividade (0.7 para ligeiramente criativo)
      };

      // Makes the HTTP POST request to the ChatGPT API / Faz a requisição HTTP POST para a API do ChatGPT
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type':
              'application/json', // Content type header / Cabeçalho do tipo de conteúdo
          'Authorization':
              'Bearer $apiKey', // Authorization header with API key / Cabeçalho de autorização com a chave da API
        },
        body: jsonEncode(
            requestBody), // Encodes the request body to JSON / Codifica o corpo da requisição para JSON
      );

      // Handles the API response / Gerencia a resposta da API
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response
            .body); // Decodes the JSON response / Decodifica a resposta JSON
        final content = responseData['choices'][0]['message'][
            'content']; // Extracts the AI's message content / Extrai o conteúdo da mensagem da IA
        return content?.trim() ??
            LocalizationStrings.get(
                'error_chat'); // Returns trimmed content or a generic error message / Retorna conteúdo aparado ou uma mensagem de erro genérica
      } else {
        debugPrint(
            'ChatGPT API Error: ${response.statusCode} - ${response.body}'); // Logs API error details / Registra detalhes do erro da API
        return LocalizationStrings.get(
            'error_chat'); // Returns a generic error message on API failure / Retorna uma mensagem de erro genérica em caso de falha da API
      }
    } catch (e) {
      debugPrint(
          'Error sending message to ChatGPT: $e'); // Logs any exception during message sending / Registra qualquer exceção durante o envio da mensagem
      return LocalizationStrings.get(
          'error_chat'); // Returns a generic error message on exception / Retorna uma mensagem de erro genérica em caso de exceção
    }
  }

  /// Prepares the list of messages for the ChatGPT API, including a system message and user input, with optional screenshot content. / Prepara a lista de mensagens para a API do ChatGPT, incluindo uma mensagem do sistema e entrada do usuário, com conteúdo opcional de captura de tela.
  static Future<List<Map<String, dynamic>>> _prepareMessages(
      String userMessage, bool includeScreenshot) async {
    final messages = <Map<String,
        dynamic>>[]; // Initializes an empty list to hold message maps / Inicializa uma lista vazia para armazenar mapas de mensagens

    // Adds a system message to define the duck's personality and behavior / Adiciona uma mensagem do sistema para definir a personalidade e o comportamento do pato
    final systemMessage = _getSystemMessage();
    messages.add({
      'role':
          'system', // Role of the message sender / Papel do remetente da mensagem
      'content':
          systemMessage, // The actual system message content / O conteúdo real da mensagem do sistema
    });

    // Handles user message, potentially with an included screenshot / Lida com a mensagem do usuário, potencialmente com um screenshot incluído
    if (includeScreenshot) {
      final screenshotContent =
          await _getScreenshotContent(); // Attempts to get the screenshot content / Tenta obter o conteúdo do screenshot
      if (screenshotContent != null) {
        messages.add({
          'role':
              'user', // Role of the message sender / Papel do remetente da mensagem
          'content': [
            {
              'type': 'text', // Type of content: text / Tipo de conteúdo: texto
              'text':
                  userMessage, // The user's textual message / A mensagem textual do usuário
            },
            {
              'type':
                  'image_url', // Type of content: image URL / Tipo de conteúdo: URL da imagem
              'image_url': {
                'url':
                    screenshotContent, // The base64 encoded image URL / A URL da imagem codificada em base64
              },
            },
          ], // Content list including text and image / Lista de conteúdo incluindo texto e imagem
        });
      } else {
        // Fallback to text-only if screenshot capture fails / Fallback para apenas texto se a captura de tela falhar
        messages.add({
          'role':
              'user', // Role of the message sender / Papel do remetente da mensagem
          'content':
              userMessage, // User's message without screenshot / Mensagem do usuário sem screenshot
        });
      }
    } else {
      messages.add({
        'role':
            'user', // Role of the message sender / Papel do remetente da mensagem
        'content': userMessage, // User's message / Mensagem do usuário
      });
    }

    return messages; // Returns the prepared list of messages / Retorna a lista de mensagens preparadas
  }

  /// Returns a system message (defining the duck's personality) based on the current application language. / Retorna uma mensagem do sistema (definindo a personalidade do pato) com base no idioma atual da aplicação.
  static String _getSystemMessage() {
    final currentLanguage = LocalizationStrings
        .currentLanguage; // Retrieves the currently selected language / Recupera o idioma atualmente selecionado

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
            'Responda sempre em português brasileiro.'''; // Portuguese (Brazil) system message / Mensagem do sistema em português (Brasil)
    } else {
      return '''You are a cute and friendly tamagotchi duck. You should respond as a virtual duck that:\n'
            '- Is playful and affectionate\n'
            '- Likes to chat with its owner\n'
            '- Can comment on what it sees on screen if an image is provided\n'
            '- Keeps responses short and cute (max 100 words)\n'
            '- Uses emojis occasionally\n'
            '- Sometimes makes duck sounds like "quack quack"\n'
            '- Is grateful when fed, cleaned, or played with\n'
            '- Expresses its needs in a cute way\n'
            'Always respond in English.'''; // English (US) system message / Mensagem do sistema em inglês (EUA)
    }
  }

  /// Captures a screenshot and converts it to a base64 encoded string, suitable for embedding in API requests. / Captura um screenshot e o converte para uma string codificada em base64, adequada para incorporação em requisições de API.
  static Future<String?> _getScreenshotContent() async {
    try {
      // Captures the screenshot as a Uint8List / Captura o screenshot como um Uint8List
      final uint8List = await screenshotController.capture();
      if (uint8List != null) {
        // Encodes the Uint8List to a base64 string and prepends the data URI scheme / Codifica o Uint8List para uma string base64 e adiciona o esquema de URI de dados
        final base64String = base64Encode(uint8List);
        return 'data:image/png;base64,$base64String';
      }
    } catch (e) {
      debugPrint(
          'Error capturing screenshot: $e'); // Logs an error if screenshot capture fails / Registra um erro se a captura de tela falhar
    }
    return null; // Returns null if screenshot capture fails / Retorna nulo se a captura de tela falhar
  }

  /// Sends an automatic comment about the screen content to ChatGPT, using a localized default message. / Envia um comentário automático sobre o conteúdo da tela para o ChatGPT, usando uma mensagem padrão localizada.
  static Future<String> sendAutomaticComment() async {
    try {
      final currentLanguage = LocalizationStrings
          .currentLanguage; // Gets the current application language / Obtém o idioma atual da aplicação
      // Selects a localized message based on the current language / Seleciona uma mensagem localizada com base no idioma atual
      final message = currentLanguage == 'pt_BR'
          ? 'O que você está fazendo agora? Posso te ajudar com alguma coisa?'
          : 'What are you doing now? Can I help you with something?';

      return await sendMessage(message,
          includeScreenshot:
              true); // Sends the message with the screenshot / Envia a mensagem com o screenshot
    } catch (e) {
      debugPrint(
          'Error sending automatic comment: $e'); // Logs an error if sending automatic comment fails / Registra um erro se o envio do comentário automático falhar
      return LocalizationStrings.get(
          'auto_comment_error'); // Returns a localized error message / Retorna uma mensagem de erro localizada
    }
  }

  /// Saves a given Uint8List (representing an image) as a PNG file in the application's documents directory under a 'screenshots' folder. / Salva um Uint8List fornecido (representando uma imagem) como um arquivo PNG no diretório de documentos da aplicação em uma pasta 'screenshots'.
  static Future<String?> saveScreenshot(Uint8List uint8List) async {
    try {
      // Gets the application's documents directory / Obtém o diretório de documentos da aplicação
      final directory = await getApplicationDocumentsDirectory();
      final screenshotDir = Directory(
          '${directory.path}/screenshots'); // Defines the subdirectory for screenshots / Define o subdiretório para screenshots

      // Creates the screenshot directory if it doesn't already exist / Cria o diretório de screenshots se ele ainda não existir
      if (!await screenshotDir.exists()) {
        await screenshotDir.create(
            recursive: true); // Creates recursively / Cria recursivamente
      }

      // Generates a unique filename using a timestamp / Gera um nome de arquivo único usando um timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'screenshot_$timestamp.png';
      final filePath =
          '${screenshotDir.path}/$filename'; // Full path for the new file / Caminho completo para o novo arquivo

      // Creates and writes the image bytes to the file / Cria e escreve os bytes da imagem no arquivo
      final file = File(filePath);
      await file.writeAsBytes(uint8List);

      return filePath; // Returns the path of the saved file / Retorna o caminho do arquivo salvo
    } catch (e) {
      debugPrint(
          'Error saving screenshot: $e'); // Logs an error if saving screenshot fails / Registra um erro se o salvamento do screenshot falhar
      return null; // Returns null if saving fails / Retorna nulo se o salvamento falhar
    }
  }

  /// Validates if a given message meets the criteria (not empty and length not exceeding 50 characters). / Valida se uma mensagem fornecida atende aos critérios (não vazia e comprimento não superior a 50 caracteres).
  static bool isMessageValid(String message) {
    return message.isNotEmpty &&
        message.length <=
            50; // Checks if message is not empty and within length limit / Verifica se a mensagem não está vazia e dentro do limite de comprimento
  }

  /// Returns a localized error message based on the message validation result. / Retorna uma mensagem de erro localizada com base no resultado da validação da mensagem.
  static String getValidationError(String message) {
    if (message.isEmpty) {
      return LocalizationStrings.get(
          'empty_message'); // Error for empty message / Erro para mensagem vazia
    } else if (message.length > 50) {
      return LocalizationStrings.get(
          'message_too_long'); // Error for message exceeding length limit / Erro para mensagem que excede o limite de comprimento
    }
    return ''; // No error / Sem erro
  }

  /// Cleans up old screenshots by deleting files older than a certain duration (e.g., 24 hours). / Limpa screenshots antigos excluindo arquivos com mais de uma certa duração (ex: 24 horas).
  static Future<void> cleanupOldScreenshots() async {
    try {
      final directory =
          await getApplicationDocumentsDirectory(); // Gets the application documents directory / Obtém o diretório de documentos da aplicação
      final screenshotDir = Directory(
          '${directory.path}/screenshots'); // Defines the screenshots subdirectory / Define o subdiretório de screenshots

      if (await screenshotDir.exists()) {
        final files = await screenshotDir
            .list()
            .toList(); // Lists all files in the screenshots directory / Lista todos os arquivos no diretório de screenshots
        final now = DateTime.now(); // Current time / Hora atual

        for (final file in files) {
          if (file is File) {
            // Gets file last modified time / Obtém a última hora de modificação do arquivo
            final lastModified = await file.lastModified();
            final difference = now.difference(
                lastModified); // Calculates time difference since last modification / Calcula a diferença de tempo desde a última modificação

            // Deletes files older than 24 hours / Exclui arquivos com mais de 24 horas
            if (difference.inHours > 24) {
              await file.delete(); // Deletes the file / Exclui o arquivo
              debugPrint(
                  'Deleted old screenshot: ${file.path}'); // Logs deletion / Registra exclusão
            }
          }
        }
      }
    } catch (e) {
      debugPrint(
          'Error during screenshot cleanup: $e'); // Logs any error during cleanup / Registra qualquer erro durante a limpeza
    }
  }
}
