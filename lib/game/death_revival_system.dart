import 'package:flutter/material.dart';
import '../utils/localization_strings.dart';
import '../game/duck_status.dart';

/// Sistema de morte e ressurreição para o pato
class DeathRevivalSystem {
  /// Exibe um diálogo ao usuário indicando a morte do pato e oferecendo uma opção de renascimento.
  static Future<void> showDeathDialog(
    BuildContext context, // O contexto de construção para exibir o diálogo
    DuckStatus duckStatus, // O status atual do pato, incluindo a causa da morte
    VoidCallback
        onRevive, // Função de callback a ser executada quando o pato for revivido
  ) async {
    // Determina a mensagem de morte apropriada com base na causa da morte do pato.
    String deathMessage;
    switch (duckStatus.deathCause) {
      case 'hunger':
        deathMessage = LocalizationStrings.get(
            'died_hunger'); // Mensagem para morte por fome
        break;
      case 'dirty':
        deathMessage = LocalizationStrings.get(
            'died_dirty'); // Mensagem para morte por sujeira
        break;
      case 'sadness':
        deathMessage = LocalizationStrings.get(
            'died_sadness'); // Mensagem para morte por tristeza
        break;
      default:
        deathMessage = LocalizationStrings.get(
            'died_hunger'); // Mensagem de fallback padrão se a causa for desconhecida
    }

    await showDialog(
      context: context,
      barrierDismissible:
          false, // Impede que o diálogo seja dispensado tocando fora
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            LocalizationStrings.get(
                'death_title'), // Título do diálogo de morte
            style: const TextStyle(
              fontSize: 24, // Tamanho da fonte para o título
              fontWeight: FontWeight.bold, // Peso da fonte para o título
              color: Colors.red, // Cor do título
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Faz a coluna ocupar espaço mínimo
            children: [
              // Ícone representando morte ou insatisfação
              const Icon(
                Icons.sentiment_very_dissatisfied,
                size: 80, // Tamanho do ícone
                color: Colors.red, // Cor do ícone
              ),
              const SizedBox(height: 16), // Espaçador
              // Exibe a mensagem específica de morte
              Text(
                deathMessage,
                style: const TextStyle(
                  fontSize: 18, // Tamanho da fonte para a mensagem de morte
                  fontWeight:
                      FontWeight.w500, // Peso da fonte para a mensagem de morte
                ),
                textAlign: TextAlign.center, // Centraliza o texto
              ),
              const SizedBox(height: 16), // Espaçador
              // Fornece uma explicação para a morte do pato com base na causa
              Text(
                _getDeathExplanation(
                    duckStatus.deathCause), // Texto de explicação
                style: const TextStyle(
                  fontSize: 14, // Tamanho da fonte para a explicação
                  color: Colors.grey, // Cor do texto da explicação
                ),
                textAlign: TextAlign.center, // Centraliza o texto
              ),
            ],
          ),
          actions: [
            // Botão para reviver o pato
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
                onRevive(); // Executa o callback de renascimento
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Cor de fundo do botão
                foregroundColor: Colors.white, // Cor do texto do botão
                padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical:
                        12), // Preenchimento ao redor do conteúdo do botão
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      8), // Cantos arredondados para o botão
                ),
              ),
              child: Row(
                mainAxisSize:
                    MainAxisSize.min, // Faz a linha ocupar espaço mínimo
                children: [
                  const Icon(Icons.favorite,
                      size: 18), // Ícone de coração para renascimento
                  const SizedBox(width: 8), // Espaçador
                  Text(
                    LocalizationStrings.get(
                        'revive'), // Texto para o botão reviver
                    style: const TextStyle(
                      fontSize: 16, // Tamanho da fonte para o texto do botão
                      fontWeight: FontWeight
                          .bold, // Peso da fonte para o texto do botão
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Fornece uma explicação localizada para a morte do pato com base na causa fornecida.
  static String _getDeathExplanation(String? cause) {
    final currentLanguage = LocalizationStrings
        .currentLanguage; // Recupera o idioma atual da aplicação

    switch (cause) {
      case 'hunger':
        return currentLanguage == 'pt_BR'
            ? 'Não foi alimentado por mais de 24 horas.'
            : 'Não foi alimentado por mais de 24 horas.';
      case 'dirty':
        return currentLanguage == 'pt_BR'
            ? 'Não foi limpo por mais de 24 horas.'
            : 'Não foi limpo por mais de 24 horas.';
      case 'sadness':
        return currentLanguage == 'pt_BR'
            ? 'Não brincou por mais de 24 horas.'
            : 'Não brincou por mais de 24 horas.';
      default:
        return currentLanguage == 'pt_BR'
            ? 'Não recebeu cuidados adequados.'
            : 'Não recebeu cuidados adequados.';
    }
  }

  /// Exibe uma animação para representar visualmente o processo de renascimento do pato.
  static Future<void> showRevivalAnimation(
    BuildContext context, // O contexto de construção para exibir o diálogo
    VoidCallback
        onAnimationComplete, // Callback executado após o término da animação de renascimento
  ) async {
    await showDialog(
      context: context,
      barrierDismissible:
          false, // Impede o fechamento até a conclusão da animação
      builder: (BuildContext context) {
        return const _RevivalAnimationDialog(); // O widget de diálogo contendo a animação de renascimento
      },
    );

    // Chama o callback de conclusão assim que o diálogo é dispensado (animação é considerada completa)
    onAnimationComplete();
  }

  /// Verifica se um aviso de morte deve ser exibido ao usuário com base no status do pato.
  static bool shouldShowDeathWarning(DuckStatus duckStatus) {
    final now = DateTime.now(); // Hora atual
    const warningThreshold = 20 * 60 * 60 * 1000; // 20 horas em milissegundos

    // Verifica se os níveis de fome, higiene ou felicidade estão baixos e atrasados para atenção
    return (now.difference(duckStatus.lastFeed).inMilliseconds >
                warningThreshold &&
            duckStatus.hunger < 20) ||
        (now.difference(duckStatus.lastClean).inMilliseconds >
                warningThreshold &&
            duckStatus.cleanliness < 20) ||
        (now.difference(duckStatus.lastPlay).inMilliseconds >
                warningThreshold &&
            duckStatus.happiness < 20);
  }

  /// Exibe um diálogo de aviso urgente ao usuário se o pato estiver próximo da morte devido à negligência.
  static Future<void> showDeathWarning(
      BuildContext context, DuckStatus duckStatus) async {
    String warningMessage; // Mensagem a ser exibida no diálogo de aviso
    final currentLanguage = LocalizationStrings
        .currentLanguage; // Recupera o idioma atual da aplicação

    // Determina a mensagem de aviso específica com base em qual necessidade é crítica
    if (duckStatus.hunger < 20) {
      warningMessage = currentLanguage == 'pt_BR'
          ? 'Estou com muita fome! Por favor, me alimente logo ou posso morrer!'
          : 'Estou com muita fome! Por favor, me alimente logo ou posso morrer!';
    } else if (duckStatus.cleanliness < 20) {
      warningMessage = currentLanguage == 'pt_BR'
          ? 'Estou muito sujo! Por favor, me limpe logo ou posso morrer!'
          : 'Estou muito sujo! Por favor, me limpe logo ou posso morrer!';
    } else {
      warningMessage = currentLanguage == 'pt_BR'
          ? 'Estou muito triste! Por favor, brinque comigo logo ou posso morrer!'
          : 'Estou muito triste! Por favor, brinque comigo logo ou posso morrer!';
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            currentLanguage == 'pt_BR'
                ? 'Aviso Urgente!'
                : 'Aviso Urgente!', // Título do diálogo de aviso
            style: const TextStyle(
              fontSize: 20, // Tamanho da fonte para o título do aviso
              fontWeight:
                  FontWeight.bold, // Peso da fonte para o título do aviso
              color: Colors.orange, // Cor do título do aviso
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Faz a coluna ocupar espaço mínimo
            children: [
              const Icon(
                Icons.warning,
                size: 60, // Tamanho do ícone de aviso
                color: Colors.orange, // Cor do ícone de aviso
              ),
              const SizedBox(height: 16), // Espaçador
              Text(
                warningMessage, // A mensagem de aviso específica
                style: const TextStyle(
                    fontSize: 16), // Tamanho da fonte para a mensagem de aviso
                textAlign: TextAlign.center, // Centraliza o texto
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(), // Fecha o diálogo ao ser pressionado
              child: Text(
                currentLanguage == 'pt_BR'
                    ? 'Entendi'
                    : 'Entendi', // Texto para o botão de entendimento
                style: const TextStyle(
                  fontSize: 16, // Tamanho da fonte para o texto do botão
                  fontWeight:
                      FontWeight.bold, // Peso da fonte para o texto do botão
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Um StatefulWidget para gerenciar o estado do diálogo de animação de renascimento.
class _RevivalAnimationDialog extends StatefulWidget {
  const _RevivalAnimationDialog(); // Construtor

  @override
  State<_RevivalAnimationDialog> createState() =>
      _RevivalAnimationDialogState(); // Cria o estado para este widget
}

/// A classe State para _RevivalAnimationDialog, gerenciando o controlador de animação e a animação real.
class _RevivalAnimationDialogState extends State<_RevivalAnimationDialog>
    with TickerProviderStateMixin {
  late AnimationController
      _animationController; // Controla a progressão da animação
  late Animation<double>
      _scaleAnimation; // Define a transformação de escala da animação
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, // O TickerProvider para o controlador de animação
      duration: const Duration(seconds: 2), // Duração da animação
    );

    // Animação de escala
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Animação de rotação
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Inicia animação
    _animationController.forward();

    // Fecha automaticamente após animação
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 80,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocalizationStrings.get('revive'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
