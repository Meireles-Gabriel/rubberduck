import 'package:shared_preferences/shared_preferences.dart';

/// Duck status management system / Sistema de gerenciamento de status do pato
class DuckStatus {
  // Status values from 0 to 100 / Valores de status de 0 a 100
  double hunger = 50.0; // Hunger level / Nível de fome
  double cleanliness = 50.0; // Cleanliness level / Nível de limpeza
  double happiness = 50.0; // Happiness level / Nível de felicidade

  // Time tracking / Rastreamento de tempo
  DateTime lastUpdate = DateTime.now();
  DateTime lastFeed = DateTime.now();
  DateTime lastClean = DateTime.now();
  DateTime lastPlay = DateTime.now();

  // Status flags / Flags de status
  bool isDead = false;
  String? deathCause;

  // Degradation rates per hour / Taxas de degradação por hora
  static const double hungerDecayRate = 4.0; // Hunger decreases by 4 per hour / Fome diminui 4 por hora
  static const double cleanlinessDecayRate = 2.0; // Cleanliness decreases by 2 per hour / Limpeza diminui 2 por hora
  static const double happinessDecayRate = 3.0; // Happiness decreases by 3 per hour / Felicidade diminui 3 por hora

  // Death threshold / Limiar de morte
  static const double deathThreshold = 5.0; // Dies when any status drops below 5 / Morre quando qualquer status cai abaixo de 5

  /// Constructor / Construtor
  DuckStatus();

  /// Load status from preferences / Carrega status das preferências
  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load status values / Carrega valores de status
    hunger = prefs.getDouble('hunger') ?? 50.0;
    cleanliness = prefs.getDouble('cleanliness') ?? 50.0;
    happiness = prefs.getDouble('happiness') ?? 50.0;

    // Load timestamps / Carrega timestamps
    lastUpdate = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt('lastUpdate') ?? DateTime.now().millisecondsSinceEpoch,
    );
    lastFeed = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt('lastFeed') ?? DateTime.now().millisecondsSinceEpoch,
    );
    lastClean = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt('lastClean') ?? DateTime.now().millisecondsSinceEpoch,
    );
    lastPlay = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt('lastPlay') ?? DateTime.now().millisecondsSinceEpoch,
    );

    // Load death status / Carrega status de morte
    isDead = prefs.getBool('isDead') ?? false;
    deathCause = prefs.getString('deathCause');

    // Update status based on time passed / Atualiza status baseado no tempo passado
    await updateStatus();
  }

  /// Save status to preferences / Salva status nas preferências
  Future<void> saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Save status values / Salva valores de status
    await prefs.setDouble('hunger', hunger);
    await prefs.setDouble('cleanliness', cleanliness);
    await prefs.setDouble('happiness', happiness);

    // Save timestamps / Salva timestamps
    await prefs.setInt('lastUpdate', lastUpdate.millisecondsSinceEpoch);
    await prefs.setInt('lastFeed', lastFeed.millisecondsSinceEpoch);
    await prefs.setInt('lastClean', lastClean.millisecondsSinceEpoch);
    await prefs.setInt('lastPlay', lastPlay.millisecondsSinceEpoch);

    // Save death status / Salva status de morte
    await prefs.setBool('isDead', isDead);
    if (deathCause != null) {
      await prefs.setString('deathCause', deathCause!);
    }
  }

  /// Update status based on time passed / Atualiza status baseado no tempo passado
  Future<void> updateStatus() async {
    if (isDead) return; // Don't update if already dead / Não atualiza se já estiver morto

    final now = DateTime.now();
    final hoursElapsed = now.difference(lastUpdate).inMilliseconds / (1000 * 60 * 60);

    if (hoursElapsed > 0) {
      // Decrease status values / Diminui valores de status
      hunger = (hunger - (hungerDecayRate * hoursElapsed)).clamp(0.0, 100.0);
      cleanliness = (cleanliness - (cleanlinessDecayRate * hoursElapsed)).clamp(0.0, 100.0);
      happiness = (happiness - (happinessDecayRate * hoursElapsed)).clamp(0.0, 100.0);

      lastUpdate = now;

      // Check for death / Verifica por morte
      await checkForDeath();

      // Save updated status / Salva status atualizado
      await saveToPreferences();
    }
  }

  /// Check if duck should die / Verifica se o pato deve morrer
  Future<void> checkForDeath() async {
    final now = DateTime.now();

    // Check if any critical need hasn't been met in 24 hours / Verifica se alguma necessidade crítica não foi atendida em 24 horas
    final dayInMilliseconds = 24 * 60 * 60 * 1000;

    if (now.difference(lastFeed).inMilliseconds > dayInMilliseconds && hunger < deathThreshold) {
      isDead = true;
      deathCause = 'hunger';
    } else if (now.difference(lastClean).inMilliseconds > dayInMilliseconds && cleanliness < deathThreshold) {
      isDead = true;
      deathCause = 'dirty';
    } else if (now.difference(lastPlay).inMilliseconds > dayInMilliseconds && happiness < deathThreshold) {
      isDead = true;
      deathCause = 'sadness';
    }

    // Also check current status levels / Também verifica níveis atuais de status
    if (hunger <= 0) {
      isDead = true;
      deathCause = 'hunger';
    } else if (cleanliness <= 0) {
      isDead = true;
      deathCause = 'dirty';
    } else if (happiness <= 0) {
      isDead = true;
      deathCause = 'sadness';
    }
  }

  /// Feed the duck / Alimenta o pato
  Future<void> feed() async {
    if (isDead) return;

    hunger = (hunger + 30.0).clamp(0.0, 100.0);
    lastFeed = DateTime.now();
    await saveToPreferences();
  }

  /// Clean the duck / Limpa o pato
  Future<void> clean() async {
    if (isDead) return;

    cleanliness = (cleanliness + 35.0).clamp(0.0, 100.0);
    lastClean = DateTime.now();
    await saveToPreferences();
  }

  /// Play with the duck / Brinca com o pato
  Future<void> play() async {
    if (isDead) return;

    happiness = (happiness + 40.0).clamp(0.0, 100.0);
    lastPlay = DateTime.now();
    await saveToPreferences();
  }

  /// Revive the duck / Revive o pato
  Future<void> revive() async {
    isDead = false;
    deathCause = null;

    // Reset status to medium values / Reseta status para valores médios
    hunger = 50.0;
    cleanliness = 50.0;
    happiness = 50.0;

    // Reset timestamps / Reseta timestamps
    final now = DateTime.now();
    lastUpdate = now;
    lastFeed = now;
    lastClean = now;
    lastPlay = now;

    await saveToPreferences();
  }

  /// Check if duck needs attention / Verifica se o pato precisa de atenção
  bool get needsAttention => hunger < 30 || cleanliness < 30 || happiness < 30;

  /// Get attention message / Obtém mensagem de atenção
  String? getAttentionMessage() {
    if (isDead) return null;

    if (hunger < 20) return 'hungry';
    if (cleanliness < 20) return 'dirty';
    if (happiness < 20) return 'sad';

    return null;
  }

  /// Get overall mood / Obtém humor geral
  String getMood() {
    if (isDead) return 'dead';

    final averageStatus = (hunger + cleanliness + happiness) / 3;

    if (averageStatus > 70) return 'happy';
    if (averageStatus > 40) return 'neutral';
    if (averageStatus > 20) return 'sad';
    return 'critical';
  }

  /// Get status as percentage / Obtém status como porcentagem
  Map<String, double> getStatusPercentages() {
    return {
      'hunger': hunger,
      'cleanliness': cleanliness,
      'happiness': happiness,
    };
  }
}
