import 'package:flutter/material.dart';
import '../utils/localization_strings.dart';
import '../game/duck_status.dart';

/// Death and revival system for the duck / Sistema de morte e ressurreição para o pato
class DeathRevivalSystem {
  /// Show death dialog / Mostra diálogo de morte
  static Future<void> showDeathDialog(
    BuildContext context,
    DuckStatus duckStatus,
    VoidCallback onRevive,
  ) async {
    // Determine death message based on cause / Determina mensagem de morte baseada na causa
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
        deathMessage = LocalizationStrings.get(
            'died_hunger'); // Default fallback / Fallback padrão
    }

    await showDialog(
      context: context,
      barrierDismissible:
          false, // Cannot dismiss without action / Não pode dispensar sem ação
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            LocalizationStrings.get('death_title'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Death icon / Ícone de morte
              const Icon(
                Icons.sentiment_very_dissatisfied,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              // Death message / Mensagem de morte
              Text(
                deathMessage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Cause explanation / Explicação da causa
              Text(
                _getDeathExplanation(duckStatus.deathCause),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            // Revive button / Botão de reviver
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRevive();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    LocalizationStrings.get('revive'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  /// Get death explanation based on cause / Obtém explicação da morte baseada na causa
  static String _getDeathExplanation(String? cause) {
    final currentLanguage = LocalizationStrings.currentLanguage;

    switch (cause) {
      case 'hunger':
        return currentLanguage == 'pt_BR'
            ? 'Não foi alimentado por mais de 24 horas.'
            : 'Was not fed for more than 24 hours.';
      case 'dirty':
        return currentLanguage == 'pt_BR'
            ? 'Não foi limpo por mais de 24 horas.'
            : 'Was not cleaned for more than 24 hours.';
      case 'sadness':
        return currentLanguage == 'pt_BR'
            ? 'Não brincou por mais de 24 horas.'
            : 'Did not play for more than 24 hours.';
      default:
        return currentLanguage == 'pt_BR'
            ? 'Não recebeu cuidados adequados.'
            : 'Did not receive adequate care.';
    }
  }

  /// Show revival animation / Mostra animação de ressurreição
  static Future<void> showRevivalAnimation(
    BuildContext context,
    VoidCallback onAnimationComplete,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const _RevivalAnimationDialog();
      },
    );

    // Call completion callback / Chama callback de conclusão
    onAnimationComplete();
  }

  /// Check if duck should show death warning / Verifica se o pato deve mostrar aviso de morte
  static bool shouldShowDeathWarning(DuckStatus duckStatus) {
    final now = DateTime.now();
    const warningThreshold = 20 *
        60 *
        60 *
        1000; // 20 hours in milliseconds / 20 horas em milissegundos

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

  /// Show death warning / Mostra aviso de morte
  static Future<void> showDeathWarning(
      BuildContext context, DuckStatus duckStatus) async {
    String warningMessage;
    final currentLanguage = LocalizationStrings.currentLanguage;

    if (duckStatus.hunger < 20) {
      warningMessage = currentLanguage == 'pt_BR'
          ? 'Estou com muita fome! Por favor, me alimente logo ou posso morrer!'
          : 'I\'m very hungry! Please feed me soon or I might die!';
    } else if (duckStatus.cleanliness < 20) {
      warningMessage = currentLanguage == 'pt_BR'
          ? 'Estou muito sujo! Por favor, me limpe logo ou posso morrer!'
          : 'I\'m very dirty! Please clean me soon or I might die!';
    } else {
      warningMessage = currentLanguage == 'pt_BR'
          ? 'Estou muito triste! Por favor, brinque comigo logo ou posso morrer!'
          : 'I\'m very sad! Please play with me soon or I might die!';
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            currentLanguage == 'pt_BR' ? 'Aviso Urgente!' : 'Urgent Warning!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning,
                size: 60,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                warningMessage,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                currentLanguage == 'pt_BR' ? 'Entendi' : 'I Understand',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Revival animation dialog / Diálogo de animação de ressurreição
class _RevivalAnimationDialog extends StatefulWidget {
  const _RevivalAnimationDialog();

  @override
  State<_RevivalAnimationDialog> createState() =>
      _RevivalAnimationDialogState();
}

class _RevivalAnimationDialogState extends State<_RevivalAnimationDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller / Inicializa controlador de animação
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
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
