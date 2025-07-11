import 'dart:async';
import 'dart:math';
import '../services/chat_service.dart';
import '../game/duck_status.dart';
import 'package:flutter/foundation.dart';

/// Gerenciador de tarefas periódicas
class PeriodicTasksManager {
  // Timers usados para gerenciar operações periódicas
  Timer? _statusUpdateTimer; // Timer para atualizar o status do pato
  Timer? _autoCommentTimer; // Timer para enviar comentários automáticos
  Timer? _cleanupTimer; // Timer para executar tarefas de limpeza

  // Callbacks para notificar componentes externos sobre eventos
  Function(String)? onStatusUpdate; // Callback para atualizações de status
  Function(String)? onAutoComment; // Callback para comentários automáticos
  Function()? onDeathDetected; // Callback para detecção de morte

  // Referência ao objeto DuckStatus para gerenciar o estado do pato
  late DuckStatus duckStatus;

  /// Inicializa o gerenciador de tarefas periódicas com o status do pato fornecido.
  void initialize(DuckStatus status) {
    duckStatus = status;
    startAllTasks();
  }

  /// Inicia todas as tarefas periódicas definidas.
  void startAllTasks() {
    _startStatusUpdateTimer();
    _startAutoCommentTimer();
    _startCleanupTimer();
  }

  /// Para todas as tarefas periódicas ativas cancelando seus timers.
  void stopAllTasks() {
    _statusUpdateTimer?.cancel();
    _autoCommentTimer?.cancel();
    _cleanupTimer?.cancel();
  }

  /// Inicia ou reinicia o timer para atualizar o status do pato.
  void _startStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();

    // Configura um timer periódico para atualizar o status a cada 30 segundos
    _statusUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        await _updateDuckStatus();
      },
    );
  }

  /// Inicia ou reinicia o timer para enviar comentários automáticos.
  void _startAutoCommentTimer() {
    _autoCommentTimer?.cancel();

    // Agenda o primeiro comentário automático
    _scheduleNextAutoComment();
  }

  /// Agenda o próximo comentário automático com um atraso aleatório.
  void _scheduleNextAutoComment() {
    _autoCommentTimer?.cancel();

    // Gera um intervalo aleatório entre 10 e 20 minutos para o próximo comentário
    final randomMinutes = Random().nextInt(11) + 10; // 10-20 minutos
    final duration = Duration(minutes: randomMinutes);

    _autoCommentTimer = Timer(duration, () async {
      await _sendAutoComment();
      _scheduleNextAutoComment(); // Agenda o comentário subsequente após o envio do atual
    });
  }

  /// Inicia ou reinicia o timer para executar tarefas de limpeza diárias.
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();

    // Configura um timer periódico para limpeza diária de arquivos antigos
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 24),
      (timer) async {
        await _performCleanup();
      },
    );
  }

  /// Atualiza o status do pato com base no tempo decorrido e notifica os ouvintes.
  Future<void> _updateDuckStatus() async {
    try {
      // Chama a lógica de atualização do status do pato
      await duckStatus.updateStatus();

      // Verifica se o pato morreu como resultado da atualização de status
      if (duckStatus.isDead) {
        onDeathDetected?.call(); // Aciona o callback de detecção de morte
        return;
      }

      // Notifica os ouvintes sobre o humor atualizado do pato
      onStatusUpdate?.call(duckStatus.getMood());
    } catch (e) {
      debugPrint(
          'Error updating duck status: $e'); // Imprime um erro se a atualização de status falhar
    }
  }

  /// Envia um comentário automático usando o ChatService, se a chave da API estiver configurada e o pato estiver vivo.
  Future<void> _sendAutoComment() async {
    try {
      // Verifica se a chave da API para o ChatService está configurada
      final isApiConfigured = await ChatService.isApiKeyConfigured();
      if (!isApiConfigured) {
        return; // Aborta se a chave da API não estiver configurada para evitar o envio de comentários
      }

      // Impede o envio de comentários se o pato estiver morto
      if (duckStatus.isDead) {
        return;
      }

      // Busca e envia um comentário automático através do ChatService
      final comment = await ChatService.sendAutomaticComment();
      onAutoComment
          ?.call(comment); // Aciona o callback de comentário automático
    } catch (e) {
      debugPrint(
          'Error sending auto comment: $e'); // Imprime um erro se o envio do comentário automático falhar
    }
  }

  /// Executa várias tarefas de limpeza, como exclusão de capturas de tela antigas.
  Future<void> _performCleanup() async {
    try {
      // Inicia a limpeza de capturas de tela antigas
      await ChatService.cleanupOldScreenshots();

      debugPrint(
          'Cleanup completed successfully'); // Registra mensagem de sucesso
    } catch (e) {
      debugPrint(
          'Error during cleanup: $e'); // Imprime um erro se a limpeza falhar
    }
  }

  /// Retorna o tempo estimado restante até o próximo comentário automático ser enviado.
  Duration? getTimeUntilNextAutoComment() {
    if (_autoCommentTimer == null || !_autoCommentTimer!.isActive) {
      return null; // Retorna nulo se o timer de comentário automático não estiver ativo
    }

    // O Timer não fornece diretamente o tempo restante. Esta é uma aproximação baseada no intervalo médio.
    return const Duration(minutes: 15); // Retorna uma duração de tempo média
  }

  /// Força uma atualização imediata do status do pato.
  Future<void> forceStatusUpdate() async {
    await _updateDuckStatus();
  }

  /// Força o envio imediato de um comentário automático.
  Future<void> forceAutoComment() async {
    await _sendAutoComment();
  }

  /// Pausa o timer de comentários automáticos, impedindo novos comentários até ser retomado.
  void pauseAutoComments() {
    _autoCommentTimer?.cancel();
  }

  /// Retoma o timer de comentários automáticos, agendando o próximo comentário.
  void resumeAutoComments() {
    _scheduleNextAutoComment();
  }

  /// Getter para verificar se os comentários automáticos estão ativos.
  bool get areAutoCommentsActive => _autoCommentTimer?.isActive ?? false;

  /// Retorna o intervalo fixo no qual o status do pato é atualizado.
  Duration get statusUpdateInterval => const Duration(seconds: 30);

  /// Retorna o intervalo mínimo e máximo para o comentário automático.
  Map<String, int> get autoCommentIntervalRange => {
        'min': 10, // Mínimo de minutos para comentário automático
        'max': 20, // Máximo de minutos para comentário automático
      };

  /// Descarta todos os recursos e cancela todos os timers ativos.
  void dispose() {
    stopAllTasks(); // Para todas as tarefas em andamento

    // Limpa todos os callbacks registrados para evitar vazamentos de memória
    onStatusUpdate = null;
    onAutoComment = null;
    onDeathDetected = null;
  }
}

/// Fornece funções utilitárias relacionadas a tarefas periódicas e cálculos de tempo.
class PeriodicTasksHelper {
  /// Formata uma duração em uma string legível (ex: "1h 30m 15s").
  static String formatDuration(Duration duration) {
    final hours = duration.inHours; // Extrai as horas da duração
    final minutes =
        duration.inMinutes.remainder(60); // Extrai os minutos restantes
    final seconds =
        duration.inSeconds.remainder(60); // Extrai os segundos restantes

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s'; // Formata com horas, minutos e segundos
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s'; // Formata com minutos e segundos
    } else {
      return '${seconds}s'; // Formata apenas com segundos
    }
  }

  /// Calcula a diferença de tempo entre o horário atual e um horário de última ação fornecido.
  static Duration timeSinceLastAction(DateTime lastAction) {
    return DateTime.now()
        .difference(lastAction); // Retorna a duração desde a última ação
  }

  /// Verifica se uma ação está atrasada com base no horário da última ação e no intervalo máximo permitido.
  static bool isActionOverdue(DateTime lastAction, Duration maxInterval) {
    return timeSinceLastAction(lastAction) >
        maxInterval; // Compara o tempo desde a última ação com o intervalo máximo
  }

  /// Calcula o próximo horário agendado para uma ação, dada sua última ocorrência e intervalo.
  static DateTime getNextScheduledTime(DateTime lastAction, Duration interval) {
    return lastAction
        .add(interval); // Adiciona o intervalo ao horário da última ação
  }
}
