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

/// Main tamagotchi widget / Widget principal do tamagotchi
class TamagotchiWidget extends StatefulWidget {
  const TamagotchiWidget({super.key});

  @override
  State<TamagotchiWidget> createState() => _TamagotchiWidgetState();
}

class _TamagotchiWidgetState extends State<TamagotchiWidget>
    with TickerProviderStateMixin {
  // Game and status / Jogo e status
  late DuckGame duckGame;
  late DuckStatus duckStatus;
  late PeriodicTasksManager periodicTasks;

  // Controllers / Controladores
  final TextEditingController _chatController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();

  // State variables / Variáveis de estado
  String _currentBubbleMessage = '';
  bool _isBubbleVisible = false;
  bool _isChatLoading = false;
  bool _isDraggingFood = false;
  bool _isDraggingClean = false;
  bool _isDraggingPlay = false;

  // Animation controllers / Controladores de animação
  late AnimationController _bubbleAnimationController;
  late Animation<double> _bubbleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeWidget();
  }

  @override
  void dispose() {
    _chatController.dispose();
    periodicTasks.dispose();
    _bubbleAnimationController.dispose();
    super.dispose();
  }

  /// Initialize the widget / Inicializa o widget
  Future<void> _initializeWidget() async {
    // Initialize duck status / Inicializa status do pato
    duckStatus = DuckStatus();
    await duckStatus.loadFromPreferences();

    // Initialize game / Inicializa jogo
    duckGame = DuckGame();
    duckGame.duckStatus = duckStatus;
    duckGame.onStatusUpdate = _onStatusUpdate;

    // Initialize periodic tasks / Inicializa tarefas periódicas
    periodicTasks = PeriodicTasksManager();
    periodicTasks.onStatusUpdate = _onStatusUpdate;
    periodicTasks.onAutoComment = _onAutoComment;
    periodicTasks.onDeathDetected = _onDeathDetected;
    periodicTasks.initialize(duckStatus);

    // Initialize bubble animation / Inicializa animação do balão
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

    // Check initial status / Verifica status inicial
    _checkInitialStatus();
  }

  /// Check initial status and show messages / Verifica status inicial e mostra mensagens
  void _checkInitialStatus() {
    if (duckStatus.isDead) {
      // Show death dialog / Mostra diálogo de morte
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDeathDialog();
      });
    } else if (duckStatus.needsAttention) {
      // Show attention message / Mostra mensagem de atenção
      final message = duckStatus.getAttentionMessage();
      if (message != null) {
        _showBubbleMessage(LocalizationStrings.get(message));
      }
    }
  }

  /// Handle status updates / Gerencia atualizações de status
  void _onStatusUpdate(String mood) {
    if (mounted) {
      setState(() {
        // Update UI based on mood / Atualiza UI baseado no humor
        if (duckStatus.needsAttention) {
          final message = duckStatus.getAttentionMessage();
          if (message != null) {
            _showBubbleMessage(LocalizationStrings.get(message));
          }
        }
      });
    }
  }

  /// Handle auto comments / Gerencia comentários automáticos
  void _onAutoComment(String comment) {
    if (mounted) {
      _showBubbleMessage(comment);
    }
  }

  /// Handle death detection / Gerencia detecção de morte
  void _onDeathDetected() {
    if (mounted) {
      _showDeathDialog();
    }
  }

  /// Show death dialog / Mostra diálogo de morte
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

  /// Show bubble message / Mostra mensagem no balão
  void _showBubbleMessage(String message) {
    setState(() {
      _currentBubbleMessage = message;
      _isBubbleVisible = true;
    });

    // Animate bubble appearance / Anima aparição do balão
    _bubbleAnimationController.forward();

    // Hide bubble after delay / Esconde balão após delay
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

  /// Handle chat message / Gerencia mensagem de chat
  Future<void> _handleChatMessage() async {
    final message = _chatController.text.trim();

    // Validate message / Valida mensagem
    if (!ChatService.isMessageValid(message)) {
      final error = ChatService.getValidationError(message);
      _showBubbleMessage(error);
      return;
    }

    // Clear input / Limpa entrada
    _chatController.clear();

    // Show loading / Mostra carregamento
    setState(() {
      _isChatLoading = true;
    });
    _showBubbleMessage(LocalizationStrings.get('thinking'));

    try {
      // Send message to ChatGPT / Envia mensagem para ChatGPT
      final response =
          await ChatService.sendMessage(message, includeScreenshot: true);

      // Show response / Mostra resposta
      _showBubbleMessage(response);
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      _showBubbleMessage(LocalizationStrings.get('error_chat'));
    } finally {
      setState(() {
        _isChatLoading = false;
      });
    }
  }

  /// Handle care actions / Gerencia ações de cuidado
  Future<void> _handleCareAction(String action) async {
    if (duckStatus.isDead) return;

    switch (action) {
      case 'feed':
        await duckGame.feedDuck();
        _showBubbleMessage(LocalizationStrings.get('fed_message'));
        break;
      case 'clean':
        await duckGame.cleanDuck();
        _showBubbleMessage(LocalizationStrings.get('cleaned_message'));
        break;
      case 'play':
        await duckGame.playWithDuck();
        _showBubbleMessage(LocalizationStrings.get('played_message'));
        break;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Bubble message area / Área de mensagem do balão
              _buildBubbleArea(),

              // Main game area / Área principal do jogo
              Expanded(
                child: Row(
                  children: [
                    // Duck area / Área do pato
                    Expanded(
                      flex: 2,
                      child: _buildDuckArea(),
                    ),

                    // Controls area / Área de controles
                    Expanded(
                      flex: 1,
                      child: _buildControlsArea(),
                    ),
                  ],
                ),
              ),

              // Chat area / Área de chat
              _buildChatArea(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build bubble message area / Constrói área de mensagem do balão
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
                          color: Colors.black.withValues(alpha: 0.1),
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
          : const SizedBox.shrink(),
    );
  }

  /// Build duck area / Constrói área do pato
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
        onWillAcceptWithDetails: (details) {
          return details.data == 'food' ||
              details.data == 'clean' ||
              details.data == 'play';
        },
        onAcceptWithDetails: (data) {
          _handleCareAction(data.data);
        },
        builder: (context, candidateData, rejectedData) {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: candidateData.isNotEmpty
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.green.withValues(alpha: 0.2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.pets,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                  )
                : GameWidget(game: duckGame),
          );
        },
      ),
    );
  }

  /// Build controls area / Constrói área de controles
  Widget _buildControlsArea() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Food control / Controle de comida
          _buildDraggableControl(
            icon: Icons.restaurant,
            label: LocalizationStrings.get('feed'),
            data: 'food',
            color: Colors.orange,
            isDragging: _isDraggingFood,
            onDragStarted: () => setState(() => _isDraggingFood = true),
            onDragCompleted: () => setState(() => _isDraggingFood = false),
            onDragCancelled: () => setState(() => _isDraggingFood = false),
          ),

          // Clean control / Controle de limpeza
          _buildDraggableControl(
            icon: Icons.cleaning_services,
            label: LocalizationStrings.get('clean'),
            data: 'clean',
            color: Colors.blue,
            isDragging: _isDraggingClean,
            onDragStarted: () => setState(() => _isDraggingClean = true),
            onDragCompleted: () => setState(() => _isDraggingClean = false),
            onDragCancelled: () => setState(() => _isDraggingClean = false),
          ),

          // Play control / Controle de brincar
          _buildDraggableControl(
            icon: Icons.sports_esports,
            label: LocalizationStrings.get('play'),
            data: 'play',
            color: Colors.purple,
            isDragging: _isDraggingPlay,
            onDragStarted: () => setState(() => _isDraggingPlay = true),
            onDragCompleted: () => setState(() => _isDraggingPlay = false),
            onDragCancelled: () => setState(() => _isDraggingPlay = false),
          ),

          // Settings button / Botão de configurações
          _buildSettingsButton(),
        ],
      ),
    );
  }

  /// Build draggable control / Constrói controle arrastável
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
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: color,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          icon,
          color: color.withValues(alpha: 0.5),
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
              color: color.withValues(alpha: 0.3),
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

  /// Build settings button / Constrói botão de configurações
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
              color: Colors.grey.withValues(alpha: 0.3),
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

  /// Build chat area / Constrói área de chat
  Widget _buildChatArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Chat input field / Campo de entrada de chat
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
                enabled: !_isChatLoading,
                maxLength: 50,
                decoration: InputDecoration(
                  hintText: LocalizationStrings.get('chat_placeholder'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  counterText:
                      '', // Hide character counter / Esconde contador de caracteres
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _handleChatMessage();
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button / Botão de enviar
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
