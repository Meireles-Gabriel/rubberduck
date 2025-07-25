import 'package:shared_preferences/shared_preferences.dart';

/// Sistema de localização para suporte multi-idioma do pet virtual
/// Essencial para proporcionar experiência nativa aos usuários de diferentes regiões
class LocalizationStrings {
  // Idioma atual carregado dinamicamente para mudanças em tempo real
  static String _currentLanguage = 'pt_BR';
  // SharedPreferences para persistir preferência de idioma entre sessões
  static SharedPreferences? _prefs;

  /// Inicialização obrigatória para carregar configurações persistidas
  /// Deve ser chamado antes de construir qualquer UI com texto localizado
  static Future<void> init() async {
    _prefs = await SharedPreferences
        .getInstance(); // Acesso ao armazenamento local do sistema
    _currentLanguage = _prefs?.getString('language') ??
        'pt_BR'; // Carrega idioma salvo ou usa português como padrão
  }

  /// Permite mudança de idioma em tempo real com persistência automática
  static Future<void> setLanguage(String language) async {
    _currentLanguage = language; // Atualiza estado em memória
    await _prefs?.setString(
        'language', language); // Persiste para próximas sessões
  }

  /// Acesso ao idioma ativo para verificações condicionais
  static String get currentLanguage => _currentLanguage;

  /// Sistema de fallback inteligente: idioma atual → português → chave original
  /// Evita textos em branco ou crashes por strings não encontradas
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
      'chat_placeholder':
          'Digite aqui...', // Texto de placeholder para o campo de entrada do chat

      // Mensagens de status do pato
      'hungry': 'Estou com fome!', // Mensagem do pato quando está com fome
      'dirty': 'Preciso de um banho!', // Mensagem do pato quando está sujo
      'sad': 'Estou entediado!', // Mensagem do pato quando está triste
      'happy': 'Eba!', // Mensagem do pato quando está feliz

      // Mensagens relacionadas à morte
      'died_hunger': 'Morri de fome... 😵', // Mensagem de morte por fome
      'died_dirty':
          'Morri por estar muito sujo... 😵', // Mensagem de morte por sujeira
      'died_sadness':
          'Morri de tristeza... 😵', // Mensagem de morte por tristeza
      'revive': 'Reviver', // Texto para o botão reviver

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
      'copy': 'Copiar', // Texto para o botão copiar
      'duck_message':
          'Mensagem do Pato', // Título do dialog da mensagem do pato
      'text_copied':
          'Texto copiado para a área de transferência!', // Mensagem de confirmação de cópia

      // Strings relacionadas ao chat
      'no_api_key':
          'Por favor, adicione sua chave API do ChatGPT nas configurações para conversar comigo!', // Mensagem quando a chave API está faltando
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
      'warning_hunger':
          'Estou com muita fome! Por favor, me alimente logo ou posso morrer!',
      'warning_dirty':
          'Estou muito sujo! Por favor, me limpe logo ou posso morrer!',
      'warning_sadness':
          'Estou muito triste! Por favor, brinque comigo logo ou posso morrer!',

      // Strings da página de configurações
      'api_key_not_configured': 'Chave API não configurada',
      'api_key_configured': 'Chave API configurada',
      'api_key_invalid': 'Formato de chave API inválido',
      'save_success': 'Configurações salvas com sucesso',
      'save_error': 'Erro ao salvar configurações: ',
      'exit_app': 'Sair do Aplicativo',
      'duck_name': 'Nome do Pato',
      'duck_name_hint': 'Digite o nome do seu pato',
      'duck_name_default': '',

      // Strings da tela de loading
      'loading_duck': 'Carregando\nseu patinho...',
    },
    'en_US': {
      // Main interface strings
      'feed': 'Feed',
      'clean': 'Clean',
      'play': 'Play',
      'chat_placeholder': 'Type here...',

      // Duck status messages
      'hungry': 'I\'m hungry!',
      'dirty': 'I need a bath!',
      'sad': 'I\'m bored!',
      'happy': 'Yay!',

      // Death-related messages
      'died_hunger': 'I died of hunger... 😵',
      'died_dirty': 'I died from being too dirty... 😵',
      'died_sadness': 'I died of sadness... 😵',
      'revive': 'Revive',

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
      'copy': 'Copy', // Copy button text
      'duck_message': 'Duck Message', // Duck message dialog title
      'text_copied': 'Text copied to clipboard!', // Copy confirmation message

      // Chat related strings
      'no_api_key':
          'Please add your ChatGPT API key in settings to chat with me!',
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
      'warning_hunger': 'I\'m very hungry! Please feed me soon or I might die!',
      'warning_dirty': 'I\'m very dirty! Please clean me soon or I might die!',
      'warning_sadness':
          'I\'m very sad! Please play with me soon or I might die!',

      // Settings page strings
      'api_key_not_configured': 'API Key not configured',
      'api_key_configured': 'API Key configured',
      'api_key_invalid': 'Invalid API Key format',
      'save_success': 'Settings saved successfully',
      'save_error': 'Error saving settings: ',
      'exit_app': 'Exit Application',
      'duck_name': 'Duck Name',
      'duck_name_hint': 'Enter your duck\'s name',
      'duck_name_default': '',

      // Loading screen strings
      'loading_duck': 'Loading\nyour duckling...',
    }
  };
}
