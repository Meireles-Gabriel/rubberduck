import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/duck_game.dart';
import '../game/duck_status.dart';
import '../services/chat_service.dart';
import '../services/periodic_tasks.dart';
import '../utils/localization_strings.dart';
import 'settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flame_audio/flame_audio.dart';

/// Widget principal do tamagotchi
class TamagotchiWidget extends ConsumerStatefulWidget {
  const TamagotchiWidget({super.key});

  static final ValueNotifier<String> duckNameNotifier =
      ValueNotifier<String>('');

  @override
  ConsumerState<TamagotchiWidget> createState() => TamagotchiWidgetState();
}

class TamagotchiWidgetState extends ConsumerState<TamagotchiWidget>
    with TickerProviderStateMixin {
  // Objetos relacionados ao jogo e status
  late DuckGame duckGame;
  late PeriodicTasksManager periodicTasks;
  bool _isInitialized = false;
  bool _talkAnimationPlayed = false;

  // Controladores para entrada de texto e captura de tela
  final TextEditingController _chatController = TextEditingController();

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

  ValueNotifier<String> get duckNameNotifier =>
      TamagotchiWidget.duckNameNotifier;

  @override
  void initState() {
    super.initState();
    _initializeWidget();
    _loadDuckName();
  }

  Future<void> _loadDuckName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('duck_name') ?? '';
    duckNameNotifier.value = name;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDuckName();
  }

  @override
  void dispose() {
    duckNameNotifier.dispose();
    _chatController.dispose();
    periodicTasks.dispose();
    _bubbleAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeWidget() async {
    // Inicializa jogo e vincula com status do pato
    duckGame = DuckGame(duckStatus: ref.read(duckStatusProvider));
    // Inicializa gerenciador de tarefas periódicas e vincula callbacks
    periodicTasks = PeriodicTasksManager();
    periodicTasks.onAutoComment = _onAutoComment;
    periodicTasks.onDeathDetected = _onDeathDetected;
    periodicTasks.initialize(ref.read(duckStatusProvider.notifier));

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

    _checkInitialStatus();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _checkInitialStatus() {
    final duckStatus = ref.read(duckStatusProvider);
    if (duckStatus.isDead) {
      duckGame.forceDeadAnimation();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDeathDialog();
      });
    }
  }

  void _onAutoComment(String comment) {
    if (mounted) {
      _showBubbleMessage(comment);
    }
  }

  void _onDeathDetected() {
    if (mounted) {
      duckGame.forceDeadAnimation();
      _showDeathDialog();
    }
  }

  void _showDeathDialog() {
    final duckStatus = ref.read(duckStatusProvider);

    String deathMessage;
    switch (duckStatus.deathCause) {
      case 'hunger':
        deathMessage = LocalizationStrings.get('died_hunger');
        break;
      case 'dirty':
        deathMessage = LocalizationStrings.get('died_dirty');
        break;
      case 'sadness':
        deathMessage = LocalizationStrings.get('died_sadness');
        break;
      default:
        deathMessage = LocalizationStrings.get('died_hunger');
    }
    _showBubbleMessage(deathMessage, animationOverride: 'dead');
    duckGame.forceDeadAnimation();
  }

  void _showBubbleMessage(String message, {String? animationOverride}) {
    FlameAudio.play('quack.wav');
    final wasVisible = _isBubbleVisible;
    setState(() {
      _isBubbleVisible = false;
      if (!wasVisible) _talkAnimationPlayed = false;
    });
    // Pequeno delay para garantir que o balão anterior suma antes de exibir o novo
    Future.delayed(const Duration(milliseconds: 50), () {
      if (animationOverride == 'run') {
        duckGame.playPlayAnimation();
      } else if (animationOverride == 'dead') {
        duckGame.forceDeadAnimation();
      } else if (!_talkAnimationPlayed) {
        duckGame.playTalkAnimation();
        _talkAnimationPlayed = true;
      }
      setState(() {
        _currentBubbleMessage = message;
        _isBubbleVisible = true;
      });
      _bubbleAnimationController.forward();
      Timer(const Duration(seconds: 30), () {
        if (mounted) {
          _bubbleAnimationController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _isBubbleVisible = false;
                _talkAnimationPlayed = false;
              });
              duckGame.forceIdleAnimation();
            }
          });
        }
      });
    });
  }

  Future<void> _handleChatMessage() async {
    final message = _chatController.text.trim();
    if (!ChatService.isMessageValid(message)) {
      final error = ChatService.getValidationError(message);
      _showBubbleMessage(error);
      return;
    }
    _chatController.clear();
    setState(() {
      _isChatLoading = true;
    });
    try {
      final response =
          await ChatService.sendMessage(message, includeScreenshot: true);
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

  Future<void> _handleCareAction(String action) async {
    final notifier = ref.read(duckStatusProvider.notifier);
    final duckStatus = ref.read(duckStatusProvider);
    if (duckStatus.isDead) return;
    switch (action) {
      case 'feed':
        notifier.feed();
        _showBubbleMessage(LocalizationStrings.get('fed_message'),
            animationOverride: 'run');
        break;
      case 'clean':
        notifier.clean();
        _showBubbleMessage(LocalizationStrings.get('cleaned_message'),
            animationOverride: 'run');
        break;
      case 'play':
        notifier.play();
        _showBubbleMessage(LocalizationStrings.get('played_message'),
            animationOverride: 'run');
        break;
    }
  }

  Color _getStatusColor(double value) {
    const goodColor = Color(0xFF98D8A0);
    const badColor = Color(0xFFE8A39D);
    final t = value / 100;
    return Color.lerp(badColor, goodColor, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final duckStatus = ref.watch(duckStatusProvider);
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: const Color(0xFFE6F3FF),
      body: Container(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            _buildBubbleArea(),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildDuckArea(),
                  ),
                  Expanded(
                    flex: 1,
                    child: _buildControlsArea(duckStatus),
                  ),
                ],
              ),
            ),
            _buildChatArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildBubbleArea() {
    return Container(
      height: 40,
      alignment: Alignment.center,
      child: _isBubbleVisible
          ? AnimatedBuilder(
              animation: _bubbleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bubbleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    child: SizedBox(
                      width: 160,
                      height: 50,
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            child: Text(
                              _currentBubbleMessage,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDuckArea() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 4,
        ),
      ),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          return details.data == 'feed' ||
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
                : Stack(children: [
                    SizedBox.expand(
                      child: GameWidget(
                        game: duckGame,
                        backgroundBuilder: (context) => Container(
                          color: Colors.lightBlue.shade50,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ValueListenableBuilder<String>(
                          valueListenable: duckNameNotifier,
                          builder: (context, duckName, _) {
                            return Text(
                              duckName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE0A44B),
                                shadows: [
                                  Shadow(
                                    blurRadius: 2,
                                    color: Color(0xFF80492C),
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ]),
          );
        },
      ),
    );
  }

  Widget _buildControlsArea(DuckStatus duckStatus) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
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
          _buildSettingsButton(),
        ],
      ),
    );
  }

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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withAlpha(76),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          icon,
          color: color.withAlpha(128),
          size: 16,
        ),
      ),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
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
          size: 16,
        ),
      ),
    );
  }

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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          borderRadius: BorderRadius.circular(16),
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
          size: 16,
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    final duckStatus = ref.watch(duckStatusProvider);
    if (duckStatus.isDead) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        width: double.infinity,
        child: Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.favorite, color: Colors.white),
            label: Text(LocalizationStrings.get('revive'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              ref.read(duckStatusProvider.notifier).revive();
              duckGame.forceReviveAnimation();
              setState(() {
                _showBubbleMessage(LocalizationStrings.get('happy'));
              });
            },
          ),
        ),
      );
    }
    // Chat normal
    return Container(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          SizedBox(
            width: 137,
            child: Container(
              height: 35,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _chatController,
                enabled: !_isChatLoading,
                maxLength: 50,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: LocalizationStrings.get('chat_placeholder'),
                  hintStyle: const TextStyle(fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  counterText: '',
                  isDense: true,
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
          GestureDetector(
            onTap: _isChatLoading
                ? null
                : () {
                    if (_chatController.text.isNotEmpty) {
                      _handleChatMessage();
                    }
                  },
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: _isChatLoading ? Colors.grey : Colors.blue,
                borderRadius: BorderRadius.circular(17.5),
              ),
              child: _isChatLoading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
