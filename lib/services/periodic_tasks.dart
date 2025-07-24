// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:math';
import '../services/chat_service.dart';
import '../game/duck_status.dart';
import 'package:flutter/foundation.dart';
import '../utils/localization_strings.dart';

/// Gerenciador de tarefas periódicas
class PeriodicTasksManager {
  // Timers usados para gerenciar operações periódicas
  Timer? _statusUpdateTimer; // Timer para atualizar o status do pato
  Timer? _autoCommentTimer; // Timer para enviar comentários automáticos
  Timer? _cleanupTimer; // Timer para executar tarefas de limpeza

  // Flag para indicar se as tarefas estão pausadas devido à morte do pato
  bool _isPausedDueToDeath = false;

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

  /// Pausa todas as tarefas devido à morte do pato
  void pauseTasksDueToDeath() {
    if (_isPausedDueToDeath) return; // Já pausado

    debugPrint('[PeriodicTasks] Pausando tarefas - pato morreu');
    _isPausedDueToDeath = true;
    _autoCommentTimer?.cancel(); // Para comentários automáticos
    // Mantém apenas o timer de status para detectar ressurreição
  }

  /// Retoma todas as tarefas após ressurreição do pato
  void resumeTasksAfterRevival() {
    if (!_isPausedDueToDeath) return; // Não estava pausado

    debugPrint('[PeriodicTasks] Retomando tarefas - pato reviveu');
    _isPausedDueToDeath = false;
    _startAutoCommentTimer(); // Retoma comentários automáticos

    // Força atualização do status para sincronizar o estado
    Future.delayed(const Duration(milliseconds: 500), () {
      forceStatusUpdate();
    });
  }

  /// Verifica se as tarefas estão pausadas devido à morte
  bool get isPausedDueToDeath => _isPausedDueToDeath;

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

    // Não agenda se as tarefas estão pausadas devido à morte
    if (_isPausedDueToDeath) {
      debugPrint('[PeriodicTasks] Não agendando comentário - pato morto');
      return;
    }

    final randomMinutes = Random().nextInt(11) + 10; // 10-20 minutos
    final duration = Duration(minutes: randomMinutes);
    debugPrint(
        '[PeriodicTasks] Próximo comentário automático em $randomMinutes minutos');

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
      final previousDeathStatus = duckStatusNotifier.state.isDead;

      // Atualiza o status do pato usando o notifier do Riverpod
      duckStatusNotifier.updateStatus();
      final duckStatus = duckStatusNotifier.state;

      // Verifica mudanças no status de morte
      if (!previousDeathStatus && duckStatus.isDead) {
        // Pato acabou de morrer
        pauseTasksDueToDeath();
        onDeathDetected?.call();
        return;
      } else if (previousDeathStatus && !duckStatus.isDead) {
        // Pato acabou de reviver
        resumeTasksAfterRevival();
      }

      // Se o pato está morto, não faz mais nada
      if (duckStatus.isDead) {
        return;
      }

      onStatusUpdate?.call(duckStatus.getMood());
    } catch (e) {
      debugPrint('Error updating duck status: $e');
    }
  }

  Future<void> _sendAutoComment() async {
    try {
      final duckStatus = duckStatusNotifier.state;

      // Não envia comentários se o pato estiver morto ou tarefas pausadas
      if (duckStatus.isDead || _isPausedDueToDeath) {
        debugPrint(
            '[PeriodicTasks] Comentário automático cancelado - pato morto');
        return;
      }

      final isApiConfigured = await ChatService.isApiKeyConfigured();
      if (!isApiConfigured) {
        return;
      }

      // Verifica necessidades críticas e envia mensagem correspondente
      if (duckStatus.hunger < 30) {
        onAutoComment?.call(LocalizationStrings.get('hungry'));
        return;
      }
      if (duckStatus.cleanliness < 30) {
        onAutoComment?.call(LocalizationStrings.get('dirty'));
        return;
      }
      if (duckStatus.happiness < 30) {
        onAutoComment?.call(LocalizationStrings.get('sad'));
        return;
      }
      // Caso contrário, envia comentário automático normal
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
    if (_isPausedDueToDeath) {
      debugPrint(
          '[PeriodicTasks] Não pode pausar comentários - pato está morto');
      return;
    }
    _autoCommentTimer?.cancel();
  }

  void resumeAutoComments() {
    if (_isPausedDueToDeath) {
      debugPrint(
          '[PeriodicTasks] Não pode retomar comentários - pato está morto');
      return;
    }
    _scheduleNextAutoComment();
  }

  bool get areAutoCommentsActive => _autoCommentTimer?.isActive ?? false;
  bool get areTasksPausedDueToDeath => _isPausedDueToDeath;
  Duration get statusUpdateInterval => const Duration(seconds: 30);
  Map<String, int> get autoCommentIntervalRange => {
        'min': 10,
        'max': 20,
      };

  void dispose() {
    stopAllTasks();
    _isPausedDueToDeath = false;
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
