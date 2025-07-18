import 'package:shared_preferences/shared_preferences.dart';

/// Sistema de gerenciamento de status do pato
class DuckStatus {
  // Nível atual de fome do pato (0-100)
  double hunger = 50.0; // Nível de fome
  // Nível atual de limpeza do pato (0-100)
  double cleanliness = 50.0; // Nível de limpeza
  // Nível atual de felicidade do pato (0-100)
  double happiness = 50.0; // Nível de felicidade

  // Timestamps para rastrear a última vez que cada status foi atualizado ou uma ação foi realizada
  DateTime lastUpdate =
      DateTime.now(); // Última vez que o status geral foi atualizado
  DateTime lastFeed = DateTime.now(); // Última vez que o pato foi alimentado
  DateTime lastClean = DateTime.now(); // Última vez que o pato foi limpo
  DateTime lastPlay = DateTime.now(); // Última vez que o pato foi brincado

  // Flags para indicar se o pato está morto e a causa da morte
  bool isDead = false; // Verdadeiro se o pato estiver morto
  String? deathCause; // A causa da morte (ex: 'fome', 'sujeira', 'tristeza')

  // Taxas pelas quais cada status se degrada por hora
  static const double hungerDecayRate =
      10.0; // A fome diminui em 10 pontos por hora
  static const double cleanlinessDecayRate =
      5.0; // A limpeza diminui em 5 ponto por hora
  static const double happinessDecayRate =
      7.0; // A felicidade diminui em 7 pontos por hora

  // O limiar abaixo do qual um status faz o pato morrer
  static const double deathThreshold =
      5.0; // O pato morre quando qualquer status cai abaixo de 5

  /// Construtor para DuckStatus.
  DuckStatus();

  /// Carrega o status do pato do SharedPreferences, incluindo fome, limpeza, felicidade e timestamps.
  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences
        .getInstance(); // Obtém a instância do SharedPreferences

    // Carrega valores de status individuais, padronizando para 50.0 se não encontrados
    hunger = prefs.getDouble('hunger') ?? 50.0;
    cleanliness = prefs.getDouble('cleanliness') ?? 50.0;
    happiness = prefs.getDouble('happiness') ?? 50.0;

    // Carrega timestamps, convertendo de milissegundos desde a época, padronizando para a hora atual se não encontrados
    lastUpdate = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt('lastUpdate') ??
          DateTime.now().millisecondsSinceEpoch, // Hora da última atualização
    );
    lastFeed = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt('lastFeed') ??
          DateTime.now().millisecondsSinceEpoch, // Hora da última alimentação
    );
    lastClean = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt('lastClean') ??
          DateTime.now().millisecondsSinceEpoch, // Hora da última limpeza
    );
    lastPlay = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt('lastPlay') ??
          DateTime.now().millisecondsSinceEpoch, // Hora da última brincadeira
    );

    // Carrega o status de morte do pato e a causa
    isDead = prefs.getBool('isDead') ?? false; // Se o pato está morto
    deathCause = prefs.getString('deathCause'); // A causa da morte

    // Atualiza o status com base no tempo decorrido desde a última atualização
    await updateStatus();
  }

  /// Salva o status atual do pato (fome, limpeza, felicidade, timestamps, status de morte) no SharedPreferences.
  Future<void> saveToPreferences() async {
    final prefs = await SharedPreferences
        .getInstance(); // Obtém a instância do SharedPreferences

    // Salva valores de status individuais
    await prefs.setDouble('hunger', hunger);
    await prefs.setDouble('cleanliness', cleanliness);
    await prefs.setDouble('happiness', happiness);

    // Salva timestamps como milissegundos desde a época
    await prefs.setInt('lastUpdate', lastUpdate.millisecondsSinceEpoch);
    await prefs.setInt('lastFeed', lastFeed.millisecondsSinceEpoch);
    await prefs.setInt('lastClean', lastClean.millisecondsSinceEpoch);
    await prefs.setInt('lastPlay', lastPlay.millisecondsSinceEpoch);

    // Salva o status de morte do pato e a causa
    await prefs.setBool('isDead', isDead);
    if (deathCause != null) {
      await prefs.setString('deathCause',
          deathCause!); // Salva apenas se uma causa de morte existir
    }
  }

  /// Atualiza os níveis de fome, limpeza e felicidade do pato com base no tempo decorrido desde a última atualização.
  Future<void> updateStatus() async {
    if (isDead) {
      return; // Se o pato estiver morto, nenhuma atualização de status é necessária
    }

    final now = DateTime.now(); // Timestamp atual
    // Calcula as horas decorridas desde a última atualização (com precisão de minutos)
    final minutesElapsed = now.difference(lastUpdate).inMinutes.toDouble();
    final hoursElapsed = minutesElapsed / 60.0;

    if (minutesElapsed > 0) {
      // Diminui cada valor de status com base na sua taxa de degradação e horas decorridas, limitando os valores entre 0 e 100
      hunger = (hunger - (hungerDecayRate * hoursElapsed)).clamp(0.0, 100.0);
      cleanliness = (cleanliness - (cleanlinessDecayRate * hoursElapsed))
          .clamp(0.0, 100.0);
      happiness =
          (happiness - (happinessDecayRate * hoursElapsed)).clamp(0.0, 100.0);

      lastUpdate = now; // Atualiza o timestamp da última atualização para agora

      await checkForDeath(); // Verifica se o pato morreu como resultado da atualização de status

      await saveToPreferences(); // Salva o status atualizado nas preferências
    }
  }

  /// Verifica se o status do pato caiu abaixo do limiar de morte ou se as necessidades críticas não foram atendidas por muito tempo, marcando-o como morto se as condições forem atendidas.
  Future<void> checkForDeath() async {
    final now = DateTime.now(); // Timestamp atual

    // Define o número de minutos para verificar necessidades críticas atrasadas (24 horas = 1440 minutos)
    const criticalMinutes = 24 * 60;

    // Verifica se o pato morreu devido à fome prolongada e nível de fome baixo
    if (now.difference(lastFeed).inMinutes >= criticalMinutes &&
        hunger < deathThreshold) {
      isDead = true; // Marca o pato como morto
      deathCause = 'hunger'; // Define a causa da morte como fome
    } else if (now.difference(lastClean).inMinutes >= criticalMinutes &&
        cleanliness < deathThreshold) {
      isDead = true; // Marca o pato como morto
      deathCause = 'dirty'; // Define a causa da morte como sujeira
    } else if (now.difference(lastPlay).inMinutes >= criticalMinutes &&
        happiness < deathThreshold) {
      isDead = true; // Marca o pato como morto
      deathCause = 'sadness'; // Define a causa da morte como tristeza
    }

    // Também verifica se algum nível de status atingiu zero, indicando morte imediata
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

  /// Aumenta o nível de fome do pato e atualiza o timestamp da última alimentação.
  Future<void> feed() async {
    if (isDead) return; // Não pode alimentar um pato morto

    hunger = (hunger + 30.0).clamp(
        0.0, 100.0); // Aumenta a fome em 30 pontos, limitado entre 0 e 100
    lastFeed = DateTime.now(); // Atualiza o timestamp da última alimentação
    await updateStatus(); // Atualiza o status geral
    await saveToPreferences(); // Salva o status atualizado
  }

  /// Aumenta o nível de limpeza do pato e atualiza o timestamp da última limpeza.
  Future<void> clean() async {
    if (isDead) return; // Não pode limpar um pato morto

    cleanliness = (cleanliness + 35.0).clamp(
        0.0, 100.0); // Aumenta a limpeza em 35 pontos, limitado entre 0 e 100
    lastClean = DateTime.now(); // Atualiza o timestamp da última limpeza
    await updateStatus(); // Atualiza o status geral
    await saveToPreferences(); // Salva o status atualizado
  }

  /// Aumenta o nível de felicidade do pato e atualiza o timestamp da última brincadeira.
  Future<void> play() async {
    if (isDead) return; // Não pode brincar com um pato morto

    happiness = (happiness + 40.0).clamp(0.0,
        100.0); // Aumenta a felicidade em 40 pontos, limitado entre 0 e 100
    lastPlay = DateTime.now(); // Atualiza o timestamp da última brincadeira
    await updateStatus(); // Atualiza o status geral
    await saveToPreferences(); // Salva o status atualizado
  }

  /// Revive o pato redefinindo seu status de morte e restaurando todos os atributos para níveis médios.
  Future<void> revive() async {
    isDead = false; // Define o pato como vivo
    deathCause = null; // Limpa a causa da morte

    // Redefine fome, limpeza e felicidade para seus valores médios padrão
    hunger = 50.0;
    cleanliness = 50.0;
    happiness = 50.0;

    // Redefine todos os timestamps para a hora atual
    final now = DateTime.now();
    lastUpdate = now;
    lastFeed = now;
    lastClean = now;
    lastPlay = now;

    await updateStatus(); // Atualiza o status geral
    await saveToPreferences(); // Salva o status de revivido
  }

  /// Getter que retorna verdadeiro se a fome, limpeza ou felicidade do pato estiverem abaixo de um certo limiar (precisa de atenção).
  bool get needsAttention =>
      hunger < 30 ||
      cleanliness < 30 ||
      happiness < 30; // Verdadeiro se qualquer status crítico estiver baixo

  /// Calcula e retorna o humor geral do pato com base na média de seus níveis de fome, limpeza e felicidade.
  String getMood() {
    if (isDead) return 'dead'; // Se morto, o humor é 'morto'

    final averageStatus =
        (hunger + cleanliness + happiness) / 3; // Calcula o status médio

    if (averageStatus > 70) {
      return 'happy'; // Retorna 'happy' para status médio alto
    }
    if (averageStatus > 40) {
      return 'neutral'; // Retorna 'neutral' para status médio
    }
    if (averageStatus > 20) {
      return 'sad'; // Retorna 'sad' para status médio baixo
    }
    return 'critical'; // Retorna 'critical' para status médio muito baixo
  }

  /// Retorna um mapa contendo os níveis atuais de fome, limpeza e felicidade como porcentagens.
  Map<String, double> getStatusPercentages() {
    return {
      'hunger': hunger, // Porcentagem de fome
      'cleanliness': cleanliness, // Porcentagem de limpeza
      'happiness': happiness, // Porcentagem de felicidade
    };
  }
}
