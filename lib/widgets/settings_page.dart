import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/localization_strings.dart';
import '../services/chat_service.dart';

/// Settings page for the tamagotchi duck / Página de configurações para o pato tamagotchi
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

/// State class for the SettingsPage / Classe de estado para a SettingsPage
class _SettingsPageState extends State<SettingsPage> {
  // Controller for the API key text field / Controlador para o campo de texto da chave API
  final TextEditingController _apiKeyController = TextEditingController();

  // State variables for managing UI and settings / Variáveis de estado para gerenciar a UI e as configurações
  bool _isEnglish = true;
  bool _isLoading = false;
  bool _apiKeyVisible = false;
  String _apiKeyStatus = '';

  @override
  void initState() {
    super.initState();
    // Load settings when the widget initializes / Carrega as configurações quando o widget inicializa
    _loadSettings();
  }

  @override
  void dispose() {
    // Dispose of the API key controller when the widget is removed / Descarta o controlador da chave API quando o widget é removido
    _apiKeyController.dispose();
    super.dispose();
  }

  /// Loads application settings from shared preferences, including language and API key.
  /// It also checks the status of the loaded API key.
  ///
  /// Carrega as configurações do aplicativo das preferências compartilhadas, incluindo idioma e chave API.
  /// Também verifica o status da chave API carregada.
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Retrieve and set language preference / Recupera e define a preferência de idioma
      final language = prefs.getString('language') ?? 'en_US';
      _isEnglish = language == 'en_US';

      // Retrieve and set API key / Recupera e define a chave API
      final apiKey = prefs.getString('chatgpt_api_key') ?? '';
      _apiKeyController.text = apiKey;

      // Check the status of the retrieved API key / Verifica o status da chave API recuperada
      await _checkApiKeyStatus();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Saves current application settings to shared preferences, including language and API key.
  /// Displays a success or error message to the user.
  ///
  /// Salva as configurações atuais do aplicativo nas preferências compartilhadas, incluindo idioma e chave API.
  /// Exibe uma mensagem de sucesso ou erro para o usuário.
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Determine and save the selected language / Determina e salva o idioma selecionado
      final language = _isEnglish ? 'en_US' : 'pt_BR';
      await prefs.setString('language', language);
      await LocalizationStrings.setLanguage(language);

      // Save the API key using ChatService / Salva a chave API usando ChatService
      await ChatService.setApiKey(_apiKeyController.text.trim());

      // Re-check API key status after saving / Verifica novamente o status da chave API após salvar
      await _checkApiKeyStatus();

      // Show success snackbar / Mostra snackbar de sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationStrings.get('save')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');

      // Show error snackbar / Mostra snackbar de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Checks the validity and status of the entered API key.
  /// Updates [_apiKeyStatus] based on whether the key is configured or has an invalid format.
  ///
  /// Verifica a validade e o status da chave API inserida.
  /// Atualiza [_apiKeyStatus] com base em se a chave está configurada ou tem um formato inválido.
  Future<void> _checkApiKeyStatus() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        _apiKeyStatus = LocalizationStrings.currentLanguage == 'pt_BR'
            ? 'Chave API não configurada'
            : 'API key not configured';
      });
      return;
    }

    // Basic validation for API key format / Validação básica para o formato da chave API
    if (apiKey.startsWith('sk-') && apiKey.length > 20) {
      setState(() {
        _apiKeyStatus = LocalizationStrings.currentLanguage == 'pt_BR'
            ? 'Chave API configurada'
            : 'API key configured';
      });
    } else {
      setState(() {
        _apiKeyStatus = LocalizationStrings.currentLanguage == 'pt_BR'
            ? 'Formato de chave API inválido'
            : 'Invalid API key format';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.95),
      appBar: AppBar(
        title: Text(
          LocalizationStrings.get('settings_title'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Button to close the settings page / Botão para fechar a página de configurações
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: LocalizationStrings.get('close'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section for language settings / Seção para configurações de idioma
                  _buildLanguageSection(),

                  const SizedBox(height: 24),

                  // Section for API key settings / Seção para configurações da chave API
                  _buildApiKeySection(),

                  const SizedBox(height: 32),

                  // Section for save and close action buttons / Seção para botões de ação de salvar e fechar
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  /// Builds the language selection section in the settings page.
  /// Allows users to toggle between English and Portuguese.
  ///
  /// Constrói a seção de seleção de idioma na página de configurações.
  /// Permite aos usuários alternar entre inglês e português.
  Widget _buildLanguageSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row containing the language icon and title / Linha contendo o ícone do idioma e o título
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  LocalizationStrings.get('language'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Row for language toggle switch / Linha para o interruptor de alternância de idioma
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEnglish
                      ? LocalizationStrings.get('english')
                      : LocalizationStrings.get('portuguese'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value:
                      !_isEnglish, // Inverted logic: true for Portuguese, false for English / Lógica invertida: true para Português, false para Inglês
                  onChanged: (value) {
                    setState(() {
                      _isEnglish =
                          !value; // Toggle language state / Alterna o estado do idioma
                    });
                  },
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.blue,
                ),
              ],
            ),

            // Display of the currently selected language / Exibição do idioma atualmente selecionado
            Text(
              _isEnglish ? 'English (US)' : 'Português (Brasil)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the API key input section in the settings page.
  /// Allows users to enter their OpenAI API key and view its status.
  ///
  /// Constrói a seção de entrada da chave API na página de configurações.
  /// Permite aos usuários inserir sua chave API OpenAI e visualizar seu status.
  Widget _buildApiKeySection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row containing the API key icon and title / Linha contendo o ícone da chave API e o título
            Row(
              children: [
                Icon(
                  Icons.key,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  LocalizationStrings.get('api_key'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Text field for API key input / Campo de texto para entrada da chave API
            TextField(
              controller: _apiKeyController,
              obscureText:
                  !_apiKeyVisible, // Toggles visibility of the API key / Alterna a visibilidade da chave API
              onChanged: (value) {
                _checkApiKeyStatus(); // Re-check status on change / Verifica o status na mudança
              },
              decoration: InputDecoration(
                hintText: LocalizationStrings.get('api_key_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _apiKeyVisible =
                          !_apiKeyVisible; // Toggle API key visibility / Alterna a visibilidade da chave API
                    });
                  },
                  icon: Icon(
                    _apiKeyVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Display area for API key status message / Área de exibição para mensagem de status da chave API
            if (_apiKeyStatus.isNotEmpty)
              Row(
                children: [
                  Icon(
                    _apiKeyStatus.contains('configurada') ||
                            _apiKeyStatus.contains('configured')
                        ? Icons.check_circle
                        : Icons.error,
                    color: _apiKeyStatus.contains('configurada') ||
                            _apiKeyStatus.contains('configured')
                        ? Colors.green
                        : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _apiKeyStatus,
                    style: TextStyle(
                      fontSize: 14,
                      color: _apiKeyStatus.contains('configurada') ||
                              _apiKeyStatus.contains('configured')
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Help text for obtaining the API key / Texto de ajuda para obter a chave API
            Text(
              LocalizationStrings.currentLanguage == 'pt_BR'
                  ? 'Você pode obter sua chave API em https://platform.openai.com/api-keys'
                  : 'You can get your API key at https://platform.openai.com/api-keys',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the action buttons section, including Save and Close buttons.
  ///
  /// Constrói a seção de botões de ação, incluindo os botões Salvar e Fechar.
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Save settings button / Botão de salvar configurações
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        LocalizationStrings.get('save'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // Close settings button / Botão de fechar configurações
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.close, size: 20),
                const SizedBox(width: 8),
                Text(
                  LocalizationStrings.get('close'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
