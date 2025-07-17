import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:async';
import '../game/duck_game.dart';
import '../game/duck_status.dart';
import '../game/death_revival_system.dart';
import '../services/chat_service.dart';
import '../services/periodic_tasks.dart';
import '../utils/localization_strings.dart';
import 'settings_page.dart';

/// Widget principal do tamagotchi
class TamagotchiWidget extends StatefulWidget {
  const TamagotchiWidget({super.key});

  @override
  State<TamagotchiWidget> createState() => _TamagotchiWidgetState();
}

/// Classe de estado para TamagotchiWidget
class _TamagotchiWidgetState extends State<TamagotchiWidget>
    with TickerProviderStateMixin {
  // Objetos relacionados ao jogo e status
  late DuckGame duckGame;
  late DuckStatus duckStatus;
  late PeriodicTasksManager periodicTasks;
  bool _isInitialized = false;

  // Controladores para entrada de texto e captura de tela
  final TextEditingController _chatController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();

  // Variáveis de estado para elementos da UI
  String _currentBubbleMessage = '';
  bool _isBubbleVisible = false;
  bool _isChatLoading = false;
  bool _isDraggingFood = false;
  bool _isDraggingClean = false;
  bool _isDraggingPlay = false;

  // Controladores de animação para mensagem de balão
  late AnimationController _bubbleAnimationController;
  late Animation<double> _bubbleAnimation;

  @override
  void initState() {
    super.initState();
    // Inicializa o estado do widget
    _initializeWidget();
  }

  @override
  void dispose() {
    // Descarta controladores e tarefas periódicas
    _chatController.dispose();
    periodicTasks.dispose();
    _bubbleAnimationController.dispose();
    super.dispose();
  }

  /// Inicializa todos os componentes necessários para o widget, incluindo status do pato, jogo,
  /// tarefas periódicas e animação do balão.
  Future<void> _initializeWidget() async {
    // Inicializa status do pato e carrega das preferências
    duckStatus = DuckStatus();
    await duckStatus.loadFromPreferences();

    // Inicializa jogo e vincula com status do pato
    duckGame = DuckGame();
    duckGame.duckStatus = duckStatus;
    duckGame.onStatusUpdate = _onStatusUpdate;

    // Inicializa gerenciador de tarefas periódicas e vincula callbacks
    periodicTasks = PeriodicTasksManager();
    periodicTasks.onStatusUpdate = _onStatusUpdate;
    periodicTasks.onAutoComment = _onAutoComment;
    periodicTasks.onDeathDetected = _onDeathDetected;
    periodicTasks.initialize(duckStatus);

    // Configura controlador de animação e interpolação do balão
    _bubbleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bubbleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bubbleAnimationController,
      curve: Curves.elasticOut,
    ));

    // Realiza verificação de status inicial
    _checkInitialStatus();

    // Marca como inicializado
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// Verifica o status inicial do pato na inicialização do widget.
  /// Exibe o diálogo de morte se o pato estiver morto, ou uma mensagem de atenção se necessário.
  void _checkInitialStatus() {
    if (duckStatus.isDead) {
      // Mostra diálogo de morte após a construção do frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDeathDialog();
      });
    } else if (duckStatus.needsAttention) {
      // Obtém e mostra mensagem de atenção se o pato precisar de atenção
      final message = duckStatus.getAttentionMessage();
      if (message != null) {
        _showBubbleMessage(LocalizationStrings.get(message));
      }
    }
  }

  /// Função de callback para lidar com atualizações no status do pato.
  /// Atualiza a interface do usuário e mostra uma mensagem de balão se o pato precisar de atenção.
  void _onStatusUpdate(String mood) {
    if (mounted) {
      setState(() {
        // Atualiza UI com base no humor do pato
        if (duckStatus.needsAttention) {
          final message = duckStatus.getAttentionMessage();
          if (message != null) {
            _showBubbleMessage(LocalizationStrings.get(message));
          }
        }
      });
    }
  }

  /// Função de callback para lidar com comentários automáticos do pato.
  /// Exibe o comentário na área da mensagem do balão.
  void _onAutoComment(String comment) {
    if (mounted) {
      _showBubbleMessage(comment);
    }
  }

  /// Função de callback para lidar com a detecção da morte do pato.
  /// Aciona a exibição do diálogo de morte.
  void _onDeathDetected() {
    if (mounted) {
      _showDeathDialog();
    }
  }

  /// Exibe o diálogo do sistema de morte e renascimento.
  /// Após o renascimento, atualiza o status do pato e mostra uma mensagem de felicidade.
  void _showDeathDialog() {
    DeathRevivalSystem.showDeathDialog(
      context,
      duckStatus,
      () async {
        await duckGame.reviveDuck();
        setState(() {
          _showBubbleMessage(LocalizationStrings.get('happy'));
        });
      },
    );
  }

  /// Mostra uma mensagem no balão de fala do pato.
  /// O balão aparece com uma animação e se esconde após um atraso.
  void _showBubbleMessage(String message) {
    setState(() {
      _currentBubbleMessage = message;
      _isBubbleVisible = true;
    });

    // Inicia animação de aparição do balão
    _bubbleAnimationController.forward();

    // Define um temporizador para esconder o balão após 5 segundos
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _bubbleAnimationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isBubbleVisible = false;
            });
          }
        });
      }
    });
  }

  /// Gerencia o envio de uma mensagem de chat para o serviço ChatGPT.
  /// Valida a mensagem, mostra o estado de carregamento, envia a mensagem e exibe a resposta ou erro.
  Future<void> _handleChatMessage() async {
    final message = _chatController.text.trim();

    // Valida a mensagem de chat
    if (!ChatService.isMessageValid(message)) {
      final error = ChatService.getValidationError(message);
      _showBubbleMessage(error);
      return;
    }

    // Limpa o campo de entrada do chat
    _chatController.clear();

    // Mostra indicador de carregamento e mensagem "pensando"
    setState(() {
      _isChatLoading = true;
    });
    _showBubbleMessage(LocalizationStrings.get('thinking'));

    try {
      // Envia mensagem para ChatGPT com captura de tela
      final response =
          await ChatService.sendMessage(message, includeScreenshot: true);

      // Exibe a resposta do ChatGPT
      _showBubbleMessage(response);
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      // Mostra mensagem de erro se o chat falhar
      _showBubbleMessage(LocalizationStrings.get('error_chat'));
    } finally {
      setState(() {
        _isChatLoading = false;
      });
    }
  }

  /// Gerencia ações de cuidado como alimentar, limpar ou brincar com o pato.
  /// Impede ações se o pato estiver morto e mostra uma mensagem de confirmação.
  Future<void> _handleCareAction(String action) async {
    if (duckStatus.isDead) return; // Não faz nada se o pato estiver morto

    switch (action) {
      case 'feed':
        await duckGame.feedDuck();
        _showBubbleMessage(LocalizationStrings.get('fed_message'));
        setState(() {
          // Atualiza os estados da UI após alimentar
          duckGame.updateDuckStatus();
        });
        break;
      case 'clean':
        await duckGame.cleanDuck();
        _showBubbleMessage(LocalizationStrings.get('cleaned_message'));
        setState(() {
          // Atualiza os estados da UI após limpar
          duckGame.updateDuckStatus();
        });
        break;
      case 'play':
        await duckGame.playWithDuck();
        _showBubbleMessage(LocalizationStrings.get('played_message'));
        setState(() {
          // Atualiza os estados da UI após brincar
          duckGame.updateDuckStatus();
        });
        break;
    }

    // Força uma reconstrução da UI para atualizar as cores dos botões
    setState(() {});
  }

  /// Calcula a cor do botão baseado no valor do status (0-100)
  Color _getStatusColor(double value) {
    // Define as cores base (pastel)
    const goodColor = Color(0xFF98D8A0); // Verde pastel
    const badColor = Color(0xFFE8A39D); // Vermelho pastel

    // Normaliza o valor para 0-1
    final t = value / 100;

    // Interpola entre as cores
    return Color.lerp(badColor, goodColor, t)!;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    // Widget de captura de tela para capturar a tela inteira
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: const Color(0xFFE6F3FF), // Azul pastel claro
        body: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Área de mensagem do balão de fala
              _buildBubbleArea(),

              // Área principal do jogo com pato e controles
              Expanded(
                child: Row(
                  children: [
                    // Área de exibição do pato
                    Expanded(
                      flex: 2,
                      child: _buildDuckArea(),
                    ),

                    // Controles para ações de cuidado
                    Expanded(
                      flex: 1,
                      child: _buildControlsArea(),
                    ),
                  ],
                ),
              ),

              // Área de entrada e envio de chat
              _buildChatArea(),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói a área animada do balão de fala para exibir mensagens.
  Widget _buildBubbleArea() {
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: _isBubbleVisible
          ? AnimatedBuilder(
              animation: _bubbleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bubbleAnimation.value,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Text(
                        _currentBubbleMessage,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            )
          : const SizedBox.shrink(), // Esconde se não visível
    );
  }

  /// Constrói a área interativa onde o jogo do pato é exibido.
  /// Permite soltar itens de cuidado no pato.
  Widget _buildDuckArea() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 2,
        ),
      ),
      child: DragTarget<String>(
        // Define tipos de dados aceitos para arrastar
        onWillAcceptWithDetails: (details) {
          return details.data == 'feed' ||
              details.data == 'clean' ||
              details.data == 'play';
        },
        // Lida com a ação de soltar aceita
        onAcceptWithDetails: (data) {
          _handleCareAction(data.data);
        },
        builder: (context, candidateData, rejectedData) {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: candidateData.isNotEmpty
                ? Container(
                    // Feedback visual quando um item é arrastado por cima
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.green.withAlpha(51),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.pets,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                  )
                : GameWidget(game: duckGame), // Exibe o widget do jogo
          );
        },
      ),
    );
  }

  /// Constrói a área contendo controles para alimentar, limpar, brincar e configurações.
  Widget _buildControlsArea() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Controle arrastável para alimentar o pato
          _buildDraggableControl(
            icon: Icons.restaurant,
            label: LocalizationStrings.get('feed'),
            data: 'feed',
            color: _getStatusColor(duckStatus.hunger),
            isDragging: _isDraggingFood,
            onDragStarted: () => setState(() => _isDraggingFood = true),
            onDragCompleted: () => setState(() => _isDraggingFood = false),
            onDragCancelled: () => setState(() => _isDraggingFood = false),
          ),

          // Controle arrastável para limpar o pato
          _buildDraggableControl(
            icon: Icons.cleaning_services,
            label: LocalizationStrings.get('clean'),
            data: 'clean',
            color: _getStatusColor(duckStatus.cleanliness),
            isDragging: _isDraggingClean,
            onDragStarted: () => setState(() => _isDraggingClean = true),
            onDragCompleted: () => setState(() => _isDraggingClean = false),
            onDragCancelled: () => setState(() => _isDraggingClean = false),
          ),

          // Controle arrastável para brincar com o pato
          _buildDraggableControl(
            icon: Icons.sports_esports,
            label: LocalizationStrings.get('play'),
            data: 'play',
            color: _getStatusColor(duckStatus.happiness),
            isDragging: _isDraggingPlay,
            onDragStarted: () => setState(() => _isDraggingPlay = true),
            onDragCompleted: () => setState(() => _isDraggingPlay = false),
            onDragCancelled: () => setState(() => _isDraggingPlay = false),
          ),

          // Botão para navegar para a página de configurações
          _buildSettingsButton(),
        ],
      ),
    );
  }

  /// Constrói um botão de controle arrastável para ações de cuidado.
  /// Inclui feedback visual para o estado de arrasto.
  Widget _buildDraggableControl({
    required IconData icon,
    required String label,
    required String data,
    required Color color,
    required bool isDragging,
    required VoidCallback onDragStarted,
    required VoidCallback onDragCompleted,
    required VoidCallback onDragCancelled,
  }) {
    return Draggable<String>(
      data: data,
      onDragStarted: onDragStarted,
      onDragCompleted: onDragCompleted,
      onDraggableCanceled: (velocity, offset) => onDragCancelled(),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withAlpha(76),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: color,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          icon,
          color: color.withAlpha(128),
          size: 30,
        ),
      ),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(76),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  /// Constrói o botão de configurações, que navega para a SettingsPage.
  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(76),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.settings,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  /// Constrói a área de entrada de chat com um campo de texto e botão de enviar.
  Widget _buildChatArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Campo de entrada expandido para mensagens de chat
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _chatController,
                enabled:
                    !_isChatLoading, // Desativa durante o carregamento do chat
                maxLength: 50, // Comprimento máximo para entrada
                decoration: InputDecoration(
                  hintText: LocalizationStrings.get('chat_placeholder'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  counterText: '', // Esconde contador de caracteres
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _handleChatMessage();
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 8), // Espaçamento entre entrada e botão

          // Botão de enviar para mensagens de chat
          GestureDetector(
            onTap: _isChatLoading
                ? null
                : () {
                    if (_chatController.text.isNotEmpty) {
                      _handleChatMessage();
                    }
                  },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _isChatLoading ? Colors.grey : Colors.blue,
                borderRadius: BorderRadius.circular(25),
              ),
              child: _isChatLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
