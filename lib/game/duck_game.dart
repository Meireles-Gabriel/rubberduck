// ignore_for_file: avoid_renaming_method_parameters, deprecated_member_use

import 'dart:async' as dart_async;
import 'dart:math';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/duck_status.dart';

/// Componente do jogo do pato usando engine Flame
class DuckGame extends FlameGame {
  // Referência ao estado do pato (Riverpod)
  DuckStatus? duckStatus;
  StateNotifierProvider<DuckStatusNotifier, DuckStatus>? duckStatusProvider;
  WidgetRef? ref;

  // Representa o sprite visual e as animações do pato no jogo
  DuckSprite? duckSprite;

  // Flag para indicar se o jogo foi completamente carregado
  bool _isLoaded = false;

  // Timer responsável por agendar animações aleatórias para o pato
  dart_async.Timer? randomAnimationTimer;

  // Função de callback para notificar componentes externos sobre mudanças no humor ou status do pato
  Function(String)? onStatusUpdate;

  DuckGame({this.duckStatus, this.duckStatusProvider, this.ref});

  /// Getter para verificar se o jogo foi completamente carregado
  bool get hasLoaded => _isLoaded;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final background = BackgroundComponent();
    await add(background);

    // Usa o estado do provider
    final status = duckStatus ?? ref?.read(duckStatusProvider!);
    duckSprite = DuckSprite(duckStatus: status!);
    await add(duckSprite!);

    // Aguarda um frame para garantir que a animação inicial seja carregada
    // e então reposiciona o sprite no centro
    await Future.delayed(Duration.zero);
    double centerX = (size.x - duckSprite!.size.x) / 2;
    double centerY = (size.y - duckSprite!.size.y) / 2;
    duckSprite!.position = Vector2(centerX, centerY);

    _isLoaded = true;
    startRandomAnimationTimer();
  }

  void startRandomAnimationTimer() {
    randomAnimationTimer?.cancel();

    void scheduleNextAnimation() {
      final delay = Duration(seconds: Random().nextInt(20) + 10);
      randomAnimationTimer = dart_async.Timer(delay, () {
        final status = duckStatus ?? ref?.read(duckStatusProvider!);
        if (status != null &&
            !status.isDead &&
            _isLoaded &&
            duckSprite != null) {
          duckSprite!.playRandomAnimation();
        }
        // Agenda a próxima animação aleatória
        if (status != null && !status.isDead) {
          scheduleNextAnimation();
        }
      });
    }

    scheduleNextAnimation();
  }

  // Métodos de animação para serem chamados externamente
  void playFeedAnimation() {
    if (_isLoaded && duckSprite != null) {
      duckSprite!.playAnimation('run');
    }
  }

  void playCleanAnimation() {
    if (_isLoaded && duckSprite != null) {
      duckSprite!.playAnimation('run');
    }
  }

  void playPlayAnimation() {
    if (_isLoaded && duckSprite != null) {
      duckSprite!.playAnimation('run');
    }
  }

  void playReviveAnimation() {
    if (_isLoaded && duckSprite != null) {
      duckSprite!.playAnimation('fly');
    }
  }

  void forceDeadAnimation() {
    if (_isLoaded && duckSprite != null) {
      duckSprite!.playAnimation('dead', force: true);
    }
    randomAnimationTimer?.cancel();
  }

  void forceReviveAnimation() {
    if (_isLoaded && duckSprite != null) {
      duckSprite!.playAnimation('fly', force: true);
    }
    startRandomAnimationTimer();
  }

  void playTalkAnimation() {
    if (_isLoaded && duckSprite != null) {
      duckSprite!.playAnimation('talk', force: true);
    }
  }

  void forceIdleAnimation() {
    if (_isLoaded && duckSprite != null) {
      duckSprite!.playAnimation('idle', force: true);
    }
  }

  /// Atualiza o status do sprite quando o estado do pato muda
  void updateSpriteStatus() {
    if (_isLoaded && duckSprite != null) {
      final currentStatus = duckStatus ?? ref?.read(duckStatusProvider!);
      if (currentStatus != null) {
        // Atualiza a referência do status no sprite
        // Note: Isso não é ideal, mas necessário devido à arquitetura atual
        duckSprite!.updateAnimationBasedOnStatus();
      }
    }
  }

  @override
  void onRemove() {
    randomAnimationTimer?.cancel();
    super.onRemove();
  }
}

/// Componente de background que se ajusta automaticamente ao tamanho do jogo
class BackgroundComponent extends SpriteComponent with HasGameRef<DuckGame> {
  @override
  Future<void> onLoad() async {
    super.onLoad();
    sprite = await Sprite.load('background.png');
    size = gameRef.size;
    position = Vector2.zero();
    priority = -1;
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
  }
}

/// Representa a aparência visual do pato e gerencia suas animações dentro do jogo.
class DuckSprite extends SpriteAnimationComponent
    with HasGameReference<DuckGame> {
  late Map<String, SpriteAnimation> animations;
  String currentAnimation = 'idle';
  final DuckStatus duckStatus;

  DuckSprite({required this.duckStatus});

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = Vector2(
      (gameSize.x - size.x) / 2,
      (gameSize.y - size.y) / 2,
    );
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await loadAnimations();
    playAnimation('idle');
  }

  Future<void> loadAnimations() async {
    animations = {};
    try {
      animations['idle'] =
          await _loadAnimation('duck_idle.png', 2, 0.3, loop: true);
      animations['blink'] =
          await _loadAnimation('duck_blink.png', 11, 0.3, loop: false);
      animations['fly'] =
          await _loadAnimation('duck_fly.png', 4, 0.15, loop: false);
      animations['look'] =
          await _loadAnimation('duck_look.png', 4, 0.5, loop: false);
      animations['run'] =
          await _loadAnimation('duck_run.png', 4, 0.2, loop: false);
      animations['talk'] =
          await _loadAnimation('duck_talk.png', 9, 0.15, loop: false);
      animations['dead'] =
          await _loadAnimation('duck_death.png', 4, 0.3, loop: true);
    } catch (e) {
      debugPrint(
          'Warning: Could not load duck sprites, using fallback animations');
      await loadFallbackAnimations();
    }
  }

  Future<SpriteAnimation> _loadAnimation(
      String filename, int frames, double stepTime,
      {bool loop = true}) async {
    final spriteSheet = await Flame.images.load('sprites/$filename');
    return SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: stepTime,
        textureSize: Vector2(220, 220),
        loop: loop,
      ),
    );
  }

  Future<void> loadFallbackAnimations() async {
    final fallbackSprite = await Sprite.load('ui/duck_fallback.png');
    final fallbackAnimation = SpriteAnimation.spriteList(
      [fallbackSprite],
      stepTime: 0.5,
      loop: true,
    );
    animations = {
      'idle': fallbackAnimation,
      'blink': fallbackAnimation,
      'fly': fallbackAnimation,
      'look': fallbackAnimation,
      'run': fallbackAnimation,
      'talk': fallbackAnimation,
      'dead': fallbackAnimation,
    };
  }

  void playAnimation(String animationName, {bool force = false}) {
    if (!animations.containsKey(animationName)) {
      animationName = 'idle';
    }

    // Não sobrescreve 'dead' se estiver morto, a menos que force
    if (duckStatus.isDead && animationName != 'dead' && !force) {
      return;
    }
    // Não sobrescreve 'talk' se já está falando, a menos que force
    if (currentAnimation == 'talk' && !force && animationName != 'dead') {
      return;
    }
    currentAnimation = animationName;
    animation = animations[animationName];
    size = Vector2(100, 100);

    // Reposiciona o sprite no centro após mudar o tamanho
    if (game.size.x > 0 && game.size.y > 0) {
      position = Vector2(
        (game.size.x - size.x) / 2,
        (game.size.y - size.y) / 2,
      );
    }
    if (animationTicker != null &&
        (animationName == 'blink' ||
            animationName == 'fly' ||
            animationName == 'look' ||
            animationName == 'run')) {
      animationTicker!.onComplete = () {
        // Para animação 'fly', sempre vai para 'idle' (usada na revivificação)
        if (animationName == 'fly') {
          playAnimation('idle', force: true);
        } else if (duckStatus.isDead) {
          playAnimation('dead', force: true);
        } else {
          playAnimation('idle', force: true);
        }
      };
    } else if (animationTicker != null && animationName == 'talk') {
      animationTicker!.onComplete = () {
        if (duckStatus.isDead) {
          playAnimation('dead', force: true);
        } else {
          playAnimation('idle', force: true);
        }
      };
    } else if (animationTicker != null) {
      animationTicker!.onComplete = null;
    }
  }

  void playRandomAnimation() {
    if (duckStatus.isDead) {
      playAnimation('dead');
      return;
    }
    final randomAnimations = ['blink', 'fly', 'look'];
    final randomAnimation =
        randomAnimations[Random().nextInt(randomAnimations.length)];
    playAnimation(randomAnimation);
  }

  void updateAnimationBasedOnStatus() {
    if (duckStatus.isDead) {
      playAnimation('dead');
      return;
    }
    // Se não está morto e não está em uma animação específica, vai para idle
    if (currentAnimation == 'dead') {
      playAnimation('idle', force: true);
    }
  }
}
