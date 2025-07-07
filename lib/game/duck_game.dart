import 'dart:async' as dart_async;
import 'dart:math';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'duck_status.dart';

/// Duck game component using Flame engine / Componente do jogo do pato usando engine Flame
class DuckGame extends FlameGame {
  // Duck component / Componente do pato
  late DuckSprite duckSprite;

  // Status reference / Referência do status
  late DuckStatus duckStatus;

  // Animation timer / Timer de animação
  dart_async.Timer? randomAnimationTimer;

  // Callback for status updates / Callback para atualizações de status
  Function(String)? onStatusUpdate;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Initialize duck status / Inicializa status do pato
    duckStatus = DuckStatus();
    await duckStatus.loadFromPreferences();

    // Create duck sprite / Cria sprite do pato
    duckSprite = DuckSprite(duckStatus: duckStatus);
    await add(duckSprite);

    // Position duck in center-left / Posiciona pato no centro-esquerdo
    duckSprite.position = Vector2(size.x * 0.3, size.y * 0.5);

    // Start random animation timer / Inicia timer de animação aleatória
    startRandomAnimationTimer();
  }

  /// Start random animation timer / Inicia timer de animação aleatória
  void startRandomAnimationTimer() {
    randomAnimationTimer?.cancel();
    randomAnimationTimer = dart_async.Timer.periodic(
      Duration(
          seconds: Random().nextInt(20) + 10), // 10-30 seconds / 10-30 segundos
      (timer) {
        if (!duckStatus.isDead) {
          duckSprite.playRandomAnimation();
        }
      },
    );
  }

  /// Update duck status / Atualiza status do pato
  Future<void> updateDuckStatus() async {
    await duckStatus.updateStatus();
    onStatusUpdate?.call(duckStatus.getMood());
  }

  /// Feed the duck / Alimenta o pato
  Future<void> feedDuck() async {
    if (duckStatus.isDead) return;

    await duckStatus.feed();
    duckSprite.playAnimation('feed');
    onStatusUpdate?.call(duckStatus.getMood());
  }

  /// Clean the duck / Limpa o pato
  Future<void> cleanDuck() async {
    if (duckStatus.isDead) return;

    await duckStatus.clean();
    duckSprite.playAnimation('clean');
    onStatusUpdate?.call(duckStatus.getMood());
  }

  /// Play with the duck / Brinca com o pato
  Future<void> playWithDuck() async {
    if (duckStatus.isDead) return;

    await duckStatus.play();
    duckSprite.playAnimation('play');
    onStatusUpdate?.call(duckStatus.getMood());
  }

  /// Revive the duck / Revive o pato
  Future<void> reviveDuck() async {
    await duckStatus.revive();
    duckSprite.playAnimation('revive');
    onStatusUpdate?.call(duckStatus.getMood());
  }

  @override
  void onRemove() {
    randomAnimationTimer?.cancel();
    super.onRemove();
  }
}

/// Duck sprite component / Componente sprite do pato
class DuckSprite extends SpriteAnimationComponent
    with HasGameReference<DuckGame> {
  // Animation components / Componentes de animação
  late Map<String, SpriteAnimation> animations;

  // Current animation state / Estado atual da animação
  String currentAnimation = 'idle';

  // Duck status reference / Referência do status do pato
  final DuckStatus duckStatus;

  DuckSprite({required this.duckStatus});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load all animations / Carrega todas as animações
    await loadAnimations();

    // Set initial animation / Define animação inicial
    playAnimation('idle');
  }

  /// Load all duck animations / Carrega todas as animações do pato
  Future<void> loadAnimations() async {
    animations = {};

    try {
      // Load idle animation (default) / Carrega animação idle (padrão)
      animations['idle'] = await _loadAnimation('duck_idle.png', 4, 0.5);

      // Load care animations / Carrega animações de cuidado
      animations['feed'] = await _loadAnimation('duck_feed.png', 6, 0.3);
      animations['clean'] = await _loadAnimation('duck_clean.png', 6, 0.3);
      animations['play'] = await _loadAnimation('duck_play.png', 8, 0.25);

      // Load death animation / Carrega animação de morte
      animations['death'] = await _loadAnimation('duck_death.png', 4, 0.6);

      // Load special animations / Carrega animações especiais
      animations['revive'] = await _loadAnimation('duck_revive.png', 6, 0.4);
      animations['happy'] = await _loadAnimation('duck_happy.png', 4, 0.4);
      animations['sleep'] = await _loadAnimation('duck_sleep.png', 2, 1.0);
    } catch (e) {
      debugPrint(
          'Warning: Could not load duck sprites, using fallback animations');
      await loadFallbackAnimations();
    }
  }

  /// Load animation from sprite sheet / Carrega animação de sprite sheet
  Future<SpriteAnimation> _loadAnimation(
      String filename, int frames, double stepTime) async {
    final spriteSheet = await Flame.images.load('sprites/$filename');

    return SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: stepTime,
        textureSize:
            Vector2.all(64), // Assuming 64x64 sprites / Assumindo sprites 64x64
      ),
    );
  }

  /// Load fallback animations (colored rectangles) / Carrega animações fallback (retângulos coloridos)
  Future<void> loadFallbackAnimations() async {
    // Create simple colored sprite for fallback / Cria sprite colorido simples para fallback
    final fallbackSprite = await Sprite.load('ui/duck_fallback.png');

    // Create basic animation from single sprite / Cria animação básica de sprite único
    final fallbackAnimation = SpriteAnimation.spriteList(
      [fallbackSprite],
      stepTime: 0.5,
    );

    // Apply to all animations / Aplica para todas as animações
    animations = {
      'idle': fallbackAnimation,
      'feed': fallbackAnimation,
      'clean': fallbackAnimation,
      'play': fallbackAnimation,
      'death': fallbackAnimation,
      'revive': fallbackAnimation,
      'happy': fallbackAnimation,
      'sleep': fallbackAnimation,
    };
  }

  /// Play specific animation / Reproduz animação específica
  void playAnimation(String animationName) {
    if (!animations.containsKey(animationName)) {
      animationName = 'idle'; // Fallback to idle / Fallback para idle
    }

    currentAnimation = animationName;
    animation = animations[animationName];

    // Set size / Define tamanho
    size = Vector2.all(80);

    // Handle animation completion / Gerencia conclusão da animação
    if (animationName != 'idle' &&
        animationName != 'death' &&
        animationName != 'sleep') {
      animationTicker?.onComplete = () {
        if (duckStatus.isDead) {
          playAnimation('death');
        } else {
          playAnimation('idle');
        }
      };
    }
  }

  /// Play random animation / Reproduz animação aleatória
  void playRandomAnimation() {
    if (duckStatus.isDead) {
      playAnimation('death');
      return;
    }

    // List of random animations / Lista de animações aleatórias
    final randomAnimations = ['happy', 'sleep'];
    final randomAnimation =
        randomAnimations[Random().nextInt(randomAnimations.length)];

    playAnimation(randomAnimation);
  }

  /// Update animation based on duck status / Atualiza animação baseada no status do pato
  void updateAnimationBasedOnStatus() {
    if (duckStatus.isDead) {
      playAnimation('death');
      return;
    }

    // Play attention-seeking animation if needed / Reproduz animação de busca de atenção se necessário
    if (duckStatus.needsAttention && currentAnimation == 'idle') {
      final attentionMessage = duckStatus.getAttentionMessage();
      if (attentionMessage != null) {
        // Play subtle animation to get attention / Reproduz animação sutil para chamar atenção
        playAnimation('happy');
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update animation based on status / Atualiza animação baseada no status
    updateAnimationBasedOnStatus();
  }
}
