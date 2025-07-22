import 'package:shared_preferences/shared_preferences.dart';

/// Strings de localização para o app
class LocalizationStrings {
  // Armazena o idioma atualmente selecionado, padrão é 'pt_BR'
  static String _currentLanguage = 'pt_BR';
  // Instância de SharedPreferences para persistir configurações de idioma
  static SharedPreferences? _prefs;

  /// Inicializa o sistema de localização carregando o idioma salvo do SharedPreferences.
  static Future<void> init() async {
    _prefs = await SharedPreferences
        .getInstance(); // Obtém a instância de SharedPreferences
    _currentLanguage = _prefs?.getString('language') ??
        'pt_BR'; // Define o idioma atual, padronizando para 'pt_BR' se não encontrado
  }

  /// Define o idioma da aplicação e o persiste no SharedPreferences.
  static Future<void> setLanguage(String language) async {
    _currentLanguage = language; // Atualiza o idioma atual
    await _prefs?.setString(
        'language', language); // Salva o novo idioma no SharedPreferences
  }

  /// Getter para o idioma atualmente ativo.
  static String get currentLanguage => _currentLanguage;

  /// Recupera uma string localizada para uma dada chave. Falls back to 'pt_BR' if the key is not found in the current language, or returns the key itself if not found anywhere.
  static String get(String key) {
    return _strings[_currentLanguage]?[key] ?? _strings['pt_BR']?[key] ?? key;
  }

  /// Um mapa estático contendo todas as strings localizadas para diferentes idiomas.
  static const Map<String, Map<String, String>> _strings = {
    'pt_BR': {
      // Strings da interface principal
      'feed': 'Alimentar', // Texto para o botão de ação alimentar
      'clean': 'Limpar', // Texto para o botão de ação limpar
      'play': 'Brincar', // Texto para o botão de ação brincar
      'settings': 'Configurações', // Texto para o botão de configurações
      'chat_placeholder':
          'Digite aqui...', // Texto de placeholder para o campo de entrada do chat
      'chat_send': 'Enviar', // Texto para o botão de envio do chat
      'chat_max_chars':
          'Máx 50 caracteres', // Mensagem indicando o número máximo de caracteres para entrada do chat

      // Mensagens de status do pato
      'hungry': 'Estou com fome!', // Mensagem do pato quando está com fome
      'dirty': 'Preciso de um banho!', // Mensagem do pato quando está sujo
      'sad': 'Estou entediado!', // Mensagem do pato quando está triste
      'happy': 'Eba!', // Mensagem do pato quando está feliz
      'sleeping': 'Zzz...', // Mensagem do pato quando está dormindo

      // Mensagens relacionadas à morte
      'died_hunger': 'Morri de fome... 😵', // Mensagem de morte por fome
      'died_dirty':
          'Morri por estar muito sujo... 😵', // Mensagem de morte por sujeira
      'died_sadness':
          'Morri de tristeza... 😵', // Mensagem de morte por tristeza
      'revive': 'Reviver', // Texto para o botão reviver
      'death_title': 'Oh não!', // Título para o diálogo de morte

      // Explicações de morte
      'explanation_hunger': 'Não foi alimentado por mais de 24 horas.',
      'explanation_dirty': 'Não foi limpo por mais de 24 horas.',
      'explanation_sadness': 'Não brincou por mais de 24 horas.',
      'explanation_adequate_care': 'Não recebeu cuidados adequados.',

      // Strings da tela de configurações
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

      // Strings relacionadas ao chat
      'no_api_key':
          'Por favor, adicione sua chave API do ChatGPT nas configurações para conversar comigo!', // Mensagem quando a chave API está faltando
      'thinking': 'Pensando...', // Mensagem exibida quando a IA está pensando
      'error_chat':
          'Desculpe, não consegui responder agora.', // Mensagem de erro genérica do chat

      // Strings de comentários automáticos
      'auto_comment_intro':
          'Deixe-me ver o que você está fazendo...', // Introdução para comentários automáticos
      'auto_comment_error':
          'Não consigo ver o que você está fazendo agora.', // Mensagem de erro para comentários automáticos

      // Mensagens de ações de cuidado do pato
      'fed_message':
          'Delícia! Obrigado por me alimentar!', // Mensagem após alimentar o pato
      'cleaned_message':
          'Ah, muito melhor! Estou limpo agora!', // Mensagem após limpar o pato
      'played_message':
          'Foi divertido! Eu amo brincar!', // Mensagem após brincar com o pato

      // Mensagens de validação
      'message_too_long':
          'Mensagem muito longa! Máx 50 caracteres.', // Erro de validação para mensagens longas
      'empty_message':
          'Por favor, digite algo primeiro!', // Erro de validação para mensagens vazias

      // Strings de aviso de morte
      'warning_title': 'Aviso Urgente!',
      'warning_hunger':
          'Estou com muita fome! Por favor, me alimente logo ou posso morrer!',
      'warning_dirty':
          'Estou muito sujo! Por favor, me limpe logo ou posso morrer!',
      'warning_sadness':
          'Estou muito triste! Por favor, brinque comigo logo ou posso morrer!',
      'understand': 'Entendi',
      // Novas strings da página de configurações
      'api_key_not_configured': 'Chave API não configurada',
      'api_key_configured': 'Chave API configurada',
      'api_key_invalid': 'Formato de chave API inválido',
      'save_success': 'Configurações salvas com sucesso',
      'save_error': 'Erro ao salvar configurações: ',
      'exit_app': 'Sair do Aplicativo',
      'duck_name': 'Nome do Pato',
      'duck_name_hint': 'Digite o nome do seu pato',
      'duck_name_saved': 'Nome do pato salvo com sucesso!',
      'duck_name_error': 'Erro ao salvar o nome do pato.',
      'duck_name_default': '',

      // Strings da tela de loading
      'loading_duck': 'Carregando\nseu patinho...',
    },
    'en_US': {
      // Main interface strings
      'feed': 'Feed',
      'clean': 'Clean',
      'play': 'Play',
      'settings': 'Settings',
      'chat_placeholder': 'Type here...',
      'chat_send': 'Send',
      'chat_max_chars': 'Max 50 chars',

      // Duck status messages
      'hungry': 'I\'m hungry!',
      'dirty': 'I need a bath!',
      'sad': 'I\'m bored!',
      'happy': 'Yay!',
      'sleeping': 'Zzz...',

      // Death-related messages
      'died_hunger': 'I died of hunger... 😵',
      'died_dirty': 'I died from being too dirty... 😵',
      'died_sadness': 'I died of sadness... 😵',
      'revive': 'Revive',
      'death_title': 'Oh no!',

      // Death explanations
      'explanation_hunger': 'Wasn\'t fed for over 24 hours.',
      'explanation_dirty': 'Wasn\'t cleaned for over 24 hours.',
      'explanation_sadness': 'Didn\'t play for over 24 hours.',
      'explanation_adequate_care': 'Didn\'t receive adequate care.',

      // Settings screen strings
      'settings_title': 'Settings',
      'language': 'Language',
      'english': 'English',
      'portuguese': 'Portuguese',
      'api_key': 'ChatGPT API Key',
      'api_key_hint': 'Enter your OpenAI API key here',
      'close': 'Close',
      'save': 'Save',

      // Chat related strings
      'no_api_key':
          'Please add your ChatGPT API key in settings to chat with me!',
      'thinking': 'Thinking...',
      'error_chat': 'Sorry, I couldn\'t answer right now.',

      // Auto-comment strings
      'auto_comment_intro': 'Let me see what you\'re doing...',
      'auto_comment_error': 'I can\'t see what you\'re doing right now.',

      // Duck care action messages
      'fed_message': 'Yummy! Thanks for feeding me!',
      'cleaned_message': 'Ah, much better! I\'m clean now!',
      'played_message': 'That was fun! I love to play!',

      // Validation messages
      'message_too_long': 'Message too long! Max 50 characters.',
      'empty_message': 'Please type something first!',

      // Death warning strings
      'warning_title': 'Urgent Warning!',
      'warning_hunger': 'I\'m very hungry! Please feed me soon or I might die!',
      'warning_dirty': 'I\'m very dirty! Please clean me soon or I might die!',
      'warning_sadness':
          'I\'m very sad! Please play with me soon or I might die!',
      'understand': 'Got it',
      // New settings page strings
      'api_key_not_configured': 'API Key not configured',
      'api_key_configured': 'API Key configured',
      'api_key_invalid': 'Invalid API Key format',
      'save_success': 'Settings saved successfully',
      'save_error': 'Error saving settings: ',
      'exit_app': 'Exit Application',
      'duck_name': 'Duck Name',
      'duck_name_hint': 'Enter your duck\'s name',
      'duck_name_saved': 'Duck name saved successfully!',
      'duck_name_error': 'Error saving duck name.',
      'duck_name_default': '',

      // Loading screen strings
      'loading_duck': 'Loading\nyour duckling...',
    }
  };
}
