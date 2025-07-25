import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint em logs de desenvolvimento

/// Modelo imutável que representa o estado completo do pet virtual
/// Centraliza todas as necessidades e informações vitais para facilitar gerenciamento
class DuckStatus {
  final double hunger;
  final double cleanliness;
  final double happiness;
  final DateTime lastUpdate;
  final DateTime lastFeed;
  final DateTime lastClean;
  final DateTime lastPlay;
  final bool isDead;
  final String? deathCause;

  DuckStatus({
    this.hunger = 50.0,
    this.cleanliness = 50.0,
    this.happiness = 50.0,
    DateTime? lastUpdate,
    DateTime? lastFeed,
    DateTime? lastClean,
    DateTime? lastPlay,
    this.isDead = false,
    this.deathCause,
  })  : lastUpdate = lastUpdate ?? DateTime.now(),
        lastFeed = lastFeed ?? DateTime.now(),
        lastClean = lastClean ?? DateTime.now(),
        lastPlay = lastPlay ?? DateTime.now();

  /// Método copyWith necessário para Riverpod - permite atualizações imutáveis
  /// Essencial para notificar listeners de mudanças de estado de forma eficiente
  DuckStatus copyWith({
    double? hunger,
    double? cleanliness,
    double? happiness,
    DateTime? lastUpdate,
    DateTime? lastFeed,
    DateTime? lastClean,
    DateTime? lastPlay,
    bool? isDead,
    String? deathCause,
  }) {
    return DuckStatus(
      hunger: hunger ?? this.hunger,
      cleanliness: cleanliness ?? this.cleanliness,
      happiness: happiness ?? this.happiness,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lastFeed: lastFeed ?? this.lastFeed,
      lastClean: lastClean ?? this.lastClean,
      lastPlay: lastPlay ?? this.lastPlay,
      isDead: isDead ?? this.isDead,
      deathCause: deathCause ?? this.deathCause,
    );
  }

  // Valores calibrados para simular necessidades realistas de um pet virtual
  static const double hungerDecayRate =
      10.0; // Fome decai rapidamente para manter engajamento
  static const double cleanlinessDecayRate =
      5.0; // Higiene decai moderadamente
  static const double happinessDecayRate =
      7.0; // Felicidade precisa de atenção regular
  static const double deathThreshold =
      5.0; // Limiar baixo para evitar morte acidental

  /// Indica quando o pet precisa de atenção urgente para evitar negligência
  bool get needsAttention => hunger < 30 || cleanliness < 30 || happiness < 30;

  /// Determina humor baseado na média dos stats para feedback visual/textual
  String getMood() {
    if (isDead) return 'dead';
    final averageStatus = (hunger + cleanliness + happiness) / 3;
    if (averageStatus > 70) return 'happy';
    if (averageStatus > 40) return 'neutral';
    if (averageStatus > 20) return 'sad';
    return 'critical';
  }

  /// Fornece percentuais para barras de progresso e indicadores visuais
  Map<String, double> getStatusPercentages() {
    return {
      'hunger': hunger,
      'cleanliness': cleanliness,
      'happiness': happiness,
    };
  }

  // Serialização necessária para persistir estado entre sessões do aplicativo
  Map<String, dynamic> toMap() => {
        'hunger': hunger,
        'cleanliness': cleanliness,
        'happiness': happiness,
        'lastUpdate': lastUpdate.millisecondsSinceEpoch,
        'lastFeed': lastFeed.millisecondsSinceEpoch,
        'lastClean': lastClean.millisecondsSinceEpoch,
        'lastPlay': lastPlay.millisecondsSinceEpoch,
        'isDead': isDead,
        'deathCause': deathCause,
      };

  /// Desserialização com valores padrão para evitar crashes em dados corrompidos
  static DuckStatus fromMap(Map<String, dynamic> map) {
    return DuckStatus(
      hunger: map['hunger'] ?? 50.0,
      cleanliness: map['cleanliness'] ?? 50.0,
      happiness: map['happiness'] ?? 50.0,
      lastUpdate: DateTime.fromMillisecondsSinceEpoch(
          map['lastUpdate'] ?? DateTime.now().millisecondsSinceEpoch),
      lastFeed: DateTime.fromMillisecondsSinceEpoch(
          map['lastFeed'] ?? DateTime.now().millisecondsSinceEpoch),
      lastClean: DateTime.fromMillisecondsSinceEpoch(
          map['lastClean'] ?? DateTime.now().millisecondsSinceEpoch),
      lastPlay: DateTime.fromMillisecondsSinceEpoch(
          map['lastPlay'] ?? DateTime.now().millisecondsSinceEpoch),
      isDead: map['isDead'] ?? false,
      deathCause: map['deathCause'],
    );
  }
}

/// Gerenciador de estado reativo que notifica mudanças automaticamente
/// Riverpod StateNotifier essencial para sincronizar UI com dados do pet
class DuckStatusNotifier extends StateNotifier<DuckStatus> {
  DuckStatusNotifier() : super(DuckStatus());

  /// Carrega estado persistido para manter continuidade entre sessões
  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'hunger': prefs.getDouble('hunger') ?? 50.0,
      'cleanliness': prefs.getDouble('cleanliness') ?? 50.0,
      'happiness': prefs.getDouble('happiness') ?? 50.0,
      'lastUpdate':
          prefs.getInt('lastUpdate') ?? DateTime.now().millisecondsSinceEpoch,
      'lastFeed':
          prefs.getInt('lastFeed') ?? DateTime.now().millisecondsSinceEpoch,
      'lastClean':
          prefs.getInt('lastClean') ?? DateTime.now().millisecondsSinceEpoch,
      'lastPlay':
          prefs.getInt('lastPlay') ?? DateTime.now().millisecondsSinceEpoch,
      'isDead': prefs.getBool('isDead') ?? false,
      'deathCause': prefs.getString('deathCause'),
    };

    // Logs detalhados para debugging de problemas de persistência e carregamento
    debugPrint('[DuckStatus] Carregado do SharedPreferences:');
    debugPrint('  Hunger: ${map['hunger']}');
    debugPrint('  Cleanliness: ${map['cleanliness']}');
    debugPrint('  Happiness: ${map['happiness']}');
    debugPrint('  lastUpdate: '
        '${DateTime.fromMillisecondsSinceEpoch((map['lastUpdate'] as int)).toLocal().toString().substring(11, 16)}');
    debugPrint('  lastFeed: '
        '${DateTime.fromMillisecondsSinceEpoch((map['lastFeed'] as int)).toLocal().toString().substring(11, 16)}');
    debugPrint('  lastClean: '
        '${DateTime.fromMillisecondsSinceEpoch((map['lastClean'] as int)).toLocal().toString().substring(11, 16)}');
    debugPrint('  lastPlay: '
        '${DateTime.fromMillisecondsSinceEpoch((map['lastPlay'] as int)).toLocal().toString().substring(11, 16)}');
    debugPrint('  isDead: ${map['isDead']}');
    debugPrint('  deathCause: ${map['deathCause']}');

    state = DuckStatus.fromMap(map);
    // Atualização imediata necessária para aplicar decay de tempo ausente
    updateStatus();
  }

  /// Persiste estado atual para manter dados entre sessões
  Future<void> saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('hunger', state.hunger);
    await prefs.setDouble('cleanliness', state.cleanliness);
    await prefs.setDouble('happiness', state.happiness);
    await prefs.setInt('lastUpdate', state.lastUpdate.millisecondsSinceEpoch);
    await prefs.setInt('lastFeed', state.lastFeed.millisecondsSinceEpoch);
    await prefs.setInt('lastClean', state.lastClean.millisecondsSinceEpoch);
    await prefs.setInt('lastPlay', state.lastPlay.millisecondsSinceEpoch);
    await prefs.setBool('isDead', state.isDead);
    if (state.deathCause != null) {
      await prefs.setString('deathCause', state.deathCause!);
    }
  }

  /// Aumenta fome e registra timestamp para cálculos de decay
  void feed() {
    if (state.isDead) return; // Pet morto não pode ser alimentado
    state = state.copyWith(
      hunger: (state.hunger + 50.0).clamp(0.0, 100.0),
      lastFeed: DateTime.now(),
    );
    saveToPreferences();
  }

  /// Melhora higiene e atualiza timestamp para tracking de necessidades
  void clean() {
    if (state.isDead) return;
    state = state.copyWith(
      cleanliness: (state.cleanliness + 50.0).clamp(0.0, 100.0),
      lastClean: DateTime.now(),
    );
    saveToPreferences();
  }

  /// Aumenta felicidade através de interação e brincadeira
  void play() {
    if (state.isDead) return;
    state = state.copyWith(
      happiness: (state.happiness + 50.0).clamp(0.0, 100.0),
      lastPlay: DateTime.now(),
    );
    saveToPreferences();
  }

  /// Ressuscita o pet resetando completamente o estado para novo começo
  void revive() {
    final wasDeadBefore = state.isDead;
    state = DuckStatus();
    saveToPreferences();

    if (wasDeadBefore) {
      debugPrint('[DuckStatus] Pato reviveu - resetando status');
    }
  }

  /// Aplica degradação natural baseada no tempo para simular necessidades realistas
  void updateStatus() {
    if (state.isDead) return;
    final now = DateTime.now();
    final minutesElapsed =
        now.difference(state.lastUpdate).inMinutes.toDouble();
    final hoursElapsed = minutesElapsed / 60.0;
    if (minutesElapsed > 0) {
      final newHunger =
          (state.hunger - (DuckStatus.hungerDecayRate * hoursElapsed))
              .clamp(0.0, 100.0);
      final newCleanliness =
          (state.cleanliness - (DuckStatus.cleanlinessDecayRate * hoursElapsed))
              .clamp(0.0, 100.0);
      final newHappiness =
          (state.happiness - (DuckStatus.happinessDecayRate * hoursElapsed))
              .clamp(0.0, 100.0);
      state = state.copyWith(
        hunger: newHunger,
        cleanliness: newCleanliness,
        happiness: newHappiness,
        lastUpdate: now,
      );
      saveToPreferences();
    }
    // Sistema de morte realista que considera tempo + valores baixos para criar consequências
    final deathThreshold = DuckStatus.deathThreshold;
    final nowDT = DateTime.now();
    final durationSinceFeed = nowDT.difference(state.lastFeed);
    final durationSinceClean = nowDT.difference(state.lastClean);
    final durationSincePlay = nowDT.difference(state.lastPlay);
    const deathMinutes =
        60 * 24; // Tempo de tolerância curto para manter engajamento (24 horas)
    if (state.hunger <= deathThreshold &&
        durationSinceFeed.inMinutes >= deathMinutes) {
      state = state.copyWith(isDead: true, deathCause: 'hunger');
      saveToPreferences();
      return;
    }
    if (state.cleanliness <= deathThreshold &&
        durationSinceClean.inMinutes >= deathMinutes) {
      state = state.copyWith(isDead: true, deathCause: 'dirty');
      saveToPreferences();
      return;
    }
    if (state.happiness <= deathThreshold &&
        durationSincePlay.inMinutes >= deathMinutes) {
      state = state.copyWith(isDead: true, deathCause: 'sadness');
      saveToPreferences();
      return;
    }
  }
}

/// Provider global que disponibiliza o estado do pato para toda a aplicação
/// Riverpod Provider essencial para injeção de dependência e gerenciamento reativo
final duckStatusProvider =
    StateNotifierProvider<DuckStatusNotifier, DuckStatus>((ref) {
  final notifier = DuckStatusNotifier();
  // Carregamento inicial automático para recuperar estado persistido
  notifier.loadFromPreferences();
  return notifier;
});
