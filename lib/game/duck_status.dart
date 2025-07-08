import 'package:shared_preferences/shared_preferences.dart';

/// Duck status management system / Sistema de gerenciamento de status do pato
class DuckStatus {
  // Current hunger level of the duck (0-100) / Nível atual de fome do pato (0-100)
  double hunger = 50.0; // Hunger level / Nível de fome
  // Current cleanliness level of the duck (0-100) / Nível atual de limpeza do pato (0-100)
  double cleanliness = 50.0; // Cleanliness level / Nível de limpeza
  // Current happiness level of the duck (0-100) / Nível atual de felicidade do pato (0-100)
  double happiness = 50.0; // Happiness level / Nível de felicidade

  // Timestamps to track the last time each status was updated or an action was performed / Timestamps para rastrear a última vez que cada status foi atualizado ou uma ação foi realizada
  DateTime lastUpdate = DateTime
      .now(); // Last time the overall status was updated / Última vez que o status geral foi atualizado
  DateTime lastFeed = DateTime
      .now(); // Last time the duck was fed / Última vez que o pato foi alimentado
  DateTime lastClean = DateTime
      .now(); // Last time the duck was cleaned / Última vez que o pato foi limpo
  DateTime lastPlay = DateTime
      .now(); // Last time the duck was played with / Última vez que o pato foi brincado

  // Flags to indicate if the duck is dead and the cause of death / Flags para indicar se o pato está morto e a causa da morte
  bool isDead =
      false; // True if the duck is dead / Verdadeiro se o pato estiver morto
  String?
      deathCause; // The cause of death (e.g., 'hunger', 'dirty', 'sadness') / A causa da morte (ex: 'fome', 'sujeira', 'tristeza')

  // Rates at which each status degrades per hour / Taxas pelas quais cada status se degrada por hora
  static const double hungerDecayRate =
      4.0; // Hunger decreases by 4 points per hour / A fome diminui em 4 pontos por hora
  static const double cleanlinessDecayRate =
      2.0; // Cleanliness decreases by 2 points per hour / A limpeza diminui em 2 pontos por hora
  static const double happinessDecayRate =
      3.0; // Happiness decreases by 3 points per hour / A felicidade diminui em 3 pontos por hora

  // The threshold below which a status causes the duck to die / O limiar abaixo do qual um status faz o pato morrer
  static const double deathThreshold =
      5.0; // Duck dies when any status drops below 5 / O pato morre quando qualquer status cai abaixo de 5

  /// Constructor for DuckStatus. / Construtor para DuckStatus.
  DuckStatus();

  /// Loads the duck's status from SharedPreferences, including hunger, cleanliness, happiness, and timestamps. / Carrega o status do pato do SharedPreferences, incluindo fome, limpeza, felicidade e timestamps.
  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences
        .getInstance(); // Gets the SharedPreferences instance / Obtém a instância do SharedPreferences

    // Loads individual status values, defaulting to 50.0 if not found / Carrega valores de status individuais, padronizando para 50.0 se não encontrados
    hunger = prefs.getDouble('hunger') ?? 50.0;
    cleanliness = prefs.getDouble('cleanliness') ?? 50.0;
    happiness = prefs.getDouble('happiness') ?? 50.0;

    // Loads timestamps, converting from milliseconds since epoch, defaulting to current time if not found / Carrega timestamps, convertendo de milissegundos desde a época, padronizando para a hora atual se não encontrados
    lastUpdate = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt('lastUpdate') ??
          DateTime.now()
              .millisecondsSinceEpoch, // Last update time / Hora da última atualização
    );
    lastFeed = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt('lastFeed') ??
          DateTime.now()
              .millisecondsSinceEpoch, // Last fed time / Hora da última alimentação
    );
    lastClean = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt('lastClean') ??
          DateTime.now()
              .millisecondsSinceEpoch, // Last cleaned time / Hora da última limpeza
    );
    lastPlay = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt('lastPlay') ??
          DateTime.now()
              .millisecondsSinceEpoch, // Last played time / Hora da última brincadeira
    );

    // Loads the duck's death status and cause / Carrega o status de morte do pato e a causa
    isDead = prefs.getBool('isDead') ??
        false; // Whether the duck is dead / Se o pato está morto
    deathCause =
        prefs.getString('deathCause'); // The cause of death / A causa da morte

    // Updates the status based on the time passed since the last update / Atualiza o status com base no tempo decorrido desde a última atualização
    await updateStatus();
  }

  /// Saves the duck's current status (hunger, cleanliness, happiness, timestamps, death status) to SharedPreferences. / Salva o status atual do pato (fome, limpeza, felicidade, timestamps, status de morte) no SharedPreferences.
  Future<void> saveToPreferences() async {
    final prefs = await SharedPreferences
        .getInstance(); // Gets the SharedPreferences instance / Obtém a instância do SharedPreferences

    // Saves individual status values / Salva valores de status individuais
    await prefs.setDouble('hunger', hunger);
    await prefs.setDouble('cleanliness', cleanliness);
    await prefs.setDouble('happiness', happiness);

    // Saves timestamps as milliseconds since epoch / Salva timestamps como milissegundos desde a época
    await prefs.setInt('lastUpdate', lastUpdate.millisecondsSinceEpoch);
    await prefs.setInt('lastFeed', lastFeed.millisecondsSinceEpoch);
    await prefs.setInt('lastClean', lastClean.millisecondsSinceEpoch);
    await prefs.setInt('lastPlay', lastPlay.millisecondsSinceEpoch);

    // Saves the duck's death status and cause / Salva o status de morte do pato e a causa
    await prefs.setBool('isDead', isDead);
    if (deathCause != null) {
      await prefs.setString('deathCause',
          deathCause!); // Only save if a death cause exists / Salva apenas se uma causa de morte existir
    }
  }

  /// Updates the duck's hunger, cleanliness, and happiness levels based on the time elapsed since the last update. / Atualiza os níveis de fome, limpeza e felicidade do pato com base no tempo decorrido desde a última atualização.
  Future<void> updateStatus() async {
    if (isDead)
      return; // If the duck is dead, no status updates are needed / Se o pato estiver morto, nenhuma atualização de status é necessária

    final now = DateTime.now(); // Current timestamp / Timestamp atual
    // Calculates hours elapsed since the last update / Calcula as horas decorridas desde a última atualização
    final hoursElapsed =
        now.difference(lastUpdate).inMilliseconds / (1000 * 60 * 60);

    if (hoursElapsed > 0) {
      // Decreases each status value based on its decay rate and elapsed hours, clamping values between 0 and 100 / Diminui cada valor de status com base na sua taxa de degradação e horas decorridas, limitando os valores entre 0 e 100
      hunger = (hunger - (hungerDecayRate * hoursElapsed)).clamp(0.0, 100.0);
      cleanliness = (cleanliness - (cleanlinessDecayRate * hoursElapsed))
          .clamp(0.0, 100.0);
      happiness =
          (happiness - (happinessDecayRate * hoursElapsed)).clamp(0.0, 100.0);

      lastUpdate =
          now; // Updates the last update timestamp to now / Atualiza o timestamp da última atualização para agora

      await checkForDeath(); // Checks if the duck has died as a result of the status update / Verifica se o pato morreu como resultado da atualização de status

      await saveToPreferences(); // Saves the updated status to preferences / Salva o status atualizado nas preferências
    }
  }

  /// Checks if the duck's status has dropped below the death threshold or if critical needs haven't been met for too long, marking it as dead if conditions are met. / Verifica se o status do pato caiu abaixo do limiar de morte ou se as necessidades críticas não foram atendidas por muito tempo, marcando-o como morto se as condições forem atendidas.
  Future<void> checkForDeath() async {
    final now = DateTime.now(); // Current timestamp / Timestamp atual

    // Defines the duration of a day in milliseconds for checking overdue critical needs / Define a duração de um dia em milissegundos para verificar necessidades críticas atrasadas
    final dayInMilliseconds = 24 * 60 * 60 * 1000;

    // Checks if the duck has died due to prolonged hunger and low hunger level / Verifica se o pato morreu devido à fome prolongada e nível de fome baixo
    if (now.difference(lastFeed).inMilliseconds > dayInMilliseconds &&
        hunger < deathThreshold) {
      isDead = true; // Marks the duck as dead / Marca o pato como morto
      deathCause =
          'hunger'; // Sets the cause of death to hunger / Define a causa da morte como fome
    } else if (now.difference(lastClean).inMilliseconds > dayInMilliseconds &&
        cleanliness < deathThreshold) {
      isDead = true; // Marks the duck as dead / Marca o pato como morto
      deathCause =
          'dirty'; // Sets the cause of death to dirtiness / Define a causa da morte como sujeira
    } else if (now.difference(lastPlay).inMilliseconds > dayInMilliseconds &&
        happiness < deathThreshold) {
      isDead = true; // Marks the duck as dead / Marca o pato como morto
      deathCause =
          'sadness'; // Sets the cause of death to sadness / Define a causa da morte como tristeza
    }

    // Also checks if any status level has reached zero, indicating immediate death / Também verifica se algum nível de status atingiu zero, indicando morte imediata
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

  /// Increases the duck's hunger level and updates the last fed timestamp. / Aumenta o nível de fome do pato e atualiza o timestamp da última alimentação.
  Future<void> feed() async {
    if (isDead)
      return; // Cannot feed a dead duck / Não pode alimentar um pato morto

    hunger = (hunger + 30.0).clamp(0.0,
        100.0); // Increases hunger by 30 points, clamped between 0 and 100 / Aumenta a fome em 30 pontos, limitado entre 0 e 100
    lastFeed = DateTime
        .now(); // Updates the last fed timestamp / Atualiza o timestamp da última alimentação
    await saveToPreferences(); // Saves the updated status / Salva o status atualizado
  }

  /// Increases the duck's cleanliness level and updates the last cleaned timestamp. / Aumenta o nível de limpeza do pato e atualiza o timestamp da última limpeza.
  Future<void> clean() async {
    if (isDead)
      return; // Cannot clean a dead duck / Não pode limpar um pato morto

    cleanliness = (cleanliness + 35.0).clamp(0.0,
        100.0); // Increases cleanliness by 35 points, clamped between 0 and 100 / Aumenta a limpeza em 35 pontos, limitado entre 0 e 100
    lastClean = DateTime
        .now(); // Updates the last cleaned timestamp / Atualiza o timestamp da última limpeza
    await saveToPreferences(); // Saves the updated status / Salva o status atualizado
  }

  /// Increases the duck's happiness level and updates the last played timestamp. / Aumenta o nível de felicidade do pato e atualiza o timestamp da última brincadeira.
  Future<void> play() async {
    if (isDead)
      return; // Cannot play with a dead duck / Não pode brincar com um pato morto

    happiness = (happiness + 40.0).clamp(0.0,
        100.0); // Increases happiness by 40 points, clamped between 0 and 100 / Aumenta a felicidade em 40 pontos, limitado entre 0 e 100
    lastPlay = DateTime
        .now(); // Updates the last played timestamp / Atualiza o timestamp da última brincadeira
    await saveToPreferences(); // Saves the updated status / Salva o status atualizado
  }

  /// Revives the duck by resetting its death status and restoring all attributes to medium levels. / Revive o pato redefinindo seu status de morte e restaurando todos os atributos para níveis médios.
  Future<void> revive() async {
    isDead = false; // Sets the duck as alive / Define o pato como vivo
    deathCause = null; // Clears the death cause / Limpa a causa da morte

    // Resets hunger, cleanliness, and happiness to their default medium values / Redefine fome, limpeza e felicidade para seus valores médios padrão
    hunger = 50.0;
    cleanliness = 50.0;
    happiness = 50.0;

    // Resets all timestamps to the current time / Redefine todos os timestamps para a hora atual
    final now = DateTime.now();
    lastUpdate = now;
    lastFeed = now;
    lastClean = now;
    lastPlay = now;

    await saveToPreferences(); // Saves the revived status / Salva o status de revivido
  }

  /// Getter that returns true if the duck's hunger, cleanliness, or happiness is below a certain threshold (needs attention). / Getter que retorna verdadeiro se a fome, limpeza ou felicidade do pato estiverem abaixo de um certo limiar (precisa de atenção).
  bool get needsAttention =>
      hunger < 30 ||
      cleanliness < 30 ||
      happiness <
          30; // True if any critical status is low / Verdadeiro se qualquer status crítico estiver baixo

  /// Returns a string indicating which specific need (hunger, dirty, sadness) requires urgent attention, or null if none. / Retorna uma string indicando qual necessidade específica (fome, sujeira, tristeza) requer atenção urgente, ou nulo se nenhuma.
  String? getAttentionMessage() {
    if (isDead)
      return null; // A dead duck doesn't need attention messages / Um pato morto não precisa de mensagens de atenção

    if (hunger < 20)
      return 'hungry'; // Returns 'hungry' if hunger is critical / Retorna 'hungry' se a fome for crítica
    if (cleanliness < 20)
      return 'dirty'; // Returns 'dirty' if cleanliness is critical / Retorna 'dirty' se a limpeza for crítica
    if (happiness < 20)
      return 'sad'; // Returns 'sad' if happiness is critical / Retorna 'sad' se a felicidade for crítica

    return null; // Returns null if no critical attention is needed / Retorna nulo se nenhuma atenção crítica for necessária
  }

  /// Calculates and returns the duck's overall mood based on the average of its hunger, cleanliness, and happiness levels. / Calcula e retorna o humor geral do pato com base na média de seus níveis de fome, limpeza e felicidade.
  String getMood() {
    if (isDead)
      return 'dead'; // If dead, mood is 'dead' / Se morto, o humor é 'morto'

    final averageStatus = (hunger + cleanliness + happiness) /
        3; // Calculates the average status / Calcula o status médio

    if (averageStatus > 70)
      return 'happy'; // Returns 'happy' for high average status / Retorna 'happy' para status médio alto
    if (averageStatus > 40)
      return 'neutral'; // Returns 'neutral' for medium average status / Retorna 'neutral' para status médio
    if (averageStatus > 20)
      return 'sad'; // Returns 'sad' for low average status / Retorna 'sad' para status médio baixo
    return 'critical'; // Returns 'critical' for very low average status / Retorna 'critical' para status médio muito baixo
  }

  /// Returns a map containing the current hunger, cleanliness, and happiness levels as percentages. / Retorna um mapa contendo os níveis atuais de fome, limpeza e felicidade como porcentagens.
  Map<String, double> getStatusPercentages() {
    return {
      'hunger': hunger, // Hunger percentage / Porcentagem de fome
      'cleanliness':
          cleanliness, // Cleanliness percentage / Porcentagem de limpeza
      'happiness':
          happiness, // Happiness percentage / Porcentagem de felicidade
    };
  }
}
