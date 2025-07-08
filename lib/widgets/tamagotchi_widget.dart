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

/// State class for TamagotchiWidget / Classe de estado para TamagotchiWidget
class _TamagotchiWidgetState extends State<TamagotchiWidget>
    with TickerProviderStateMixin {
  // Game and status related objects / Objetos relacionados ao jogo e status
  late DuckGame duckGame;
  late DuckStatus duckStatus;
  late PeriodicTasksManager periodicTasks;

  // Controllers for text input and screenshot / Controladores para entrada de texto e captura de tela
  final TextEditingController _chatController = TextEditingController();
  final ScreenshotController _screenshotController = ScreenshotController();

  // State variables for UI elements / Variáveis de estado para elementos da UI
  String _currentBubbleMessage = '';
  bool _isBubbleVisible = false;
  bool _isChatLoading = false;
  bool _isDraggingFood = false;
  bool _isDraggingClean = false;
  bool _isDraggingPlay = false;

  // Animation controllers for bubble message / Controladores de animação para mensagem de balão
  late AnimationController _bubbleAnimationController;
  late Animation<double> _bubbleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize the widget's state / Inicializa o estado do widget
    _initializeWidget();
  }

  @override
  void dispose() {
    // Dispose controllers and periodic tasks / Descarta controladores e tarefas periódicas
    _chatController.dispose();
    periodicTasks.dispose();
    _bubbleAnimationController.dispose();
    super.dispose();
  }

  /// Initializes all necessary components for the widget, including duck status, game,
  /// periodic tasks, and bubble animation.
  ///
  /// Inicializa todos os componentes necessários para o widget, incluindo status do pato, jogo,
  /// tarefas periódicas e animação do balão.
  Future<void> _initializeWidget() async {
    // Initialize duck status and load from preferences / Inicializa status do pato e carrega das preferências
    duckStatus = DuckStatus();
    await duckStatus.loadFromPreferences();

    // Initialize game and link with duck status / Inicializa jogo e vincula com status do pato
    duckGame = DuckGame();
    duckGame.duckStatus = duckStatus;
    duckGame.onStatusUpdate = _onStatusUpdate;

    // Initialize periodic tasks manager and link callbacks / Inicializa gerenciador de tarefas periódicas e vincula callbacks
    periodicTasks = PeriodicTasksManager();
    periodicTasks.onStatusUpdate = _onStatusUpdate;
    periodicTasks.onAutoComment = _onAutoComment;
    periodicTasks.onDeathDetected = _onDeathDetected;
    periodicTasks.initialize(duckStatus);

    // Set up bubble animation controller and tween / Configura controlador de animação e interpolação do balão
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

    // Perform initial status check / Realiza verificação de status inicial
    _checkInitialStatus();
  }

  /// Checks the duck's initial status upon widget initialization.
  /// Displays death dialog if the duck is dead, or an attention message if needed.
  ///
  /// Verifica o status inicial do pato na inicialização do widget.
  /// Exibe o diálogo de morte se o pato estiver morto, ou uma mensagem de atenção se necessário.
  void _checkInitialStatus() {
    if (duckStatus.isDead) {
      // Show death dialog after frame is built / Mostra diálogo de morte após a construção do frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDeathDialog();
      });
    } else if (duckStatus.needsAttention) {
      // Get and show attention message if duck needs attention / Obtém e mostra mensagem de atenção se o pato precisar de atenção
      final message = duckStatus.getAttentionMessage();
      if (message != null) {
        _showBubbleMessage(LocalizationStrings.get(message));
      }
    }
  }

  /// Callback function to handle updates in duck's status.
  /// Updates the UI and shows a bubble message if the duck needs attention.
  ///
  /// Função de callback para lidar com atualizações no status do pato.
  /// Atualiza a interface do usuário e mostra uma mensagem de balão se o pato precisar de atenção.
  void _onStatusUpdate(String mood) {
    if (mounted) {
      setState(() {
        // Update UI based on duck's mood / Atualiza UI com base no humor do pato
        if (duckStatus.needsAttention) {
          final message = duckStatus.getAttentionMessage();
          if (message != null) {
            _showBubbleMessage(LocalizationStrings.get(message));
          }
        }
      });
    }
  }

  /// Callback function to handle automatic comments from the duck.
  /// Displays the comment in the bubble message area.
  ///
  /// Função de callback para lidar com comentários automáticos do pato.
  /// Exibe o comentário na área da mensagem do balão.
  void _onAutoComment(String comment) {
    if (mounted) {
      _showBubbleMessage(comment);
    }
  }

  /// Callback function to handle detection of the duck's death.
  /// Triggers the display of the death dialog.
  ///
  /// Função de callback para lidar com a detecção da morte do pato.
  /// Aciona a exibição do diálogo de morte.
  void _onDeathDetected() {
    if (mounted) {
      _showDeathDialog();
    }
  }

  /// Displays the death and revival system dialog.
  /// Upon revival, updates the duck's status and shows a happy message.
  ///
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

  /// Shows a message in the duck's speech bubble.
  /// The bubble appears with an animation and hides after a delay.
  ///
  /// Mostra uma mensagem no balão de fala do pato.
  /// O balão aparece com uma animação e se esconde após um atraso.
  void _showBubbleMessage(String message) {
    setState(() {
      _currentBubbleMessage = message;
      _isBubbleVisible = true;
    });

    // Start bubble appearance animation / Inicia animação de aparição do balão
    _bubbleAnimationController.forward();

    // Set a timer to hide the bubble after 5 seconds / Define um temporizador para esconder o balão após 5 segundos
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

  /// Handles sending a chat message to the ChatGPT service.
  /// Validates the message, shows loading state, sends the message, and displays the response or error.
  ///
  /// Gerencia o envio de uma mensagem de chat para o serviço ChatGPT.
  /// Valida a mensagem, mostra o estado de carregamento, envia a mensagem e exibe a resposta ou erro.
  Future<void> _handleChatMessage() async {
    final message = _chatController.text.trim();

    // Validate the chat message / Valida a mensagem de chat
    if (!ChatService.isMessageValid(message)) {
      final error = ChatService.getValidationError(message);
      _showBubbleMessage(error);
      return;
    }

    // Clear the chat input field / Limpa o campo de entrada do chat
    _chatController.clear();

    // Show loading indicator and "thinking" message / Mostra indicador de carregamento e mensagem "pensando"
    setState(() {
      _isChatLoading = true;
    });
    _showBubbleMessage(LocalizationStrings.get('thinking'));

    try {
      // Send message to ChatGPT with screenshot / Envia mensagem para ChatGPT com captura de tela
      final response =
          await ChatService.sendMessage(message, includeScreenshot: true);

      // Display the response from ChatGPT / Exibe a resposta do ChatGPT
      _showBubbleMessage(response);
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      // Show error message if chat fails / Mostra mensagem de erro se o chat falhar
      _showBubbleMessage(LocalizationStrings.get('error_chat'));
    } finally {
      setState(() {
        _isChatLoading = false;
      });
    }
  }

  /// Handles care actions such as feeding, cleaning, or playing with the duck.
  /// Prevents actions if the duck is dead and shows a confirmation message.
  ///
  /// Lida com ações de cuidado como alimentar, limpar ou brincar com o pato.
  /// Impede ações se o pato estiver morto e mostra uma mensagem de confirmação.
  Future<void> _handleCareAction(String action) async {
    if (duckStatus.isDead)
      return; // Do nothing if the duck is dead / Não faz nada se o pato estiver morto

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

    setState(() {}); // Trigger UI refresh / Aciona a atualização da UI
  }

  @override
  Widget build(BuildContext context) {
    // Screenshot widget to capture the entire screen / Widget de captura de tela para capturar a tela inteira
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Speech bubble message area / Área de mensagem do balão de fala
              _buildBubbleArea(),

              // Main game area with duck and controls / Área principal do jogo com pato e controles
              Expanded(
                child: Row(
                  children: [
                    // Duck display area / Área de exibição do pato
                    Expanded(
                      flex: 2,
                      child: _buildDuckArea(),
                    ),

                    // Controls for care actions / Controles para ações de cuidado
                    Expanded(
                      flex: 1,
                      child: _buildControlsArea(),
                    ),
                  ],
                ),
              ),

              // Chat input and send area / Área de entrada e envio de chat
              _buildChatArea(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the animated speech bubble area for displaying messages.
  ///
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
                          color: Colors.black.withOpacity(0.1),
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
          : const SizedBox
              .shrink(), // Hide if not visible / Esconde se não visível
    );
  }

  /// Builds the interactive area where the duck game is displayed.
  /// Allows dropping care items onto the duck.
  ///
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
        // Defines accepted data types for dragging / Define tipos de dados aceitos para arrastar
        onWillAcceptWithDetails: (details) {
          return details.data == 'food' ||
              details.data == 'clean' ||
              details.data == 'play';
        },
        // Handles accepted drop action / Lida com a ação de soltar aceita
        onAcceptWithDetails: (data) {
          _handleCareAction(data.data);
        },
        builder: (context, candidateData, rejectedData) {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: candidateData.isNotEmpty
                ? Container(
                    // Visual feedback when item is dragged over / Feedback visual quando um item é arrastado por cima
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.green.withOpacity(0.2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.pets,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                  )
                : GameWidget(
                    game:
                        duckGame), // Display the game widget / Exibe o widget do jogo
          );
        },
      ),
    );
  }

  /// Builds the area containing controls for feeding, cleaning, playing, and settings.
  ///
  /// Constrói a área contendo controles para alimentar, limpar, brincar e configurações.
  Widget _buildControlsArea() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Draggable control for feeding the duck / Controle arrastável para alimentar o pato
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

          // Draggable control for cleaning the duck / Controle arrastável para limpar o pato
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

          // Draggable control for playing with the duck / Controle arrastável para brincar com o pato
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

          // Button to navigate to settings page / Botão para navegar para a página de configurações
          _buildSettingsButton(),
        ],
      ),
    );
  }

  /// Builds a draggable control button for care actions.
  /// Includes visual feedback for dragging state.
  ///
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
          color: color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: color,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          icon,
          color: color.withOpacity(0.5),
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
              color: color.withOpacity(0.3),
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

  /// Builds the settings button, which navigates to the SettingsPage.
  ///
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
              color: Colors.grey.withOpacity(0.3),
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

  /// Builds the chat input area with a text field and send button.
  ///
  /// Constrói a área de entrada de chat com um campo de texto e botão de enviar.
  Widget _buildChatArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Expanded input field for chat messages / Campo de entrada expandido para mensagens de chat
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
                    !_isChatLoading, // Disable during chat loading / Desativa durante o carregamento do chat
                maxLength:
                    50, // Maximum length for input / Comprimento máximo para entrada
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

          const SizedBox(
              width:
                  8), // Spacing between input and button / Espaçamento entre entrada e botão

          // Send button for chat messages / Botão de enviar para mensagens de chat
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
