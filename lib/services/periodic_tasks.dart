import 'dart:async';
import 'dart:math';
import '../services/chat_service.dart';
import '../game/duck_status.dart';
import 'package:flutter/foundation.dart';

/// Periodic tasks manager / Gerenciador de tarefas periódicas
class PeriodicTasksManager {
  // Timers / Timers
  Timer? _statusUpdateTimer;
  Timer? _autoCommentTimer;
  Timer? _cleanupTimer;

  // Callbacks / Callbacks
  Function(String)? onStatusUpdate;
  Function(String)? onAutoComment;
  Function()? onDeathDetected;

  // References / Referências
  late DuckStatus duckStatus;

  /// Initialize periodic tasks / Inicializa tarefas periódicas
  void initialize(DuckStatus status) {
    duckStatus = status;
    startAllTasks();
  }

  /// Start all periodic tasks / Inicia todas as tarefas periódicas
  void startAllTasks() {
    _startStatusUpdateTimer();
    _startAutoCommentTimer();
    _startCleanupTimer();
  }

  /// Stop all periodic tasks / Para todas as tarefas periódicas
  void stopAllTasks() {
    _statusUpdateTimer?.cancel();
    _autoCommentTimer?.cancel();
    _cleanupTimer?.cancel();
  }

  /// Start status update timer / Inicia timer de atualização de status
  void _startStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();

    // Update status every 30 seconds / Atualiza status a cada 30 segundos
    _statusUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        await _updateDuckStatus();
      },
    );
  }

  /// Start auto comment timer / Inicia timer de comentário automático
  void _startAutoCommentTimer() {
    _autoCommentTimer?.cancel();

    // Schedule first comment / Agenda primeiro comentário
    _scheduleNextAutoComment();
  }

  /// Schedule next auto comment / Agenda próximo comentário automático
  void _scheduleNextAutoComment() {
    _autoCommentTimer?.cancel();

    // Random interval between 10-20 minutes / Intervalo aleatório entre 10-20 minutos
    final randomMinutes =
        Random().nextInt(11) + 10; // 10-20 minutes / 10-20 minutos
    final duration = Duration(minutes: randomMinutes);

    _autoCommentTimer = Timer(duration, () async {
      await _sendAutoComment();
      _scheduleNextAutoComment(); // Schedule next comment / Agenda próximo comentário
    });
  }

  /// Start cleanup timer / Inicia timer de limpeza
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();

    // Cleanup old files daily / Limpa arquivos antigos diariamente
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 24),
      (timer) async {
        await _performCleanup();
      },
    );
  }

  /// Update duck status / Atualiza status do pato
  Future<void> _updateDuckStatus() async {
    try {
      // Update status based on time / Atualiza status baseado no tempo
      await duckStatus.updateStatus();

      // Check for death / Verifica por morte
      if (duckStatus.isDead) {
        onDeathDetected?.call();
        return;
      }

      // Notify status update / Notifica atualização de status
      onStatusUpdate?.call(duckStatus.getMood());
    } catch (e) {
      debugPrint('Error updating duck status: $e');
    }
  }

  /// Send automatic comment / Envia comentário automático
  Future<void> _sendAutoComment() async {
    try {
      // Check if API key is configured / Verifica se chave API está configurada
      final isApiConfigured = await ChatService.isApiKeyConfigured();
      if (!isApiConfigured) {
        return; // Don't send auto comments without API key / Não envia comentários automáticos sem chave API
      }

      // Don't send comments if duck is dead / Não envia comentários se o pato estiver morto
      if (duckStatus.isDead) {
        return;
      }

      // Send automatic comment / Envia comentário automático
      final comment = await ChatService.sendAutomaticComment();
      onAutoComment?.call(comment);
    } catch (e) {
      debugPrint('Error sending auto comment: $e');
    }
  }

  /// Perform cleanup tasks / Executa tarefas de limpeza
  Future<void> _performCleanup() async {
    try {
      // Clean up old screenshots / Limpa screenshots antigos
      await ChatService.cleanupOldScreenshots();

      debugPrint('Cleanup completed successfully');
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  /// Get time until next auto comment / Obtém tempo até próximo comentário automático
  Duration? getTimeUntilNextAutoComment() {
    if (_autoCommentTimer == null || !_autoCommentTimer!.isActive) {
      return null;
    }

    // Note: Timer doesn't provide remaining time directly
    // This is an approximation / Timer não fornece tempo restante diretamente
    // Esta é uma aproximação
    return const Duration(minutes: 15); // Average time / Tempo médio
  }

  /// Force status update / Força atualização de status
  Future<void> forceStatusUpdate() async {
    await _updateDuckStatus();
  }

  /// Force auto comment / Força comentário automático
  Future<void> forceAutoComment() async {
    await _sendAutoComment();
  }

  /// Pause auto comments / Pausa comentários automáticos
  void pauseAutoComments() {
    _autoCommentTimer?.cancel();
  }

  /// Resume auto comments / Retoma comentários automáticos
  void resumeAutoComments() {
    _scheduleNextAutoComment();
  }

  /// Check if auto comments are active / Verifica se comentários automáticos estão ativos
  bool get areAutoCommentsActive => _autoCommentTimer?.isActive ?? false;

  /// Get status update interval / Obtém intervalo de atualização de status
  Duration get statusUpdateInterval => const Duration(seconds: 30);

  /// Get auto comment interval range / Obtém intervalo de comentário automático
  Map<String, int> get autoCommentIntervalRange => {
        'min': 10, // minutes / minutos
        'max': 20, // minutes / minutos
      };

  /// Dispose all resources / Descarta todos os recursos
  void dispose() {
    stopAllTasks();

    // Clear callbacks / Limpa callbacks
    onStatusUpdate = null;
    onAutoComment = null;
    onDeathDetected = null;
  }
}

/// Periodic tasks helper functions / Funções auxiliares para tarefas periódicas
class PeriodicTasksHelper {
  /// Format duration for display / Formata duração para exibição
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Calculate time since last action / Calcula tempo desde última ação
  static Duration timeSinceLastAction(DateTime lastAction) {
    return DateTime.now().difference(lastAction);
  }

  /// Check if action is overdue / Verifica se ação está atrasada
  static bool isActionOverdue(DateTime lastAction, Duration maxInterval) {
    return timeSinceLastAction(lastAction) > maxInterval;
  }

  /// Get next scheduled time / Obtém próximo horário agendado
  static DateTime getNextScheduledTime(DateTime lastAction, Duration interval) {
    return lastAction.add(interval);
  }

  /// Calculate urgency level / Calcula nível de urgência
  static double calculateUrgencyLevel(
      DateTime lastAction, Duration maxInterval) {
    final timeSince = timeSinceLastAction(lastAction);
    final urgencyRatio = timeSince.inMilliseconds / maxInterval.inMilliseconds;
    return urgencyRatio.clamp(0.0, 1.0);
  }

  /// Get urgency color / Obtém cor de urgência
  static String getUrgencyColor(double urgencyLevel) {
    if (urgencyLevel < 0.3) return 'green';
    if (urgencyLevel < 0.6) return 'yellow';
    if (urgencyLevel < 0.9) return 'orange';
    return 'red';
  }
}
