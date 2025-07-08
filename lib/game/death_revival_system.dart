import 'package:flutter/material.dart';
import '../utils/localization_strings.dart';
import '../game/duck_status.dart';

/// Death and revival system for the duck / Sistema de morte e ressurreição para o pato
class DeathRevivalSystem {
  /// Displays a dialog to the user indicating the duck's death and offering a revival option. / Exibe um diálogo ao usuário indicando a morte do pato e oferecendo uma opção de renascimento.
  static Future<void> showDeathDialog(
    BuildContext
        context, // The build context to display the dialog / O contexto de construção para exibir o diálogo
    DuckStatus
        duckStatus, // The current status of the duck, including the cause of death / O status atual do pato, incluindo a causa da morte
    VoidCallback
        onRevive, // Callback function to be executed when the duck is revived / Função de callback a ser executada quando o pato for revivido
  ) async {
    // Determines the appropriate death message based on the duck's cause of death. / Determina a mensagem de morte apropriada com base na causa da morte do pato.
    String deathMessage;
    switch (duckStatus.deathCause) {
      case 'hunger':
        deathMessage = LocalizationStrings.get(
            'died_hunger'); // Message for death by hunger / Mensagem para morte por fome
        break;
      case 'dirty':
        deathMessage = LocalizationStrings.get(
            'died_dirty'); // Message for death by dirtiness / Mensagem para morte por sujeira
        break;
      case 'sadness':
        deathMessage = LocalizationStrings.get(
            'died_sadness'); // Message for death by sadness / Mensagem para morte por tristeza
        break;
      default:
        deathMessage = LocalizationStrings.get(
            'died_hunger'); // Default fallback message if cause is unknown / Mensagem de fallback padrão se a causa for desconhecida
    }

    await showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents the dialog from being dismissed by tapping outside / Impede que o diálogo seja dispensado tocando fora
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            LocalizationStrings.get(
                'death_title'), // Title of the death dialog / Título do diálogo de morte
            style: const TextStyle(
              fontSize:
                  24, // Font size for the title / Tamanho da fonte para o título
              fontWeight: FontWeight
                  .bold, // Font weight for the title / Peso da fonte para o título
              color: Colors.red, // Color of the title / Cor do título
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize
                .min, // Makes the column take minimum space / Faz a coluna ocupar espaço mínimo
            children: [
              // Icon representing death or dissatisfaction / Ícone representando morte ou insatisfação
              const Icon(
                Icons.sentiment_very_dissatisfied,
                size: 80, // Size of the icon / Tamanho do ícone
                color: Colors.red, // Color of the icon / Cor do ícone
              ),
              const SizedBox(height: 16), // Spacer / Espaçador
              // Displays the specific death message / Exibe a mensagem específica de morte
              Text(
                deathMessage,
                style: const TextStyle(
                  fontSize:
                      18, // Font size for the death message / Tamanho da fonte para a mensagem de morte
                  fontWeight: FontWeight
                      .w500, // Font weight for the death message / Peso da fonte para a mensagem de morte
                ),
                textAlign:
                    TextAlign.center, // Centers the text / Centraliza o texto
              ),
              const SizedBox(height: 16), // Spacer / Espaçador
              // Provides an explanation for the duck's death based on the cause / Fornece uma explicação para a morte do pato com base na causa
              Text(
                _getDeathExplanation(duckStatus
                    .deathCause), // Explanation text / Texto de explicação
                style: const TextStyle(
                  fontSize:
                      14, // Font size for the explanation / Tamanho da fonte para a explicação
                  color: Colors
                      .grey, // Color of the explanation text / Cor do texto da explicação
                ),
                textAlign:
                    TextAlign.center, // Centers the text / Centraliza o texto
              ),
            ],
          ),
          actions: [
            // Button to revive the duck / Botão para reviver o pato
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Closes the dialog / Fecha o diálogo
                onRevive(); // Executes the revival callback / Executa o callback de renascimento
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors
                    .green, // Background color of the button / Cor de fundo do botão
                foregroundColor: Colors
                    .white, // Text color of the button / Cor do texto do botão
                padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical:
                        12), // Padding around the button's content / Preenchimento ao redor do conteúdo do botão
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      8), // Rounded corners for the button / Cantos arredondados para o botão
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize
                    .min, // Makes the row take minimum space / Faz a linha ocupar espaço mínimo
                children: [
                  const Icon(Icons.favorite,
                      size:
                          18), // Heart icon for revival / Ícone de coração para renascimento
                  const SizedBox(width: 8), // Spacer / Espaçador
                  Text(
                    LocalizationStrings.get(
                        'revive'), // Text for the revive button / Texto para o botão reviver
                    style: const TextStyle(
                      fontSize:
                          16, // Font size for the button text / Tamanho da fonte para o texto do botão
                      fontWeight: FontWeight
                          .bold, // Font weight for the button text / Peso da fonte para o texto do botão
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

  /// Provides a localized explanation for the duck's death based on the given cause. / Fornece uma explicação localizada para a morte do pato com base na causa fornecida.
  static String _getDeathExplanation(String? cause) {
    final currentLanguage = LocalizationStrings
        .currentLanguage; // Retrieves the current application language / Recupera o idioma atual da aplicação

    switch (cause) {
      case 'hunger':
        return currentLanguage == 'pt_BR'
            ? 'Não foi alimentado por mais de 24 horas.'
            : 'Was not fed for more than 24 hours.'; // Explanation for hunger death / Explicação para morte por fome
      case 'dirty':
        return currentLanguage == 'pt_BR'
            ? 'Não foi limpo por mais de 24 horas.'
            : 'Was not cleaned for more than 24 hours.'; // Explanation for dirtiness death / Explicação para morte por sujeira
      case 'sadness':
        return currentLanguage == 'pt_BR'
            ? 'Não brincou por mais de 24 horas.'
            : 'Did not play for more than 24 hours.'; // Explanation for sadness death / Explicação para morte por tristeza
      default:
        return currentLanguage == 'pt_BR'
            ? 'Não recebeu cuidados adequados.'
            : 'Did not receive adequate care.'; // Generic explanation for unknown cause / Explicação genérica para causa desconhecida
    }
  }

  /// Displays an animation to visually represent the duck's revival process. / Exibe uma animação para representar visualmente o processo de renascimento do pato.
  static Future<void> showRevivalAnimation(
    BuildContext
        context, // The build context for showing the dialog / O contexto de construção para exibir o diálogo
    VoidCallback
        onAnimationComplete, // Callback executed after the revival animation finishes / Callback executado após o término da animação de renascimento
  ) async {
    await showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents dismissal until animation completes / Impede o fechamento até a conclusão da animação
      builder: (BuildContext context) {
        return const _RevivalAnimationDialog(); // The dialog widget containing the revival animation / O widget de diálogo contendo a animação de renascimento
      },
    );

    // Calls the completion callback once the dialog is dismissed (animation is considered complete) / Chama o callback de conclusão assim que o diálogo é dispensado (animação é considerada completa)
    onAnimationComplete();
  }

  /// Checks if a death warning should be displayed to the user based on the duck's status. / Verifica se um aviso de morte deve ser exibido ao usuário com base no status do pato.
  static bool shouldShowDeathWarning(DuckStatus duckStatus) {
    final now = DateTime.now(); // Current time / Hora atual
    const warningThreshold = 20 *
        60 *
        60 *
        1000; // 20 hours in milliseconds / 20 horas em milissegundos

    // Checks if hunger, cleanliness, or happiness levels are low and overdue for attention / Verifica se os níveis de fome, higiene ou felicidade estão baixos e atrasados para atenção
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

  /// Displays an urgent warning dialog to the user if the duck is nearing death due to neglect. / Exibe um diálogo de aviso urgente ao usuário se o pato estiver próximo da morte devido à negligência.
  static Future<void> showDeathWarning(
      BuildContext context, DuckStatus duckStatus) async {
    String
        warningMessage; // Message to be displayed in the warning dialog / Mensagem a ser exibida no diálogo de aviso
    final currentLanguage = LocalizationStrings
        .currentLanguage; // Retrieves the current application language / Recupera o idioma atual da aplicação

    // Determines the specific warning message based on which need is critical / Determina a mensagem de aviso específica com base em qual necessidade é crítica
    if (duckStatus.hunger < 20) {
      warningMessage = currentLanguage == 'pt_BR'
          ? 'Estou com muita fome! Por favor, me alimente logo ou posso morrer!'
          : 'I\'m very hungry! Please feed me soon or I might die!'; // Warning for hunger / Aviso para fome
    } else if (duckStatus.cleanliness < 20) {
      warningMessage = currentLanguage == 'pt_BR'
          ? 'Estou muito sujo! Por favor, me limpe logo ou posso morrer!'
          : 'I\'m very dirty! Please clean me soon or I might die!'; // Warning for dirtiness / Aviso para sujeira
    } else {
      warningMessage = currentLanguage == 'pt_BR'
          ? 'Estou muito triste! Por favor, brinque comigo logo ou posso morrer!'
          : 'I\'m very sad! Please play with me soon or I might die!'; // Warning for sadness / Aviso para tristeza
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            currentLanguage == 'pt_BR'
                ? 'Aviso Urgente!'
                : 'Urgent Warning!', // Title of the warning dialog / Título do diálogo de aviso
            style: const TextStyle(
              fontSize:
                  20, // Font size for the warning title / Tamanho da fonte para o título do aviso
              fontWeight: FontWeight
                  .bold, // Font weight for the warning title / Peso da fonte para o título do aviso
              color: Colors
                  .orange, // Color of the warning title / Cor do título do aviso
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize
                .min, // Makes the column take minimum space / Faz a coluna ocupar espaço mínimo
            children: [
              const Icon(
                Icons.warning,
                size:
                    60, // Size of the warning icon / Tamanho do ícone de aviso
                color: Colors
                    .orange, // Color of the warning icon / Cor do ícone de aviso
              ),
              const SizedBox(height: 16), // Spacer / Espaçador
              Text(
                warningMessage, // The specific warning message / A mensagem de aviso específica
                style: const TextStyle(
                    fontSize:
                        16), // Font size for the warning message / Tamanho da fonte para a mensagem de aviso
                textAlign:
                    TextAlign.center, // Centers the text / Centraliza o texto
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(), // Closes the dialog when pressed / Fecha o diálogo ao ser pressionado
              child: Text(
                currentLanguage == 'pt_BR'
                    ? 'Entendi'
                    : 'I Understand', // Text for the understand button / Texto para o botão de entendimento
                style: const TextStyle(
                  fontSize:
                      16, // Font size for the button text / Tamanho da fonte para o texto do botão
                  fontWeight: FontWeight
                      .bold, // Font weight for the button text / Peso da fonte para o texto do botão
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A StatefulWidget to manage the state of the revival animation dialog. / Um StatefulWidget para gerenciar o estado do diálogo de animação de renascimento.
class _RevivalAnimationDialog extends StatefulWidget {
  const _RevivalAnimationDialog(); // Constructor / Construtor

  @override
  State<_RevivalAnimationDialog> createState() =>
      _RevivalAnimationDialogState(); // Creates the state for this widget / Cria o estado para este widget
}

/// The State class for _RevivalAnimationDialog, managing the animation controller and actual animation. / A classe State para _RevivalAnimationDialog, gerenciando o controlador de animação e a animação real.
class _RevivalAnimationDialogState extends State<_RevivalAnimationDialog>
    with TickerProviderStateMixin {
  late AnimationController
      _animationController; // Controls the animation progression / Controla a progressão da animação
  late Animation<double>
      _scaleAnimation; // Defines the scale transformation of the animation / Define a transformação de escala da animação
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync:
          this, // The TickerProvider for the animation controller / O TickerProvider para o controlador de animação
      duration: const Duration(
          seconds: 2), // Duration of the animation / Duração da animação
    );

    // Scale animation / Animação de escala
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Rotation animation / Animação de rotação
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animation / Inicia animação
    _animationController.forward();

    // Auto-close after animation / Fecha automaticamente após animação
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
