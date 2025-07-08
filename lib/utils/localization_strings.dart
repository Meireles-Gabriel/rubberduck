import 'package:shared_preferences/shared_preferences.dart';

/// Localization strings for the app / Strings de localização para o app
class LocalizationStrings {
  // Stores the currently selected language, defaults to 'en_US' / Armazena o idioma atualmente selecionado, padrão é 'en_US'
  static String _currentLanguage = 'en_US';
  // SharedPreferences instance for persisting language settings / Instância de SharedPreferences para persistir configurações de idioma
  static SharedPreferences? _prefs;

  /// Initializes the localization system by loading the saved language from SharedPreferences. / Inicializa o sistema de localização carregando o idioma salvo do SharedPreferences.
  static Future<void> init() async {
    _prefs = await SharedPreferences
        .getInstance(); // Gets the instance of SharedPreferences / Obtém a instância de SharedPreferences
    _currentLanguage = _prefs?.getString('language') ??
        'en_US'; // Sets the current language, defaulting to 'en_US' if not found / Define o idioma atual, padronizando para 'en_US' se não encontrado
  }

  /// Sets the application's language and persists it in SharedPreferences. / Define o idioma da aplicação e o persiste no SharedPreferences.
  static Future<void> setLanguage(String language) async {
    _currentLanguage =
        language; // Updates the current language / Atualiza o idioma atual
    await _prefs?.setString('language',
        language); // Saves the new language to SharedPreferences / Salva o novo idioma no SharedPreferences
  }

  /// Getter for the currently active language. / Getter para o idioma atualmente ativo.
  static String get currentLanguage => _currentLanguage;

  /// Retrieves a localized string for a given key. Falls back to 'en_US' if the key is not found in the current language, or returns the key itself if not found anywhere. / Recupera uma string localizada para uma dada chave. Volta para 'en_US' se a chave não for encontrada no idioma atual, ou retorna a própria chave se não for encontrada em nenhum lugar.
  static String get(String key) {
    return _strings[_currentLanguage]?[key] ?? _strings['en_US']?[key] ?? key;
  }

  /// A static map containing all localized strings for different languages. / Um mapa estático contendo todas as strings localizadas para diferentes idiomas.
  static const Map<String, Map<String, String>> _strings = {
    'en_US': {
      // Main interface strings / Strings da interface principal
      'feed':
          'Feed', // Text for the feed action button / Texto para o botão de ação alimentar
      'clean':
          'Clean', // Text for the clean action button / Texto para o botão de ação limpar
      'play':
          'Play', // Text for the play action button / Texto para o botão de ação brincar
      'settings':
          'Settings', // Text for the settings button / Texto para o botão de configurações
      'chat_placeholder':
          'Type your message here...', // Placeholder text for the chat input field / Texto de placeholder para o campo de entrada do chat
      'chat_send':
          'Send', // Text for the chat send button / Texto para o botão de envio do chat
      'chat_max_chars':
          'Max 50 characters', // Message indicating maximum characters for chat input / Mensagem indicando o número máximo de caracteres para entrada do chat

      // Duck status messages / Mensagens de status do pato
      'hungry':
          'I\'m hungry!', // Duck's message when hungry / Mensagem do pato quando está com fome
      'dirty':
          'I need a bath!', // Duck's message when dirty / Mensagem do pato quando está sujo
      'sad':
          'I\'m bored!', // Duck's message when sad / Mensagem do pato quando está triste
      'happy':
          'I\'m happy!', // Duck's message when happy / Mensagem do pato quando está feliz
      'sleeping':
          'Zzz...', // Duck's message when sleeping / Mensagem do pato quando está dormindo

      // Death related messages / Mensagens relacionadas à morte
      'died_hunger': 'I died of hunger... 😵',
      'died_dirty': 'I died from being too dirty... 😵',
      'died_sadness': 'I died of sadness... 😵',
      'revive':
          'Revive', // Text for the revive button / Texto para o botão reviver
      'death_title':
          'Oh no!', // Title for the death dialog / Título para o diálogo de morte

      // Settings screen strings / Strings da tela de configurações
      'settings_title':
          'Settings', // Title of the settings screen / Título da tela de configurações
      'language':
          'Language', // Label for language selection / Rótulo para seleção de idioma
      'english':
          'English', // Option for English language / Opção para idioma inglês
      'portuguese':
          'Portuguese', // Option for Portuguese language / Opção para idioma português
      'api_key':
          'ChatGPT API Key', // Label for ChatGPT API key input / Rótulo para entrada da chave API do ChatGPT
      'api_key_hint':
          'Enter your OpenAI API key here', // Hint text for API key input field / Texto de dica para o campo de entrada da chave API
      'close': 'Close', // Text for close button / Texto para o botão fechar
      'save': 'Save', // Text for save button / Texto para o botão salvar

      // Chat related strings / Strings relacionadas ao chat
      'no_api_key':
          'Please add your ChatGPT API key in settings to chat with me!', // Message when API key is missing / Mensagem quando a chave API está faltando
      'thinking':
          'Thinking...', // Message displayed when AI is thinking / Mensagem exibida quando a IA está pensando
      'error_chat':
          'Sorry, I couldn\'t respond right now.', // Generic chat error message / Mensagem de erro genérica do chat

      // Automatic comments strings / Strings de comentários automáticos
      'auto_comment_intro':
          'Let me see what you\'re doing...', // Introduction for automatic comments / Introdução para comentários automáticos
      'auto_comment_error':
          'I can\'t see what you\'re doing right now.', // Error message for automatic comments / Mensagem de erro para comentários automáticos

      // Duck care action messages / Mensagens de ações de cuidado do pato
      'fed_message':
          'Yummy! Thank you for feeding me!', // Message after feeding the duck / Mensagem após alimentar o pato
      'cleaned_message':
          'Ah, much better! I\'m clean now!', // Message after cleaning the duck / Mensagem após limpar o pato
      'played_message':
          'That was fun! I love playing!', // Message after playing with the duck / Mensagem após brincar com o pato

      // Validation messages / Mensagens de validação
      'message_too_long':
          'Message too long! Max 50 characters.', // Validation error for long messages / Erro de validação para mensagens longas
      'empty_message':
          'Please type something first!', // Validation error for empty messages / Erro de validação para mensagens vazias
    },
    'pt_BR': {
      // Main interface strings / Strings da interface principal
      'feed': 'Alimentar', // Texto para o botão de ação alimentar
      'clean': 'Limpar', // Texto para o botão de ação limpar
      'play': 'Brincar', // Texto para o botão de ação brincar
      'settings': 'Configurações', // Texto para o botão de configurações
      'chat_placeholder':
          'Digite sua mensagem aqui...', // Texto de placeholder para o campo de entrada do chat
      'chat_send': 'Enviar', // Texto para o botão de envio do chat
      'chat_max_chars':
          'Máx 50 caracteres', // Mensagem indicando o número máximo de caracteres para entrada do chat

      // Duck status messages / Mensagens de status do pato
      'hungry': 'Estou com fome!', // Mensagem do pato quando está com fome
      'dirty': 'Preciso de um banho!', // Mensagem do pato quando está sujo
      'sad': 'Estou entediado!', // Mensagem do pato quando está triste
      'happy': 'Estou feliz!', // Mensagem do pato quando está feliz
      'sleeping': 'Zzz...', // Mensagem do pato quando está dormindo

      // Death related messages / Mensagens relacionadas à morte
      'died_hunger': 'Morri de fome... 😵', // Mensagem de morte por fome
      'died_dirty':
          'Morri por estar muito sujo... 😵', // Mensagem de morte por sujeira
      'died_sadness':
          'Morri de tristeza... 😵', // Mensagem de morte por tristeza
      'revive': 'Reviver', // Texto para o botão reviver
      'death_title': 'Oh não!', // Título para o diálogo de morte

      // Settings screen strings / Strings da tela de configurações
      'settings_title': 'Configurações', // Título da tela de configurações
      'language': 'Idioma', // Rótulo para seleção de idioma
      'english': 'Inglês', // Opção para idioma inglês
      'portuguese': 'Português', // Opção para idioma português
      'api_key':
          'Chave API ChatGPT', // Rótulo para entrada da chave API do ChatGPT
      'api_key_hint':
          'Digite sua chave API da OpenAI aqui', // Texto de dica para o campo de entrada da chave API
      'close': 'Fechar', // Texto para o botão fechar
      'save': 'Salvar', // Texto para o botão salvar

      // Chat related strings / Strings relacionadas ao chat
      'no_api_key':
          'Por favor, adicione sua chave API do ChatGPT nas configurações para conversar comigo!', // Mensagem quando a chave API está faltando
      'thinking': 'Pensando...', // Mensagem exibida quando a IA está pensando
      'error_chat':
          'Desculpe, não consegui responder agora.', // Mensagem de erro genérica do chat

      // Automatic comments strings / Strings de comentários automáticos
      'auto_comment_intro':
          'Deixe-me ver o que você está fazendo...', // Introdução para comentários automáticos
      'auto_comment_error':
          'Não consigo ver o que você está fazendo agora.', // Mensagem de erro para comentários automáticos

      // Duck care action messages / Mensagens de ações de cuidado do pato
      'fed_message':
          'Delícia! Obrigado por me alimentar!', // Mensagem após alimentar o pato
      'cleaned_message':
          'Ah, muito melhor! Estou limpo agora!', // Mensagem após limpar o pato
      'played_message':
          'Foi divertido! Eu amo brincar!', // Mensagem após brincar com o pato

      // Validation messages / Mensagens de validação
      'message_too_long':
          'Mensagem muito longa! Máx 50 caracteres.', // Erro de validação para mensagens longas
      'empty_message':
          'Por favor, digite algo primeiro!', // Erro de validação para mensagens vazias
    }
  };
}
