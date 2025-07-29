import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/localization_strings.dart';
import '../services/chat_service.dart';
import 'tamagotchi_widget.dart';

/// Interface de configuração centralizada para personalização da experiência do usuário
/// Necessária para permitir ajustes sem reinicializar o app e manter preferências
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

/// Gerenciador de estado para configurações com validação e persistência
class _SettingsPageState extends State<SettingsPage> {
  // Controllers necessários para capturar e validar input do usuário
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _duckNameController = TextEditingController();

  // Estados de UI para feedback visual ao usuário
  bool _isLoading = false; // Previne múltiplas operações simultâneas
  bool _apiKeyVisible = false; // Segurança para não expor chave por acidente
  String _apiKeyStatus = ''; // Feedback em tempo real sobre validade da chave

  @override
  void initState() {
    super.initState();
    // Carregamento imediato para exibir configurações atuais ao usuário
    _loadSettings();
  }

  @override
  void dispose() {
    // Cleanup de controllers para prevenir vazamentos de memória
    _apiKeyController.dispose();
    _duckNameController.dispose();
    super.dispose();
  }

  /// Recupera configurações persistidas para exibir estado atual ao usuário
  /// Necessário para evitar perda de configurações e mostrar valores atuais
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true; // Indica carregamento para feedback visual
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Carrega nome personalizado para mostrar identidade atual do pet
      final duckName = prefs.getString('duck_name') ??
          LocalizationStrings.get('duck_name_default');
      _duckNameController.text = duckName;

      // Carrega chave API para mostrar se funcionalidade de chat está disponível
      final apiKey = prefs.getString('chatgpt_api_key') ?? '';
      _apiKeyController.text = apiKey;

      // Validação imediata para informar status da funcionalidade de IA
      await _checkApiKeyStatus();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false; // Remove indicador de carregamento
      });
    }
  }

  /// Persiste configurações do usuário para manter preferências entre sessões
  /// Validação e feedback essenciais para confirmar sucesso das operações
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true; // Previne múltiplas operações simultâneas
    });

    try {
      // Salva via ChatService para centralizar lógica de validação de API
      await ChatService.setApiKey(_apiKeyController.text.trim());

      // Persiste nome personalizado com fallback para evitar strings vazias
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'duck_name',
          _duckNameController.text.trim().isEmpty
              ? LocalizationStrings.get('duck_name_default')
              : _duckNameController.text.trim());

      // Atualização em tempo real necessária para não exigir restart
      TamagotchiWidget.duckNameNotifier.value = _duckNameController.text.trim();
      setState(() {});

      // Revalidação pós-save para confirmar sucesso da operação
      await _checkApiKeyStatus();

      // Feedback positivo para confirmar sucesso ao usuário
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationStrings.get('save_success')),
            backgroundColor: Colors.green, // Verde para sucesso
            duration: const Duration(seconds: 2), // Curto para não incomodar
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      setState(() {});

      // Feedback de erro essencial para debugging do usuário
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationStrings.get('save_error')}$e'),
            backgroundColor: Colors.red, // Vermelho para erro
            duration: const Duration(seconds: 3), // Mais tempo para ler erro
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // Libera interface para novas operações
      });
    }
  }

  /// Validação em tempo real para informar usuário sobre funcionalidade de IA
  /// Feedback imediato necessário para evitar tentativas com chaves inválidas
  Future<void> _checkApiKeyStatus() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        _apiKeyStatus = LocalizationStrings.get('api_key_not_configured');
      });
      return;
    }

    // Validação de formato para feedback rápido antes de tentar usar API
    if (apiKey.startsWith('sk-') && apiKey.length > 20) {
      setState(() {
        _apiKeyStatus = LocalizationStrings.get('api_key_configured');
      });
    } else {
      setState(() {
        _apiKeyStatus = LocalizationStrings.get('api_key_invalid');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withAlpha(242),
      appBar: AppBar(
        toolbarHeight: 40,
        title: Text(
          LocalizationStrings.get('settings_title'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDuckNameSection(),
                  // Seção para seleção de idioma
                  _buildLanguageSection(),

                  const SizedBox(height: 16),

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

  Widget _buildDuckNameSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pets,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  LocalizationStrings.get('duck_name'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _duckNameController,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: LocalizationStrings.get('duck_name'),
                hintText: LocalizationStrings.get('duck_name_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the language selection section
  Widget _buildLanguageSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  LocalizationStrings.get('language'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLanguageButton(
                      'pt_BR', LocalizationStrings.get('portuguese')),
                  const SizedBox(height: 8),
                  _buildLanguageButton(
                      'en_US', LocalizationStrings.get('english')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a language selection button
  Widget _buildLanguageButton(String languageCode, String languageName) {
    final isSelected = LocalizationStrings.currentLanguage == languageCode;
    return ElevatedButton(
      onPressed: () async {
        await LocalizationStrings.setLanguage(languageCode);
        setState(() {}); // Refresh UI
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Text(languageName),
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
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row containing the API key icon and title / Linha contendo o ícone da chave API e o título
            Row(
              children: [
                Icon(
                  Icons.vpn_key,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  LocalizationStrings.get('api_key'),
                  style: const TextStyle(
                    fontSize: 14,
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
                        _apiKeyStatus.contains('inválido') ||
                        _apiKeyStatus.contains('not configured') ||
                        _apiKeyStatus.contains('Invalid')
                    ? Colors.orange
                    : Colors.green,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Limpa o histórico de conversa diretamente
  /// Essencial para resolver problemas de contexto ou começar nova "personalidade"
  Future<void> _clearConversationHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Limpa o histórico usando o método do ChatService
      await ChatService.clearHistory();

      // Feedback positivo para confirmar sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationStrings.get('clear_history_success')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error clearing conversation history: $e');

      // Feedback de erro para debugging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationStrings.get('save_error')}$e'),
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

  /// Builds the action buttons section (Save and Close) in the settings page.
  ///
  /// Constrói a seção de botões de ação (Salvar e Fechar) na página de configurações.
  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
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
        ),
        const SizedBox(height: 16),
        // Clear conversation history button / Botão limpar histórico de conversa
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _clearConversationHistory,
              icon: const Icon(Icons.delete_forever),
              label: Text(LocalizationStrings.get('clear_history')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Exit app button / Botão sair do aplicativo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await windowManager.close();
              },
              icon: const Icon(Icons.exit_to_app),
              label: Text(LocalizationStrings.get('exit_app')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
