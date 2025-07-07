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

class _SettingsPageState extends State<SettingsPage> {
  // Controllers / Controladores
  final TextEditingController _apiKeyController = TextEditingController();

  // State variables / Variáveis de estado
  bool _isEnglish = true;
  bool _isLoading = false;
  bool _apiKeyVisible = false;
  String _apiKeyStatus = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  /// Load settings from preferences / Carrega configurações das preferências
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load language setting / Carrega configuração de idioma
      final language = prefs.getString('language') ?? 'en_US';
      _isEnglish = language == 'en_US';

      // Load API key / Carrega chave API
      final apiKey = prefs.getString('chatgpt_api_key') ?? '';
      _apiKeyController.text = apiKey;

      // Check API key status / Verifica status da chave API
      await _checkApiKeyStatus();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Save settings to preferences / Salva configurações nas preferências
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Save language setting / Salva configuração de idioma
      final language = _isEnglish ? 'en_US' : 'pt_BR';
      await prefs.setString('language', language);
      await LocalizationStrings.setLanguage(language);

      // Save API key / Salva chave API
      await ChatService.setApiKey(_apiKeyController.text.trim());

      // Check API key status / Verifica status da chave API
      await _checkApiKeyStatus();

      // Show success message / Mostra mensagem de sucesso
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

      // Show error message / Mostra mensagem de erro
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

  /// Check API key status / Verifica status da chave API
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

    // Basic validation / Validação básica
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
      backgroundColor: Colors.white.withValues(alpha: 0.95),
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
          // Close button / Botão de fechar
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
                  // Language settings section / Seção de configurações de idioma
                  _buildLanguageSection(),

                  const SizedBox(height: 24),

                  // API key settings section / Seção de configurações da chave API
                  _buildApiKeySection(),

                  const SizedBox(height: 32),

                  // Save and close buttons / Botões de salvar e fechar
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  /// Build language settings section / Constrói seção de configurações de idioma
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
            // Section title / Título da seção
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

            // Language toggle / Alternador de idioma
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
                      !_isEnglish, // Switched logic for PT/EN / Lógica invertida para PT/EN
                  onChanged: (value) {
                    setState(() {
                      _isEnglish = !value;
                    });
                  },
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.blue,
                ),
              ],
            ),

            // Language description / Descrição do idioma
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

  /// Build API key settings section / Constrói seção de configurações da chave API
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
            // Section title / Título da seção
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

            // API key input field / Campo de entrada da chave API
            TextField(
              controller: _apiKeyController,
              obscureText: !_apiKeyVisible,
              onChanged: (value) {
                _checkApiKeyStatus();
              },
              decoration: InputDecoration(
                hintText: LocalizationStrings.get('api_key_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _apiKeyVisible = !_apiKeyVisible;
                    });
                  },
                  icon: Icon(
                    _apiKeyVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // API key status / Status da chave API
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

            // API key help text / Texto de ajuda da chave API
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

  /// Build action buttons / Constrói botões de ação
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Save button / Botão de salvar
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

        // Close button / Botão de fechar
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
