import 'package:shared_preferences/shared_preferences.dart';

/// Localization strings for the app / Strings de localização para o app
class LocalizationStrings {
  static String _currentLanguage = 'en_US';
  static SharedPreferences? _prefs;

  /// Initialize localization / Inicializa a localização
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _currentLanguage = _prefs?.getString('language') ?? 'en_US';
  }

  /// Set language / Define idioma
  static Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    await _prefs?.setString('language', language);
  }

  /// Get current language / Obtém idioma atual
  static String get currentLanguage => _currentLanguage;

  /// Get localized string / Obtém string localizada
  static String get(String key) {
    return _strings[_currentLanguage]?[key] ?? _strings['en_US']?[key] ?? key;
  }

  /// All localized strings / Todas as strings localizadas
  static const Map<String, Map<String, String>> _strings = {
    'en_US': {
      // Main interface / Interface principal
      'feed': 'Feed',
      'clean': 'Clean',
      'play': 'Play',
      'settings': 'Settings',
      'chat_placeholder': 'Type your message here...',
      'chat_send': 'Send',
      'chat_max_chars': 'Max 50 characters',

      // Duck status / Status do pato
      'hungry': 'I\'m hungry!',
      'dirty': 'I need a bath!',
      'sad': 'I\'m bored!',
      'happy': 'I\'m happy!',
      'sleeping': 'Zzz...',

      // Death messages / Mensagens de morte
      'died_hunger': 'I died of hunger... 😵',
      'died_dirty': 'I died from being too dirty... 😵',
      'died_sadness': 'I died of sadness... 😵',
      'revive': 'Revive',
      'death_title': 'Oh no!',

      // Settings / Configurações
      'settings_title': 'Settings',
      'language': 'Language',
      'english': 'English',
      'portuguese': 'Portuguese',
      'api_key': 'ChatGPT API Key',
      'api_key_hint': 'Enter your OpenAI API key here',
      'close': 'Close',
      'save': 'Save',

      // Chat / Chat
      'no_api_key': 'Please add your ChatGPT API key in settings to chat with me!',
      'thinking': 'Thinking...',
      'error_chat': 'Sorry, I couldn\'t respond right now.',

      // Automatic comments / Comentários automáticos
      'auto_comment_intro': 'Let me see what you\'re doing...',
      'auto_comment_error': 'I can\'t see what you\'re doing right now.',

      // Care actions / Ações de cuidado
      'fed_message': 'Yummy! Thank you for feeding me!',
      'cleaned_message': 'Ah, much better! I\'m clean now!',
      'played_message': 'That was fun! I love playing!',

      // Validation / Validação
      'message_too_long': 'Message too long! Max 50 characters.',
      'empty_message': 'Please type something first!',
    },

    'pt_BR': {
      // Main interface / Interface principal
      'feed': 'Alimentar',
      'clean': 'Limpar',
      'play': 'Brincar',
      'settings': 'Configurações',
      'chat_placeholder': 'Digite sua mensagem aqui...',
      'chat_send': 'Enviar',
      'chat_max_chars': 'Máx 50 caracteres',

      // Duck status / Status do pato
      'hungry': 'Estou com fome!',
      'dirty': 'Preciso de um banho!',
      'sad': 'Estou entediado!',
      'happy': 'Estou feliz!',
      'sleeping': 'Zzz...',

      // Death messages / Mensagens de morte
      'died_hunger': 'Morri de fome... 😵',
      'died_dirty': 'Morri por estar muito sujo... 😵',
      'died_sadness': 'Morri de tristeza... 😵',
      'revive': 'Reviver',
      'death_title': 'Oh não!',

      // Settings / Configurações
      'settings_title': 'Configurações',
      'language': 'Idioma',
      'english': 'Inglês',
      'portuguese': 'Português',
      'api_key': 'Chave API ChatGPT',
      'api_key_hint': 'Digite sua chave API da OpenAI aqui',
      'close': 'Fechar',
      'save': 'Salvar',

      // Chat / Chat
      'no_api_key': 'Por favor, adicione sua chave API do ChatGPT nas configurações para conversar comigo!',
      'thinking': 'Pensando...',
      'error_chat': 'Desculpe, não consegui responder agora.',

      // Automatic comments / Comentários automáticos
      'auto_comment_intro': 'Deixe-me ver o que você está fazendo...',
      'auto_comment_error': 'Não consigo ver o que você está fazendo agora.',

      // Care actions / Ações de cuidado
      'fed_message': 'Delícia! Obrigado por me alimentar!',
      'cleaned_message': 'Ah, muito melhor! Estou limpo agora!',
      'played_message': 'Foi divertido! Eu amo brincar!',

      // Validation / Validação
      'message_too_long': 'Mensagem muito longa! Máx 50 caracteres.',
      'empty_message': 'Por favor, digite algo primeiro!',
    }
  };
}
