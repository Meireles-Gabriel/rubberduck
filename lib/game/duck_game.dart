import 'dart:async' as dart_async;
import 'dart:math';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'duck_status.dart';

/// Duck game component using Flame engine / Componente do jogo do pato usando engine Flame
class DuckGame extends FlameGame {
  // Represents the visual sprite and animations of the duck in the game / Representa o sprite visual e as animações do pato no jogo
  late DuckSprite duckSprite;

  // Reference to the DuckStatus object, which manages the duck's internal state (hunger, hygiene, happiness) / Referência ao objeto DuckStatus, que gerencia o estado interno do pato (fome, higiene, felicidade)
  late DuckStatus duckStatus;

  // Timer responsible for scheduling random animations for the duck / Timer responsável por agendar animações aleatórias para o pato
  dart_async.Timer? randomAnimationTimer;

  // Callback function to notify external components about changes in the duck's mood or status / Função de callback para notificar componentes externos sobre mudanças no humor ou status do pato
  Function(String)? onStatusUpdate;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Ensures that Flutter widgets are initialized before proceeding / Garante que os widgets Flutter sejam inicializados antes de prosseguir
    // Initializes the duck's status and loads its persisted state from preferences / Inicializa o status do pato e carrega seu estado persistido das preferências
    duckStatus = DuckStatus();
    await duckStatus.loadFromPreferences();

    // Creates and adds the DuckSprite component to the game, linking it to the duck's status / Cria e adiciona o componente DuckSprite ao jogo, vinculando-o ao status do pato
    duckSprite = DuckSprite(duckStatus: duckStatus);
    await add(duckSprite);

    // Positions the duck sprite on the screen, typically at a center-left location / Posiciona o sprite do pato na tela, tipicamente em uma localização centro-esquerda
    duckSprite.position = Vector2(size.x * 0.3, size.y * 0.5);

    // Initiates the timer for playing random animations / Inicia o timer para reproduzir animações aleatórias
    startRandomAnimationTimer();
  }

  /// Starts or restarts the timer that triggers random animations for the duck. / Inicia ou reinicia o timer que aciona animações aleatórias para o pato.
  void startRandomAnimationTimer() {
    randomAnimationTimer
        ?.cancel(); // Cancels any existing timer to prevent duplicates / Cancela qualquer timer existente para evitar duplicatas
    randomAnimationTimer = dart_async.Timer.periodic(
      Duration(
          seconds: Random().nextInt(20) +
              10), // Generates a random interval between 10 and 30 seconds / Gera um intervalo aleatório entre 10 e 30 segundos
      (timer) {
        if (!duckStatus.isDead) {
          duckSprite
              .playRandomAnimation(); // Plays a random animation if the duck is not dead / Reproduz uma animação aleatória se o pato não estiver morto
        }
      },
    );
  }

  /// Forces an update of the duck's internal status and notifies listeners. / Força uma atualização do status interno do pato e notifica os ouvintes.
  Future<void> updateDuckStatus() async {
    await duckStatus
        .updateStatus(); // Calls the DuckStatus method to update state / Chama o método DuckStatus para atualizar o estado
    onStatusUpdate?.call(duckStatus
        .getMood()); // Triggers the status update callback with the current mood / Aciona o callback de atualização de status com o humor atual
  }

  /// Feeds the duck, updates its status, plays the feeding animation, and notifies listeners. / Alimenta o pato, atualiza seu status, reproduz a animação de alimentação e notifica os ouvintes.
  Future<void> feedDuck() async {
    if (duckStatus.isDead)
      return; // Prevents action if the duck is dead / Impede a ação se o pato estiver morto

    await duckStatus
        .feed(); // Updates the duck's hunger status / Atualiza o status de fome do pato
    duckSprite.playAnimation(
        'feed'); // Plays the feeding animation / Reproduz a animação de alimentação
    onStatusUpdate?.call(duckStatus
        .getMood()); // Notifies about the new mood / Notifica sobre o novo humor
  }

  /// Cleans the duck, updates its status, plays the cleaning animation, and notifies listeners. / Limpa o pato, atualiza seu status, reproduz a animação de limpeza e notifica os ouvintes.
  Future<void> cleanDuck() async {
    if (duckStatus.isDead)
      return; // Prevents action if the duck is dead / Impede a ação se o pato estiver morto

    await duckStatus
        .clean(); // Updates the duck's hygiene status / Atualiza o status de higiene do pato
    duckSprite.playAnimation(
        'clean'); // Plays the cleaning animation / Reproduz a animação de limpeza
    onStatusUpdate?.call(duckStatus
        .getMood()); // Notifies about the new mood / Notifica sobre o novo humor
  }

  /// Plays with the duck, updates its status, plays the playing animation, and notifies listeners. / Brinca com o pato, atualiza seu status, reproduz a animação de brincadeira e notifica os ouvintes.
  Future<void> playWithDuck() async {
    if (duckStatus.isDead)
      return; // Prevents action if the duck is dead / Impede a ação se o pato estiver morto

    await duckStatus
        .play(); // Updates the duck's happiness status / Atualiza o status de felicidade do pato
    duckSprite.playAnimation(
        'play'); // Plays the playing animation / Reproduz a animação de brincadeira
    onStatusUpdate?.call(duckStatus
        .getMood()); // Notifies about the new mood / Notifica sobre o novo humor
  }

  /// Revives the duck, updates its status, plays the revival animation, and notifies listeners. / Revive o pato, atualiza seu status, reproduz a animação de renascimento e notifica os ouvintes.
  Future<void> reviveDuck() async {
    await duckStatus
        .revive(); // Resets the duck's status to alive and healthy / Redefine o status do pato para vivo e saudável
    duckSprite.playAnimation(
        'revive'); // Plays the revival animation / Reproduz a animação de renascimento
    onStatusUpdate?.call(duckStatus
        .getMood()); // Notifies about the new mood / Notifica sobre o novo humor
  }

  @override
  void onRemove() {
    randomAnimationTimer
        ?.cancel(); // Cancels the animation timer when the component is removed / Cancela o timer de animação quando o componente é removido
    super
        .onRemove(); // Calls the superclass method / Chama o método da superclasse
  }
}

/// Represents the duck's visual appearance and manages its animations within the game. / Representa a aparência visual do pato e gerencia suas animações dentro do jogo.
class DuckSprite extends SpriteAnimationComponent
    with HasGameReference<DuckGame> {
  // A map storing different SpriteAnimation objects, each corresponding to a specific duck action or state. / Um mapa que armazena diferentes objetos SpriteAnimation, cada um correspondendo a uma ação ou estado específico do pato.
  late Map<String, SpriteAnimation> animations;

  // Keeps track of the currently active animation name (e.g., 'idle', 'feed', 'death'). / Acompanha o nome da animação atualmente ativa (ex: 'idle', 'feed', 'death').
  String currentAnimation = 'idle';

  // A direct reference to the DuckStatus object, allowing the sprite to react to the duck's internal state. / Uma referência direta ao objeto DuckStatus, permitindo que o sprite reaja ao estado interno do pato.
  final DuckStatus duckStatus;

  /// Constructor for DuckSprite, requiring a DuckStatus instance. / Construtor para DuckSprite, exigindo uma instância de DuckStatus.
  DuckSprite({required this.duckStatus});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Loads all predefined animations for the duck from asset files. / Carrega todas as animações predefinidas para o pato de arquivos de ativos.
    await loadAnimations();

    // Sets the initial animation to 'idle' when the sprite loads. / Define a animação inicial como 'idle' quando o sprite é carregado.
    playAnimation('idle');
  }

  /// Asynchronously loads all sprite animations for the duck from image assets. / Carrega assincronamente todas as animações de sprite para o pato a partir de ativos de imagem.
  Future<void> loadAnimations() async {
    animations =
        {}; // Initializes the animations map / Inicializa o mapa de animações

    try {
      // Loads the default idle animation for the duck / Carrega a animação padrão de "idle" para o pato
      animations['idle'] = await _loadAnimation('duck_idle.png', 4, 0.5);

      // Loads animations for care actions (feeding, cleaning, playing) / Carrega animações para ações de cuidado (alimentar, limpar, brincar)
      animations['feed'] = await _loadAnimation('duck_feed.png', 6, 0.3);
      animations['clean'] = await _loadAnimation('duck_clean.png', 6, 0.3);
      animations['play'] = await _loadAnimation('duck_play.png', 8, 0.25);

      // Loads the death animation / Carrega a animação de morte
      animations['death'] = await _loadAnimation('duck_death.png', 4, 0.6);

      // Loads special animations like revival and happy states / Carrega animações especiais como renascimento e estados felizes
      animations['revive'] = await _loadAnimation('duck_revive.png', 6, 0.4);
      animations['happy'] = await _loadAnimation('duck_happy.png', 4, 0.4);
      animations['sleep'] = await _loadAnimation('duck_sleep.png', 2, 1.0);
    } catch (e) {
      debugPrint(
          'Warning: Could not load duck sprites, using fallback animations'); // Logs a warning if sprites fail to load / Registra um aviso se os sprites falharem ao carregar
      await loadFallbackAnimations(); // Loads simpler fallback animations if primary loading fails / Carrega animações de fallback mais simples se o carregamento primário falhar
    }
  }

  /// Helper method to load a SpriteAnimation from a given sprite sheet filename. / Método auxiliar para carregar um SpriteAnimation de um nome de arquivo de folha de sprite dado.
  Future<SpriteAnimation> _loadAnimation(
      String filename, int frames, double stepTime) async {
    // Loads the image file as a sprite sheet / Carrega o arquivo de imagem como uma folha de sprite
    final spriteSheet = await Flame.images.load('sprites/$filename');

    // Creates and returns a SpriteAnimation from the loaded sprite sheet data / Cria e retorna um SpriteAnimation a partir dos dados da folha de sprite carregada
    return SpriteAnimation.fromFrameData(
      spriteSheet,
      SpriteAnimationData.sequenced(
        amount:
            frames, // Total number of frames in the animation / Número total de quadros na animação
        stepTime:
            stepTime, // Time between each frame in seconds / Tempo entre cada quadro em segundos
        textureSize: Vector2.all(
            64), // Assumes each sprite frame is 64x64 pixels / Assume que cada quadro de sprite tem 64x64 pixels
      ),
    );
  }

  /// Loads simple fallback animations (colored rectangles) if actual sprite loading fails. / Carrega animações de fallback simples (retângulos coloridos) se o carregamento real do sprite falhar.
  Future<void> loadFallbackAnimations() async {
    // Loads a simple fallback image to use as a sprite / Carrega uma imagem de fallback simples para usar como sprite
    final fallbackSprite = await Sprite.load('ui/duck_fallback.png');

    // Creates a basic animation from a single sprite frame / Cria uma animação básica a partir de um único quadro de sprite
    final fallbackAnimation = SpriteAnimation.spriteList(
      [
        fallbackSprite
      ], // List containing the single fallback sprite / Lista contendo o único sprite de fallback
      stepTime:
          0.5, // Time for each step of the animation / Tempo para cada passo da animação
    );

    // Assigns the fallback animation to all animation keys / Atribui a animação de fallback a todas as chaves de animação
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

  /// Plays a specified animation by its name. If the animation name is not found, it defaults to 'idle'. / Reproduz uma animação especificada pelo seu nome. Se o nome da animação não for encontrado, ele padroniza para 'idle'.
  void playAnimation(String animationName) {
    if (!animations.containsKey(animationName)) {
      animationName =
          'idle'; // Fallback to idle if animation not found / Fallback para "idle" se a animação não for encontrada
    }

    currentAnimation =
        animationName; // Sets the current animation name / Define o nome da animação atual
    animation = animations[
        animationName]; // Assigns the animation to the component / Atribui a animação ao componente

    size = Vector2.all(
        80); // Sets the size of the sprite component / Define o tamanho do componente sprite

    // Manages the completion behavior for non-looping animations / Gerencia o comportamento de conclusão para animações não repetitivas
    if (animationName != 'idle' &&
        animationName != 'death' &&
        animationName != 'sleep') {
      animationTicker?.onComplete = () {
        if (duckStatus.isDead) {
          playAnimation(
              'death'); // Transitions to death animation if duck is dead / Transiciona para animação de morte se o pato estiver morto
        } else {
          playAnimation(
              'idle'); // Returns to idle animation otherwise / Retorna para animação "idle" caso contrário
        }
      };
    }
  }

  /// Plays a random animation from a predefined list, ensuring the duck is not dead. / Reproduz uma animação aleatória de uma lista predefinida, garantindo que o pato não esteja morto.
  void playRandomAnimation() {
    if (duckStatus.isDead) {
      playAnimation(
          'death'); // Forces death animation if duck is dead / Força animação de morte se o pato estiver morto
      return;
    }

    // Defines a list of animations that can be played randomly / Define uma lista de animações que podem ser reproduzidas aleatoriamente
    final randomAnimations = ['happy', 'sleep'];
    // Selects a random animation from the list / Seleciona uma animação aleatória da lista
    final randomAnimation =
        randomAnimations[Random().nextInt(randomAnimations.length)];

    playAnimation(
        randomAnimation); // Plays the selected random animation / Reproduz a animação aleatória selecionada
  }

  /// Updates the current animation of the duck based on its status. / Atualiza a animação atual do pato com base no seu status.
  void updateAnimationBasedOnStatus() {
    if (duckStatus.isDead) {
      playAnimation(
          'death'); // Plays death animation if duck is dead / Reproduz animação de morte se o pato estiver morto
      return;
    }

    // Checks if the duck needs attention and is currently idle, then plays a subtle attention-seeking animation. / Verifica se o pato precisa de atenção e está atualmente ocioso, então reproduz uma animação sutil de busca de atenção.
    if (duckStatus.needsAttention && currentAnimation == 'idle') {
      final attentionMessage = duckStatus
          .getAttentionMessage(); // Gets the attention message / Obtém a mensagem de atenção
      if (attentionMessage != null) {
        // Plays a happy animation as a subtle way to get attention / Reproduz uma animação feliz como uma maneira sutil de chamar atenção
        playAnimation('happy');
      }
    }
  }
}
