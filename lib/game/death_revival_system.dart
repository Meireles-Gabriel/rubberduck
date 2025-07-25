import 'package:flutter/material.dart';
import '../utils/localization_strings.dart';
import '../game/duck_status.dart';

/// Sistema crítico para manter engajamento do usuário através de consequências e recuperação
/// Morte cria urgência e valor emocional; ressurreição oferece segunda chance sem perda permanente
class DeathRevivalSystem {
  /// Confronta o usuário com consequências de negligência para ensinar responsabilidade
  /// Dialog modal força reconhecimento da situação e decisão consciente de reviver
  static Future<void> showDeathDialog(
    BuildContext
        context, // Contexto necessário para overlay modal sobre a aplicação
    DuckStatus
        duckStatus, // Estado atual para determinar causa específica da morte
    VoidCallback
        onRevive, // Callback para coordenar ressurreição com outros sistemas
  ) async {
    // Mensagem específica por causa para educar sobre diferentes tipos de negligência
    String deathMessage;
    switch (duckStatus.deathCause) {
      case 'hunger':
        deathMessage = LocalizationStrings.get(
            'died_hunger'); // Ensina importância da alimentação regular
        break;
      case 'dirty':
        deathMessage = LocalizationStrings.get(
            'died_dirty'); // Enfatiza necessidade de higiene
        break;
      case 'sadness':
        deathMessage = LocalizationStrings.get(
            'died_sadness'); // Destaca importância da interação social
        break;
      default:
        deathMessage = LocalizationStrings.get(
            'died_hunger'); // Fallback para evitar UI quebrada
    }

    await showDialog(
      context: context,
      barrierDismissible:
          false, // Força decisão consciente - usuário deve enfrentar consequências
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            LocalizationStrings.get(
                'death_title'), // Título impactante para gerar resposta emocional
            style: const TextStyle(
              fontSize: 24, // Tamanho grande para chamar atenção
              fontWeight: FontWeight.bold, // Peso para dar seriedade
              color: Colors.red, // Vermelho para transmitir urgência/perigo
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Compacto para foco na mensagem
            children: [
              // Ícone visual para reforçar impacto emocional da morte
              const Icon(
                Icons.sentiment_very_dissatisfied,
                size: 80, // Grande para impacto visual
                color: Colors.red, // Cor consistente com gravidade
              ),
              const SizedBox(height: 16), // Espaçamento para respiração visual
              // Mensagem específica para educar sobre causa da morte
              Text(
                deathMessage,
                style: const TextStyle(
                  fontSize: 18, // Legível mas não competindo com título
                  fontWeight: FontWeight.w500, // Peso médio para manter atenção
                ),
                textAlign: TextAlign.center, // Centralizado para seriedade
              ),
              const SizedBox(
                  height: 16), // Separação entre mensagem e explicação
              // Explicação educativa para prevenir repetição do problema
              Text(
                _getDeathExplanation(duckStatus
                    .deathCause), // Educação sobre cuidados necessários
                style: const TextStyle(
                  fontSize: 14, // Menor para informação secundária
                  color: Colors.grey, // Cor suave para não competir
                ),
                textAlign: TextAlign.center, // Consistência visual
              ),
            ],
          ),
          actions: [
            // Botão único para reviver - sem opção de desistir para manter engajamento
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Remove modal da tela
                onRevive(); // Dispara sistemas de ressurreição
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Verde para esperança/vida
                foregroundColor: Colors.white, // Contraste para legibilidade
                padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12), // Padding generoso para facilitar clique
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      8), // Bordas suaves para amigabilidade
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Compacto para centralização
                children: [
                  const Icon(Icons.favorite,
                      size: 18), // Coração simboliza amor/cuidado necessário
                  const SizedBox(width: 8), // Espaçamento entre ícone e texto
                  Text(
                    LocalizationStrings.get(
                        'revive'), // Texto direto para ação clara
                    style: const TextStyle(
                      fontSize: 16, // Tamanho confortável para leitura
                      fontWeight:
                          FontWeight.bold, // Peso para destacar ação principal
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

  /// Fornece explicação educativa para prevenir repetição da negligência
  static String _getDeathExplanation(String? cause) {
    switch (cause) {
      case 'hunger':
        return LocalizationStrings.get('explanation_hunger');
      case 'dirty':
        return LocalizationStrings.get('explanation_dirty');
      case 'sadness':
        return LocalizationStrings.get('explanation_sadness');
      default:
        return LocalizationStrings.get('explanation_adequate_care');
    }
  }

  /// Exibe uma animação para representar visualmente o processo de renascimento do pato.
  static Future<void> showRevivalAnimation(
    BuildContext context, // Contexto para modal de animação
    VoidCallback
        onAnimationComplete, // Callback para sincronizar com outros sistemas
  ) async {
    await showDialog(
      context: context,
      barrierDismissible:
          false, // Força conclusão da animação para experiência completa
      builder: (BuildContext context) {
        return const _RevivalAnimationDialog(); // Widget especializado para animação
      },
    );

    // Callback executado após animação para coordenar próximos passos
    onAnimationComplete();
  }

  /// Detecta situações críticas para alertar usuário antes da morte
  static bool shouldShowDeathWarning(DuckStatus duckStatus) {
    final now = DateTime.now(); // Timestamp para cálculos de tempo
    const warningThreshold = 20 * 60 * 60 * 1000; // 20 horas - prazo crítico

    // Sistema de alerta precoce para evitar mortes acidentais
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

  /// Exibe aviso urgente para prevenir morte iminente do pet
  static Future<void> showDeathWarning(
      BuildContext context, DuckStatus duckStatus) async {
    String warningMessage; // Mensagem específica para cada tipo de negligência

    // Identifica necessidade mais crítica para alerta direcionado
    if (duckStatus.hunger < 20) {
      warningMessage = LocalizationStrings.get('warning_hunger');
    } else if (duckStatus.cleanliness < 20) {
      warningMessage = LocalizationStrings.get('warning_dirty');
    } else {
      warningMessage = LocalizationStrings.get('warning_sadness');
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            LocalizationStrings.get(
                'warning_title'), // Título de alerta para chamar atenção
            style: const TextStyle(
              fontSize: 20, // Menor que morte mas ainda proeminente
              fontWeight: FontWeight.bold, // Bold para comunicar urgência
              color: Colors
                  .orange, // Laranja para aviso (não crítico como vermelho)
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Compacto para foco
            children: [
              const Icon(
                Icons.warning,
                size: 60, // Menor que ícone de morte mas visível
                color: Colors.orange, // Consistente com título
              ),
              const SizedBox(height: 16), // Espaçamento para legibilidade
              Text(
                warningMessage, // Mensagem específica sobre necessidade crítica
                style:
                    const TextStyle(fontSize: 16), // Legível para ação rápida
                textAlign: TextAlign.center, // Centralizado para seriedade
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(), // Permite dispensar após leitura
              child: Text(
                LocalizationStrings.get(
                    'understand'), // Texto que confirma compreensão
                style: const TextStyle(
                  fontSize: 16, // Tamanho confortável
                  fontWeight: FontWeight.bold, // Bold para destacar ação
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Widget especializado para criar experiência visual marcante da ressurreição
/// Animação complexa necessária para celebrar momento de renovação da vida
class _RevivalAnimationDialog extends StatefulWidget {
  const _RevivalAnimationDialog(); // Construtor simples - toda lógica no State

  @override
  State<_RevivalAnimationDialog> createState() =>
      _RevivalAnimationDialogState(); // Delega gerenciamento de animação ao State
}

/// Gerenciador de animação complexa para cerimônia de ressurreição
/// Múltiplas animações simultâneas criam experiência visual rica e memorável
class _RevivalAnimationDialogState extends State<_RevivalAnimationDialog>
    with TickerProviderStateMixin {
  late AnimationController
      _animationController; // Controla timing de toda a sequência
  late Animation<double>
      _scaleAnimation; // Efeito de crescimento para simbolizar vida
  late Animation<double> _rotationAnimation; // Rotação para dinamismo visual

  @override
  void initState() {
    super.initState();
    // Controller com duração calibrada para impacto emocional
    _animationController = AnimationController(
      vsync: this, // TickerProvider para sincronização com frame rate
      duration: const Duration(seconds: 2), // Duração que permite apreciação
    );

    // Animação de escala com curva elástica para efeito de "nascimento"
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut, // Curva que simula vida emergindo
    ));

    // Rotação sutil para adicionar movimento orgânico
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // Suave para não marejar
    ));

    // Inicia animação automaticamente para impacto imediato
    _animationController.forward();

    // Auto-dismiss para não exigir interação durante momento emocional
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
    // Cleanup essencial para evitar vazamentos de memória
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // Transparente para foco no conteúdo
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value, // Aplica animação de crescimento
            child: Transform.rotate(
              angle: _rotationAnimation.value, // Aplica rotação sutil
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white, // Fundo branco para pureza/renascimento
                  borderRadius:
                      BorderRadius.circular(100), // Circular para suavidade
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green
                          .withValues(alpha: 0.5), // Sombra verde para vida
                      blurRadius: 20, // Blur suave para efeito místico
                      spreadRadius: 5, // Spread para presença visual
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite, // Coração simboliza amor/vida renovada
                      size: 80,
                      color: Colors.green, // Verde para vida/saúde
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LocalizationStrings.get(
                          'revive'), // Confirma ação de ressurreição
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold, // Bold para celebração
                        color: Colors.green, // Consistente com tema de vida
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
