import 'dart:async';
import 'dart:math';
import '../services/chat_service.dart';
import '../game/duck_status.dart';
import 'package:flutter/foundation.dart';

/// Periodic tasks manager / Gerenciador de tarefas periódicas
class PeriodicTasksManager {
  // Timers used for managing periodic operations / Timers usados para gerenciar operações periódicas
  Timer?
      _statusUpdateTimer; // Timer for updating duck status / Timer para atualizar o status do pato
  Timer?
      _autoCommentTimer; // Timer for sending automatic comments / Timer para enviar comentários automáticos
  Timer?
      _cleanupTimer; // Timer for performing cleanup tasks / Timer para executar tarefas de limpeza

  // Callbacks to notify external components about events / Callbacks para notificar componentes externos sobre eventos
  Function(String)?
      onStatusUpdate; // Callback for status updates / Callback para atualizações de status
  Function(String)?
      onAutoComment; // Callback for automatic comments / Callback para comentários automáticos
  Function()?
      onDeathDetected; // Callback for death detection / Callback para detecção de morte

  // Reference to the DuckStatus object to manage duck's state / Referência ao objeto DuckStatus para gerenciar o estado do pato
  late DuckStatus duckStatus;

  /// Initializes the periodic tasks manager with the given duck status. / Inicializa o gerenciador de tarefas periódicas com o status do pato fornecido.
  void initialize(DuckStatus status) {
    duckStatus = status;
    startAllTasks();
  }

  /// Starts all defined periodic tasks. / Inicia todas as tarefas periódicas definidas.
  void startAllTasks() {
    _startStatusUpdateTimer();
    _startAutoCommentTimer();
    _startCleanupTimer();
  }

  /// Stops all active periodic tasks by canceling their timers. / Para todas as tarefas periódicas ativas cancelando seus timers.
  void stopAllTasks() {
    _statusUpdateTimer?.cancel();
    _autoCommentTimer?.cancel();
    _cleanupTimer?.cancel();
  }

  /// Starts or restarts the timer for updating the duck's status. / Inicia ou reinicia o timer para atualizar o status do pato.
  void _startStatusUpdateTimer() {
    _statusUpdateTimer?.cancel();

    // Sets up a periodic timer to update status every 30 seconds / Configura um timer periódico para atualizar o status a cada 30 segundos
    _statusUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        await _updateDuckStatus();
      },
    );
  }

  /// Starts or restarts the timer for sending automatic comments. / Inicia ou reinicia o timer para enviar comentários automáticos.
  void _startAutoCommentTimer() {
    _autoCommentTimer?.cancel();

    // Schedules the very first automatic comment / Agenda o primeiro comentário automático
    _scheduleNextAutoComment();
  }

  /// Schedules the next automatic comment with a random delay. / Agenda o próximo comentário automático com um atraso aleatório.
  void _scheduleNextAutoComment() {
    _autoCommentTimer?.cancel();

    // Generates a random interval between 10 to 20 minutes for the next comment / Gera um intervalo aleatório entre 10 e 20 minutos para o próximo comentário
    final randomMinutes =
        Random().nextInt(11) + 10; // 10-20 minutes / 10-20 minutos
    final duration = Duration(minutes: randomMinutes);

    _autoCommentTimer = Timer(duration, () async {
      await _sendAutoComment();
      _scheduleNextAutoComment(); // Schedules the subsequent comment after the current one is sent / Agenda o comentário subsequente após o envio do atual
    });
  }

  /// Starts or restarts the timer for performing daily cleanup tasks. / Inicia ou reinicia o timer para executar tarefas de limpeza diárias.
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();

    // Sets up a periodic timer for daily cleanup of old files / Configura um timer periódico para limpeza diária de arquivos antigos
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 24),
      (timer) async {
        await _performCleanup();
      },
    );
  }

  /// Updates the duck's status based on elapsed time and notifies listeners. / Atualiza o status do pato com base no tempo decorrido e notifica os ouvintes.
  Future<void> _updateDuckStatus() async {
    try {
      // Calls the duck status update logic / Chama a lógica de atualização do status do pato
      await duckStatus.updateStatus();

      // Checks if the duck has died as a result of the status update / Verifica se o pato morreu como resultado da atualização de status
      if (duckStatus.isDead) {
        onDeathDetected
            ?.call(); // Triggers the death detection callback / Aciona o callback de detecção de morte
        return;
      }

      // Notifies listeners about the updated mood of the duck / Notifica os ouvintes sobre o humor atualizado do pato
      onStatusUpdate?.call(duckStatus.getMood());
    } catch (e) {
      debugPrint(
          'Error updating duck status: $e'); // Prints an error if status update fails / Imprime um erro se a atualização de status falhar
    }
  }

  /// Sends an automatic comment using the ChatService, if API key is configured and duck is alive. / Envia um comentário automático usando o ChatService, se a chave da API estiver configurada e o pato estiver vivo.
  Future<void> _sendAutoComment() async {
    try {
      // Checks if the API key for ChatService is configured / Verifica se a chave da API para o ChatService está configurada
      final isApiConfigured = await ChatService.isApiKeyConfigured();
      if (!isApiConfigured) {
        return; // Aborts if API key is not configured to prevent sending comments / Aborta se a chave da API não estiver configurada para evitar o envio de comentários
      }

      // Prevents sending comments if the duck is currently dead / Impede o envio de comentários se o pato estiver morto
      if (duckStatus.isDead) {
        return;
      }

      // Fetches and sends an automatic comment through ChatService / Busca e envia um comentário automático através do ChatService
      final comment = await ChatService.sendAutomaticComment();
      onAutoComment?.call(
          comment); // Triggers the auto comment callback / Aciona o callback de comentário automático
    } catch (e) {
      debugPrint(
          'Error sending auto comment: $e'); // Prints an error if sending auto comment fails / Imprime um erro se o envio do comentário automático falhar
    }
  }

  /// Performs various cleanup tasks, such as deleting old screenshots. / Executa várias tarefas de limpeza, como exclusão de capturas de tela antigas.
  Future<void> _performCleanup() async {
    try {
      // Initiates the cleanup of old screenshots / Inicia a limpeza de capturas de tela antigas
      await ChatService.cleanupOldScreenshots();

      debugPrint(
          'Cleanup completed successfully'); // Logs success message / Registra mensagem de sucesso
    } catch (e) {
      debugPrint(
          'Error during cleanup: $e'); // Prints an error if cleanup fails / Imprime um erro se a limpeza falhar
    }
  }

  /// Returns the estimated time remaining until the next automatic comment is sent. / Retorna o tempo estimado restante até o próximo comentário automático ser enviado.
  Duration? getTimeUntilNextAutoComment() {
    if (_autoCommentTimer == null || !_autoCommentTimer!.isActive) {
      return null; // Returns null if the auto comment timer is not active / Retorna nulo se o timer de comentário automático não estiver ativo
    }

    // Note: The Timer class does not directly provide the remaining time.
    // This is an approximation based on the average interval. / O Timer não fornece diretamente o tempo restante. Esta é uma aproximação baseada no intervalo médio.
    return const Duration(
        minutes:
            15); // Returns an average time duration / Retorna uma duração de tempo média
  }

  /// Forces an immediate update of the duck's status. / Força uma atualização imediata do status do pato.
  Future<void> forceStatusUpdate() async {
    await _updateDuckStatus();
  }

  /// Forces an immediate dispatch of an automatic comment. / Força o envio imediato de um comentário automático.
  Future<void> forceAutoComment() async {
    await _sendAutoComment();
  }

  /// Pauses the automatic comment timer, preventing further comments until resumed. / Pausa o timer de comentários automáticos, impedindo novos comentários até ser retomado.
  void pauseAutoComments() {
    _autoCommentTimer?.cancel();
  }

  /// Resumes the automatic comment timer, scheduling the next comment. / Retoma o timer de comentários automáticos, agendando o próximo comentário.
  void resumeAutoComments() {
    _scheduleNextAutoComment();
  }

  /// Getter to check if automatic comments are currently active. / Getter para verificar se os comentários automáticos estão ativos.
  bool get areAutoCommentsActive => _autoCommentTimer?.isActive ?? false;

  /// Returns the fixed interval at which the duck's status is updated. / Retorna o intervalo fixo no qual o status do pato é atualizado.
  Duration get statusUpdateInterval => const Duration(seconds: 30);

  /// Returns the minimum and maximum range for the automatic comment interval. / Retorna o intervalo mínimo e máximo para o comentário automático.
  Map<String, int> get autoCommentIntervalRange => {
        'min':
            10, // Minimum minutes for auto comment / Mínimo de minutos para comentário automático
        'max':
            20, // Maximum minutes for auto comment / Máximo de minutos para comentário automático
      };

  /// Disposes all resources and cancels all active timers. / Descarta todos os recursos e cancela todos os timers ativos.
  void dispose() {
    stopAllTasks(); // Stops all ongoing tasks / Para todas as tarefas em andamento

    // Clears all registered callbacks to prevent memory leaks / Limpa todos os callbacks registrados para evitar vazamentos de memória
    onStatusUpdate = null;
    onAutoComment = null;
    onDeathDetected = null;
  }
}

/// Provides utility functions related to periodic tasks and time calculations. / Fornece funções utilitárias relacionadas a tarefas periódicas e cálculos de tempo.
class PeriodicTasksHelper {
  /// Formats a given duration into a human-readable string (e.g., "1h 30m 15s"). / Formata uma duração em uma string legível (ex: "1h 30m 15s").
  static String formatDuration(Duration duration) {
    final hours = duration
        .inHours; // Extracts hours from duration / Extrai as horas da duração
    final minutes = duration.inMinutes.remainder(
        60); // Extracts remaining minutes / Extrai os minutos restantes
    final seconds = duration.inSeconds.remainder(
        60); // Extracts remaining seconds / Extrai os segundos restantes

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s'; // Formats with hours, minutes, and seconds / Formata com horas, minutos e segundos
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s'; // Formats with minutes and seconds / Formata com minutos e segundos
    } else {
      return '${seconds}s'; // Formats with only seconds / Formata apenas com segundos
    }
  }

  /// Calculates the time difference between the current time and a given last action time. / Calcula a diferença de tempo entre o horário atual e um horário de última ação fornecido.
  static Duration timeSinceLastAction(DateTime lastAction) {
    return DateTime.now().difference(
        lastAction); // Returns the duration since the last action / Retorna a duração desde a última ação
  }

  /// Checks if an action is overdue based on the last action time and a maximum allowed interval. / Verifica se uma ação está atrasada com base no horário da última ação e no intervalo máximo permitido.
  static bool isActionOverdue(DateTime lastAction, Duration maxInterval) {
    return timeSinceLastAction(lastAction) >
        maxInterval; // Compares time since last action with maximum interval / Compara o tempo desde a última ação com o intervalo máximo
  }

  /// Calculates the next scheduled time for an action given its last occurrence and interval. / Calcula o próximo horário agendado para uma ação, dada sua última ocorrência e intervalo.
  static DateTime getNextScheduledTime(DateTime lastAction, Duration interval) {
    return lastAction.add(
        interval); // Adds the interval to the last action time / Adiciona o intervalo ao horário da última ação
  }

  /// Calculates an urgency level (0.0 to 1.0) based on how much time has passed relative to a maximum interval. / Calcula um nível de urgência (0.0 a 1.0) com base no tempo decorrido em relação a um intervalo máximo.
  static double calculateUrgencyLevel(
      DateTime lastAction, Duration maxInterval) {
    final timeSince = timeSinceLastAction(
        lastAction); // Time elapsed since last action / Tempo decorrido desde a última ação
    final urgencyRatio = timeSince.inMilliseconds /
        maxInterval
            .inMilliseconds; // Ratio of time elapsed to max interval / Razão do tempo decorrido para o intervalo máximo
    return urgencyRatio.clamp(0.0,
        1.0); // Clamps the value between 0.0 and 1.0 / Limita o valor entre 0.0 e 1.0
  }

  /// Returns a color string representing the urgency level (green, yellow, orange, red). / Retorna uma string de cor que representa o nível de urgência (verde, amarelo, laranja, vermelho).
  static String getUrgencyColor(double urgencyLevel) {
    if (urgencyLevel < 0.3) return 'green'; // Low urgency / Baixa urgência
    if (urgencyLevel < 0.6) return 'yellow'; // Medium urgency / Média urgência
    if (urgencyLevel < 0.9) return 'orange'; // High urgency / Alta urgência
    return 'red'; // Very high urgency / Urgência muito alta
  }
}
