import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/localization_strings.dart';
import '../services/chat_service.dart';

/// Página de configurações para o pato tamagotchi
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

/// Classe de estado para a SettingsPage
class _SettingsPageState extends State<SettingsPage> {
  // Controlador para o campo de texto da chave API
  final TextEditingController _apiKeyController = TextEditingController();

  // Variáveis de estado para gerenciar a UI e as configurações
  bool _isLoading = false;
  bool _apiKeyVisible = false;
  String _apiKeyStatus = '';

  @override
  void initState() {
    super.initState();
    // Carrega as configurações quando o widget inicializa
    _loadSettings();
  }

  @override
  void dispose() {
    // Descarta o controlador da chave API quando o widget é removido
    _apiKeyController.dispose();
    super.dispose();
  }

  /// Carrega as configurações do aplicativo das preferências compartilhadas, incluindo idioma e chave API.
  /// Também verifica o status da chave API carregada.
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Recupera e define a chave API
      final apiKey = prefs.getString('chatgpt_api_key') ?? '';
      _apiKeyController.text = apiKey;

      // Verifica o status da chave API recuperada
      await _checkApiKeyStatus();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Salva as configurações atuais do aplicativo nas preferências compartilhadas, incluindo idioma e chave API.
  /// Exibe uma mensagem de sucesso ou erro para o usuário.
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await LocalizationStrings.setLanguage('pt_BR');

      // Salva a chave API usando ChatService
      await ChatService.setApiKey(_apiKeyController.text.trim());

      // Verifica novamente o status da chave API após salvar
      await _checkApiKeyStatus();

      // Mostra snackbar de sucesso
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

      // Mostra snackbar de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar configurações: $e'),
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

  /// Verifica a validade e o status da chave API inserida.
  /// Atualiza [_apiKeyStatus] com base em se a chave está configurada ou tem um formato inválido.
  Future<void> _checkApiKeyStatus() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        _apiKeyStatus = 'Chave API não configurada';
      });
      return;
    }

    // Validação básica para o formato da chave API
    if (apiKey.startsWith('sk-') && apiKey.length > 20) {
      setState(() {
        _apiKeyStatus = 'Chave API configurada';
      });
    } else {
      setState(() {
        _apiKeyStatus = 'Formato de chave API inválido';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withAlpha(242),
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
          // Botão para fechar a página de configurações
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
                  // Seção para configurações da chave API
                  _buildApiKeySection(),

                  const SizedBox(height: 32),

                  // Seção para botões de ação de salvar e fechar
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  /// Builds the API key input section in the settings page.
  /// Allows users to enter, save, and view their ChatGPT API key.
  ///
  /// Constrói a seção de entrada da chave API na página de configurações.
  /// Permite aos usuários inserir, salvar e visualizar sua chave API do ChatGPT.
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
                  Icons.vpn_key,
                  color: Colors.blue.shade600,
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
              obscureText: !_apiKeyVisible,
              decoration: InputDecoration(
                labelText: LocalizationStrings.get('api_key'),
                hintText: LocalizationStrings.get('api_key_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _apiKeyVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _apiKeyVisible = !_apiKeyVisible;
                    });
                  },
                ),
              ),
              onChanged: (value) => _checkApiKeyStatus(),
            ),
            const SizedBox(height: 8),
            // Displays the current status of the API key / Exibe o status atual da chave API
            Text(
              _apiKeyStatus,
              style: TextStyle(
                color: _apiKeyStatus.contains('não configurada') ||
                        _apiKeyStatus.contains('inválido')
                    ? Colors.orange
                    : Colors.green,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the action buttons section (Save and Close) in the settings page.
  ///
  /// Constrói a seção de botões de ação (Salvar e Fechar) na página de configurações.
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Close button / Botão fechar
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            LocalizationStrings.get('close'),
            style: TextStyle(color: Colors.blue.shade600),
          ),
        ),
        const SizedBox(width: 8),
        // Save button / Botão salvar
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(LocalizationStrings.get('save')),
        ),
      ],
    );
  }
}
