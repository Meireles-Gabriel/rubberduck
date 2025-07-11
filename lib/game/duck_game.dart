import 'dart:async' as dart_async;
import 'dart:math';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'duck_status.dart';

/// Componente do jogo do pato usando engine Flame
class DuckGame extends FlameGame {
  // Representa o sprite visual e as animações do pato no jogo
  late DuckSprite duckSprite;

  // Referência ao objeto DuckStatus, que gerencia o estado interno do pato (fome, higiene, felicidade)
  late DuckStatus duckStatus;

  // Timer responsável por agendar animações aleatórias para o pato
  dart_async.Timer? randomAnimationTimer;

  // Função de callback para notificar componentes externos sobre mudanças no humor ou status do pato
  Function(String)? onStatusUpdate;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Garante que os widgets Flutter sejam inicializados antes de prosseguir
    // Inicializa o status do pato e carrega seu estado persistido das preferências
    duckStatus = DuckStatus();
    await duckStatus.loadFromPreferences();

    // Cria e adiciona o componente DuckSprite ao jogo, vinculando-o ao status do pato
    duckSprite = DuckSprite(duckStatus: duckStatus);
    await add(duckSprite);

    // Posiciona o sprite do pato na tela, tipicamente em uma localização centro-esquerda
    duckSprite.position = Vector2(size.x * 0.3, size.y * 0.5);

    // Inicia o timer para reproduzir animações aleatórias
    startRandomAnimationTimer();
  }

  /// Inicia ou reinicia o timer que aciona animações aleatórias para o pato.
  void startRandomAnimationTimer() {
    randomAnimationTimer
        ?.cancel(); // Cancela qualquer timer existente para evitar duplicatas
    randomAnimationTimer = dart_async.Timer.periodic(
      Duration(
          seconds: Random().nextInt(20) +
              10), // Gera um intervalo aleatório entre 10 e 30 segundos
      (timer) {
        if (!duckStatus.isDead) {
          duckSprite
              .playRandomAnimation(); // Reproduz uma animação aleatória se o pato não estiver morto
        }
      },
    );
  }

  /// Força uma atualização do status interno do pato e notifica os ouvintes.
  Future<void> updateDuckStatus() async {
    await duckStatus
        .updateStatus(); // Chama o método DuckStatus para atualizar o estado
    onStatusUpdate?.call(duckStatus
        .getMood()); // Aciona o callback de atualização de status com o humor atual
  }

  /// Alimenta o pato, atualiza seu status, reproduz a animação de alimentação e notifica os ouvintes.
  Future<void> feedDuck() async {
    if (duckStatus.isDead) return; // Impede a ação se o pato estiver morto

    await duckStatus.feed(); // Atualiza o status de fome do pato
    duckSprite.playAnimation('feed'); // Reproduz a animação de alimentação
    onStatusUpdate?.call(duckStatus.getMood()); // Notifica sobre o novo humor
  }

  /// Limpa o pato, atualiza seu status, reproduz a animação de limpeza e notifica os ouvintes.
  Future<void> cleanDuck() async {
    if (duckStatus.isDead) return; // Impede a ação se o pato estiver morto

    await duckStatus.clean(); // Atualiza o status de higiene do pato
    duckSprite.playAnimation('clean'); // Reproduz a animação de limpeza
    onStatusUpdate?.call(duckStatus.getMood()); // Notifica sobre o novo humor
  }

  /// Brinca com o pato, atualiza seu status, reproduz a animação de brincadeira e notifica os ouvintes.
  Future<void> playWithDuck() async {
    if (duckStatus.isDead) return; // Impede a ação se o pato estiver morto

    await duckStatus.play(); // Atualiza o status de felicidade do pato
    duckSprite.playAnimation('play'); // Reproduz a animação de brincadeira
    onStatusUpdate?.call(duckStatus.getMood()); // Notifica sobre o novo humor
  }

  /// Revive o pato, atualiza seu status, reproduz a animação de renascimento e notifica os ouvintes.
  Future<void> reviveDuck() async {
    await duckStatus.revive(); // Redefine o status do pato para vivo e saudável
    duckSprite.playAnimation('revive'); // Reproduz a animação de renascimento
    onStatusUpdate?.call(duckStatus.getMood()); // Notifica sobre o novo humor
  }

  @override
  void onRemove() {
    randomAnimationTimer
        ?.cancel(); // Cancela o timer de animação quando o componente é removido
    super.onRemove(); // Chama o método da superclasse
  }
}

/// Representa a aparência visual do pato e gerencia suas animações dentro do jogo.
class DuckSprite extends SpriteAnimationComponent
    with HasGameReference<DuckGame> {
  // Um mapa que armazena diferentes objetos SpriteAnimation, cada um correspondendo a uma ação ou estado específico do pato.
  late Map<String, SpriteAnimation> animations;

  // Acompanha o nome da animação atualmente ativa (ex: 'idle', 'feed', 'death').
  String currentAnimation = 'idle';

  // Uma referência direta ao objeto DuckStatus, permitindo que o sprite reaja ao estado interno do pato.
  final DuckStatus duckStatus;

  /// Construtor para DuckSprite, exigindo uma instância de DuckStatus.
  DuckSprite({required this.duckStatus});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Carrega todas as animações predefinidas para o pato de arquivos de ativos.
    await loadAnimations();

    // Define a animação inicial como 'idle' quando o sprite é carregado.
    playAnimation('idle');
  }

  /// Carrega assincronamente todas as animações de sprite para o pato a partir de ativos de imagem.
  Future<void> loadAnimations() async {
    animations = {}; // Inicializa o mapa de animações

    try {
      // Carrega a animação padrão de "idle" para o pato
      animations['idle'] = await _loadAnimation('duck_idle.png', 4, 0.5);

      // Carrega animações para ações de cuidado (alimentar, limpar, brincar)
      animations['feed'] = await _loadAnimation('duck_feed.png', 6, 0.3);
      animations['clean'] = await _loadAnimation('duck_clean.png', 6, 0.3);
      animations['play'] = await _loadAnimation('duck_play.png', 8, 0.25);

      // Carrega a animação de morte
      animations['death'] = await _loadAnimation('duck_death.png', 4, 0.6);

      // Carrega animações especiais como renascimento e estados felizes
      animations['revive'] = await _loadAnimation('duck_revive.png', 6, 0.4);
      animations['happy'] = await _loadAnimation('duck_happy.png', 4, 0.4);
      animations['sleep'] = await _loadAnimation('duck_sleep.png', 2, 1.0);
    } catch (e) {
      debugPrint(
          'Warning: Could not load duck sprites, using fallback animations'); // Registra um aviso se os sprites falharem ao carregar
      await loadFallbackAnimations(); // Carrega animações de fallback mais simples se o carregamento primário falhar
    }
  }

  /// Método auxiliar para carregar um SpriteAnimation de um nome de arquivo de folha de sprite dado.
  Future<SpriteAnimation> _loadAnimation(
      String filename, int frames, double stepTime) async {
    // Carrega o arquivo de imagem como uma folha de sprite
    final spriteSheet = await Flame.images.load('sprites/$filename');

    // Cria e retorna um SpriteAnimation a partir dos dados da folha de sprite carregada
    return SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount: frames, // Número total de quadros na animação
        stepTime: stepTime, // Tempo entre cada quadro em segundos
        textureSize: Vector2.all(
            64), // Assume que cada quadro de sprite tem 64x64 pixels
      ),
    );
  }

  /// Carrega animações de fallback simples (retângulos coloridos) se o carregamento real do sprite falhar.
  Future<void> loadFallbackAnimations() async {
    // Carrega uma imagem de fallback simples para usar como sprite
    final fallbackSprite = await Sprite.load('ui/duck_fallback.png');

    // Cria uma animação básica a partir de um único quadro de sprite
    final fallbackAnimation = SpriteAnimation.spriteList(
      [fallbackSprite], // Lista contendo o único sprite de fallback
      stepTime: 0.5, // Tempo para cada passo da animação
    );

    // Atribui a animação de fallback a todas as chaves de animação
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

  /// Reproduz uma animação especificada pelo seu nome. Se o nome da animação não for encontrado, ele padroniza para 'idle'.
  void playAnimation(String animationName) {
    if (!animations.containsKey(animationName)) {
      animationName =
          'idle'; // Fallback para "idle" se a animação não for encontrada
    }

    currentAnimation = animationName; // Define o nome da animação atual
    animation = animations[animationName]; // Atribui a animação ao componente

    size = Vector2.all(80); // Define o tamanho do componente sprite

    // Gerencia o comportamento de conclusão para animações não repetitivas
    if (animationName != 'idle' &&
        animationName != 'death' &&
        animationName != 'sleep') {
      animationTicker?.onComplete = () {
        if (duckStatus.isDead) {
          playAnimation(
              'death'); // Transiciona para animação de morte se o pato estiver morto
        } else {
          playAnimation('idle'); // Retorna para animação "idle" caso contrário
        }
      };
    }
  }

  /// Reproduz uma animação aleatória de uma lista predefinida, garantindo que o pato não esteja morto.
  void playRandomAnimation() {
    if (duckStatus.isDead) {
      playAnimation('death'); // Força animação de morte se o pato estiver morto
      return;
    }

    // Define uma lista de animações que podem ser reproduzidas aleatoriamente
    final randomAnimations = ['happy', 'sleep'];
    // Seleciona uma animação aleatória da lista
    final randomAnimation =
        randomAnimations[Random().nextInt(randomAnimations.length)];

    playAnimation(randomAnimation); // Reproduz a animação aleatória selecionada
  }

  /// Atualiza a animação atual do pato com base no seu status.
  void updateAnimationBasedOnStatus() {
    if (duckStatus.isDead) {
      playAnimation(
          'death'); // Reproduz animação de morte se o pato estiver morto
      return;
    }

    // Verifica se o pato precisa de atenção e está atualmente ocioso, então reproduz uma animação sutil de busca de atenção.
    if (duckStatus.needsAttention && currentAnimation == 'idle') {
      final attentionMessage =
          duckStatus.getAttentionMessage(); // Obtém a mensagem de atenção
      if (attentionMessage != null) {
        // Reproduz uma animação feliz como uma maneira sutil de chamar atenção
        playAnimation('happy');
      }
    }
  }
}
