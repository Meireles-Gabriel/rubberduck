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
  late DuckSprite duckSprite;

  // Timer responsável por agendar animações aleatórias para o pato
  dart_async.Timer? randomAnimationTimer;

  // Função de callback para notificar componentes externos sobre mudanças no humor ou status do pato
  Function(String)? onStatusUpdate;

  DuckGame({this.duckStatus, this.duckStatusProvider, this.ref});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final background = BackgroundComponent();
    await add(background);

    // Usa o estado do provider
    final status = duckStatus ?? ref?.read(duckStatusProvider!);
    duckSprite = DuckSprite(duckStatus: status!);
    await add(duckSprite);

    double centerX = (size.x - duckSprite.size.x) / 2;
    double centerY = (size.y - duckSprite.size.y) / 2;
    duckSprite.position = Vector2(centerX, centerY);

    startRandomAnimationTimer();
  }

  void startRandomAnimationTimer() {
    randomAnimationTimer?.cancel();
    randomAnimationTimer = dart_async.Timer.periodic(
      Duration(seconds: Random().nextInt(20) + 10),
      (timer) {
        final status = duckStatus ?? ref?.read(duckStatusProvider!);
        if (status != null && !status.isDead) {
          duckSprite.playRandomAnimation();
        }
      },
    );
  }

  // Métodos de animação para serem chamados externamente
  void playFeedAnimation() {
    duckSprite.playAnimation('run');
  }

  void playCleanAnimation() {
    duckSprite.playAnimation('run');
  }

  void playPlayAnimation() {
    duckSprite.playAnimation('run');
  }

  void playReviveAnimation() {
    duckSprite.playAnimation('fly');
  }

  void forceDeadAnimation() {
    duckSprite.playAnimation('dead');
    randomAnimationTimer?.cancel();
  }

  void forceReviveAnimation() {
    duckSprite.playAnimation('fly');
    startRandomAnimationTimer();
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
          await _loadAnimation('duck_fly.png', 4, 0.2, loop: false);
      animations['look'] =
          await _loadAnimation('duck_look.png', 4, 0.5, loop: false);
      animations['run'] =
          await _loadAnimation('duck_run.png', 4, 0.2, loop: false);
      animations['talk'] =
          await _loadAnimation('duck_talk.png', 3, 0.3, loop: true);
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

  void playAnimation(String animationName) {
    if (!animations.containsKey(animationName)) {
      animationName = 'idle';
    }
    currentAnimation = animationName;
    animation = animations[animationName];
    size = Vector2(100, 100);
    if (animationTicker != null &&
        (animationName == 'blink' ||
            animationName == 'fly' ||
            animationName == 'look' ||
            animationName == 'run')) {
      animationTicker!.onComplete = () {
        if (duckStatus.isDead) {
          playAnimation('dead');
        } else {
          playAnimation('idle');
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
  }
}
