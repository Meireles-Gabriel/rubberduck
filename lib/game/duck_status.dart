import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

/// Sistema de gerenciamento de status do pato
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

  static const double hungerDecayRate = 1000.0;
  static const double cleanlinessDecayRate = 500.0;
  static const double happinessDecayRate = 700.0;
  static const double deathThreshold = 5.0;

  bool get needsAttention => hunger < 30 || cleanliness < 30 || happiness < 30;

  String getMood() {
    if (isDead) return 'dead';
    final averageStatus = (hunger + cleanliness + happiness) / 3;
    if (averageStatus > 70) return 'happy';
    if (averageStatus > 40) return 'neutral';
    if (averageStatus > 20) return 'sad';
    return 'critical';
  }

  Map<String, double> getStatusPercentages() {
    return {
      'hunger': hunger,
      'cleanliness': cleanliness,
      'happiness': happiness,
    };
  }

  // Métodos de serialização para persistência
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

class DuckStatusNotifier extends StateNotifier<DuckStatus> {
  DuckStatusNotifier() : super(DuckStatus());

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
    // Verifica imediatamente as necessidades e se o pato deve estar morto
    updateStatus();
  }

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

  void feed() {
    if (state.isDead) return;
    state = state.copyWith(
      hunger: (state.hunger + 50.0).clamp(0.0, 100.0),
      lastFeed: DateTime.now(),
    );
    saveToPreferences();
  }

  void clean() {
    if (state.isDead) return;
    state = state.copyWith(
      cleanliness: (state.cleanliness + 50.0).clamp(0.0, 100.0),
      lastClean: DateTime.now(),
    );
    saveToPreferences();
  }

  void play() {
    if (state.isDead) return;
    state = state.copyWith(
      happiness: (state.happiness + 50.0).clamp(0.0, 100.0),
      lastPlay: DateTime.now(),
    );
    saveToPreferences();
  }

  void revive() {
    final wasDeadBefore = state.isDead;
    state = DuckStatus();
    saveToPreferences();

    if (wasDeadBefore) {
      debugPrint('[DuckStatus] Pato reviveu - resetando status');
    }
  }

  // Atualização baseada no tempo decorrido
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
    // Lógica de morte automática
    final deathThreshold = DuckStatus.deathThreshold;
    final nowDT = DateTime.now();
    final durationSinceFeed = nowDT.difference(state.lastFeed);
    final durationSinceClean = nowDT.difference(state.lastClean);
    final durationSincePlay = nowDT.difference(state.lastPlay);
    const deathHours = 1;
    if (state.hunger <= deathThreshold &&
        durationSinceFeed.inHours >= deathHours) {
      state = state.copyWith(isDead: true, deathCause: 'hunger');
      saveToPreferences();
      return;
    }
    if (state.cleanliness <= deathThreshold &&
        durationSinceClean.inHours >= deathHours) {
      state = state.copyWith(isDead: true, deathCause: 'dirty');
      saveToPreferences();
      return;
    }
    if (state.happiness <= deathThreshold &&
        durationSincePlay.inHours >= deathHours) {
      state = state.copyWith(isDead: true, deathCause: 'sadness');
      saveToPreferences();
      return;
    }
  }
}

final duckStatusProvider =
    StateNotifierProvider<DuckStatusNotifier, DuckStatus>((ref) {
  final notifier = DuckStatusNotifier();
  notifier.loadFromPreferences();
  return notifier;
});
