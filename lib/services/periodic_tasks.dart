// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

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

  // Referência ao notifier do estado do pato (Riverpod)
  late DuckStatusNotifier duckStatusNotifier;

  /// Inicializa o gerenciador de tarefas periódicas com o notifier do pato fornecido.
  void initialize(DuckStatusNotifier notifier) {
    duckStatusNotifier = notifier;
    startAllTasks();
  }

  void startAllTasks() {
    _startStatusUpdateTimer();
    _startAutoCommentTimer();
    _startCleanupTimer();
  }

  void stopAllTasks() {
    _statusUpdateTimer?.cancel();
    _autoCommentTimer?.cancel();
    _cleanupTimer?.cancel();
  }

  void _startStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        await _updateDuckStatus();
      },
    );
  }

  void _startAutoCommentTimer() {
    _autoCommentTimer?.cancel();
    _scheduleNextAutoComment();
  }

  void _scheduleNextAutoComment() {
    _autoCommentTimer?.cancel();
    final randomMinutes = Random().nextInt(11) + 10; // 10-20 minutos
    final duration = Duration(minutes: randomMinutes);
    _autoCommentTimer = Timer(duration, () async {
      await _sendAutoComment();
      _scheduleNextAutoComment();
    });
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 6),
      (timer) async {
        await _performCleanup();
      },
    );
  }

  Future<void> _updateDuckStatus() async {
    try {
      // Atualiza o status do pato usando o notifier do Riverpod
      duckStatusNotifier.updateStatus();
      final duckStatus = duckStatusNotifier.state;
      if (duckStatus.isDead) {
        onDeathDetected?.call();
        return;
      }
      onStatusUpdate?.call(duckStatus.getMood());
    } catch (e) {
      debugPrint('Error updating duck status: $e');
    }
  }

  Future<void> _sendAutoComment() async {
    try {
      final isApiConfigured = await ChatService.isApiKeyConfigured();
      if (!isApiConfigured) {
        return;
      }
      final duckStatus = duckStatusNotifier.state;
      if (duckStatus.isDead) {
        return;
      }
      final comment = await ChatService.sendAutomaticComment();
      onAutoComment?.call(comment);
    } catch (e) {
      debugPrint('Error sending auto comment: $e');
    }
  }

  Future<void> _performCleanup() async {
    try {
      await ChatService.cleanupOldScreenshots();
      debugPrint('Cleanup completed successfully');
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  Duration? getTimeUntilNextAutoComment() {
    if (_autoCommentTimer == null || !_autoCommentTimer!.isActive) {
      return null;
    }
    return const Duration(minutes: 15);
  }

  Future<void> forceStatusUpdate() async {
    await _updateDuckStatus();
  }

  Future<void> forceAutoComment() async {
    await _sendAutoComment();
  }

  void pauseAutoComments() {
    _autoCommentTimer?.cancel();
  }

  void resumeAutoComments() {
    _scheduleNextAutoComment();
  }

  bool get areAutoCommentsActive => _autoCommentTimer?.isActive ?? false;
  Duration get statusUpdateInterval => const Duration(seconds: 30);
  Map<String, int> get autoCommentIntervalRange => {
        'min': 10,
        'max': 20,
      };

  void dispose() {
    stopAllTasks();
    onStatusUpdate = null;
    onAutoComment = null;
    onDeathDetected = null;
  }
}

class PeriodicTasksHelper {
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

  static Duration timeSinceLastAction(DateTime lastAction) {
    return DateTime.now().difference(lastAction);
  }

  static bool isActionOverdue(DateTime lastAction, Duration maxInterval) {
    return timeSinceLastAction(lastAction) > maxInterval;
  }

  static DateTime getNextScheduledTime(DateTime lastAction, Duration interval) {
    return lastAction.add(interval);
  }
}
