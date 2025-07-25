// ignore_for_file: avoid_renaming_method_parameters, deprecated_member_use

import 'dart:async' as dart_async;
import 'dart:math';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../game/duck_status.dart';

/// Componente principal do jogo que gerencia as animações e comportamentos visuais do pet
/// Flame engine necessária para performance suave de animações e controle de sprites
class DuckGame extends FlameGame {
  // Referências ao estado compartilhado para sincronização entre UI e animações
  DuckStatus? duckStatus;
  StateNotifierProvider<DuckStatusNotifier, DuckStatus>? duckStatusProvider;
  WidgetRef? ref;

  // Sprite principal que renderiza as animações do pato na tela
  DuckSprite? duckSprite;

  // Flag crítica para evitar operações em jogo não inicializado
  bool _isLoaded = false;

  // Timer para animações periódicas que dão vida ao pet quando idle
  dart_async.Timer? randomAnimationTimer;

  // Callback para comunicação com sistema de mensagens/UI externa
  Function(String)? onStatusUpdate;

  DuckGame({this.duckStatus, this.duckStatusProvider, this.ref});

  /// Verificação essencial para garantir segurança nas operações do jogo
  bool get hasLoaded => _isLoaded;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Background necessário para dar contexto visual e delimitar área do pet
    final background = BackgroundComponent();
    await add(background);

    // Inicialização do sprite principal com estado atual para sincronização
    final status = duckStatus ?? ref?.read(duckStatusProvider!);
    duckSprite = DuckSprite(duckStatus: status!);
    await add(duckSprite!);

    // Delay necessário para garantir que Flame calcule tamanhos antes de posicionar
    await Future.delayed(Duration.zero);
    double centerX = (size.x - duckSprite!.size.x) / 2;
    double centerY = (size.y - duckSprite!.size.y) / 2;
    duckSprite!.position = Vector2(centerX, centerY);

    _isLoaded = true;
    // Inicia animações aleatórias para dar vida ao pet quando não está sendo usado
    startRandomAnimationTimer();
  }

  void startRandomAnimationTimer() {
    randomAnimationTimer?.cancel();

    void scheduleNextAnimation() {
      final delay = Duration(seconds: Random().nextInt(20) + 10);
      randomAnimationTimer = dart_async.Timer(delay, () {
        final status = duckStatus ?? ref?.read(duckStatusProvider!);
        debugPrint(
            '[DuckGame] Timer de animação aleatória ativado - isDead: ${status?.isDead}');
        if (status != null &&
            !status.isDead &&
            _isLoaded &&
            duckSprite != null) {
          duckSprite!.playRandomAnimation();
        }
        // Agenda a próxima animação aleatória APENAS se o pato estiver vivo
        if (status != null && !status.isDead) {
          scheduleNextAnimation();
        } else {
          debugPrint(
              '[DuckGame] Timer de animação aleatória parado - pato morto');
        }
      });
    }

    // Só inicia o timer se o pato estiver vivo
    final currentStatus = duckStatus ?? ref?.read(duckStatusProvider!);
    if (currentStatus != null && !currentStatus.isDead) {
      debugPrint('[DuckGame] Iniciando timer de animações aleatórias');
      scheduleNextAnimation();
    } else {
      debugPrint('[DuckGame] Não iniciando timer - pato morto');
    }
  }

  // Métodos de animação para serem chamados externamente
  void playFeedAnimation() {
    if (_isLoaded && duckSprite != null) {
      final currentStatus = duckStatus ?? ref?.read(duckStatusProvider!);
      debugPrint(
          '[DuckGame] playFeedAnimation - isDead: ${currentStatus?.isDead}');
      if (currentStatus != null && !currentStatus.isDead) {
        duckSprite!.playAnimation('run');
      }
    }
  }

  void playCleanAnimation() {
    if (_isLoaded && duckSprite != null) {
      final currentStatus = duckStatus ?? ref?.read(duckStatusProvider!);
      debugPrint(
          '[DuckGame] playCleanAnimation - isDead: ${currentStatus?.isDead}');
      if (currentStatus != null && !currentStatus.isDead) {
        duckSprite!.playAnimation('run');
      }
    }
  }

  void playPlayAnimation() {
    if (_isLoaded && duckSprite != null) {
      final currentStatus = duckStatus ?? ref?.read(duckStatusProvider!);
      debugPrint(
          '[DuckGame] playPlayAnimation - isDead: ${currentStatus?.isDead}');
      if (currentStatus != null && !currentStatus.isDead) {
        duckSprite!.playAnimation('run');
      }
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
      // CRÍTICO: Atualiza o status ANTES de qualquer coisa
      final currentStatus = duckStatus ?? ref?.read(duckStatusProvider!);
      if (currentStatus != null) {
        duckSprite!.updateStatusReference(currentStatus);
        debugPrint(
            '[DuckGame] Status atualizado para revive: isDead=${currentStatus.isDead}');
      }

      duckSprite!.playAnimation('fly', force: true);
    }
    startRandomAnimationTimer();
  }

  void playTalkAnimation() {
    if (_isLoaded && duckSprite != null) {
      // Atualiza o status antes de tocar a animação talk
      final currentStatus = duckStatus ?? ref?.read(duckStatusProvider!);
      if (currentStatus != null) {
        duckSprite!.updateStatusReference(currentStatus);
        debugPrint(
            '[DuckGame] Status atualizado para talk: isDead=${currentStatus.isDead}');
      }
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
        duckSprite!.updateStatusReference(currentStatus);
        duckSprite!.updateAnimationBasedOnStatus();
        debugPrint(
            '[DuckGame] Status atualizado: isDead=${currentStatus.isDead}');

        // Se o pato acabou de reviver, reinicia o timer de animações aleatórias
        if (!currentStatus.isDead) {
          if (randomAnimationTimer?.isActive != true) {
            debugPrint(
                '[DuckGame] Reiniciando timer de animações após ressurreição');
            startRandomAnimationTimer();
          }
        } else {
          // Se o pato morreu, cancela o timer
          randomAnimationTimer?.cancel();
          debugPrint('[DuckGame] Timer cancelado - pato morreu');
        }
      }
    }
  }

  /// Força atualização do status e reposiciona animações
  void forceStatusUpdate() {
    updateSpriteStatus();
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
  DuckStatus duckStatus;

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
        } else {
          // Verifica o status mais atual possível no momento da execução
          final currentStatus =
              game.duckStatus ?? game.ref?.read(game.duckStatusProvider!);
          if (currentStatus?.isDead == true) {
            playAnimation('dead', force: true);
          } else {
            playAnimation('idle', force: true);
          }
        }
      };
    } else if (animationTicker != null && animationName == 'talk') {
      animationTicker!.onComplete = () {
        // Força uma atualização do status antes de decidir a próxima animação
        final currentStatus =
            game.duckStatus ?? game.ref?.read(game.duckStatusProvider!);
        // Atualiza a referência local do status
        if (currentStatus != null) {
          duckStatus = currentStatus;
        }

        // Debug para verificar o status no final da animação talk
        debugPrint(
            '[DuckSprite] Animação talk terminou, status atual: isDead=${currentStatus?.isDead}');

        if (currentStatus?.isDead == true) {
          debugPrint('[DuckSprite] Indo para animação dead');
          playAnimation('dead', force: true);
        } else {
          debugPrint('[DuckSprite] Indo para animação idle');
          playAnimation('idle', force: true);
        }
      };
    } else if (animationTicker != null) {
      animationTicker!.onComplete = null;
    }
  }

  void playRandomAnimation() {
    // Verifica o status mais atual possível
    final currentStatus =
        game.duckStatus ?? game.ref?.read(game.duckStatusProvider!);
    if (currentStatus?.isDead == true) {
      playAnimation('dead');
      return;
    }
    final randomAnimations = ['blink', 'fly', 'look'];
    final randomAnimation =
        randomAnimations[Random().nextInt(randomAnimations.length)];
    playAnimation(randomAnimation);
  }

  void updateAnimationBasedOnStatus() {
    // Verifica o status mais atual possível
    final currentStatus =
        game.duckStatus ?? game.ref?.read(game.duckStatusProvider!);
    if (currentStatus?.isDead == true) {
      playAnimation('dead');
      return;
    }
    // Se não está morto e não está em uma animação específica, vai para idle
    if (currentAnimation == 'dead') {
      playAnimation('idle', force: true);
    }
  }

  /// Atualiza a referência do status do pato
  void updateStatusReference(DuckStatus newStatus) {
    duckStatus = newStatus;
  }
}
