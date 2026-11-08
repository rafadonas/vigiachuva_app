import 'ponto_serie.dart';

/// Previsão horária de chuva da Open-Meteo (inclui as últimas 24 h observadas pelo modelo).
/// "precipitation" = soma da hora anterior, em mm (equivale a mm/h).
/// "precipitation_probability" = chance de mais de 0,1 mm na hora anterior, em %.
class PrevisaoChuva {
  const PrevisaoChuva({
    required this.precipitacao,
    required this.probabilidade,
    required this.coletadaEm,
    required this.latitude,
    required this.longitude,
  });

  final List<PontoSerie> precipitacao;
  final List<PontoSerie> probabilidade;
  final DateTime coletadaEm;
  final double latitude;
  final double longitude;

  factory PrevisaoChuva.daOpenMeteo(Map<String, dynamic> json, DateTime coletadaEm) {
    final horario = json['hourly'] as Map<String, dynamic>?;
    if (horario == null) {
      throw const FormatException('Resposta da Open-Meteo sem o bloco "hourly".');
    }
    final tempos = (horario['time'] as List).cast<String>();
    final chuva = horario['precipitation'] as List;
    final prob = horario['precipitation_probability'] as List;
    if (tempos.length != chuva.length || tempos.length != prob.length) {
      throw const FormatException('Séries horárias com tamanhos diferentes.');
    }
    final precipitacao = <PontoSerie>[];
    final probabilidade = <PontoSerie>[];
    for (var i = 0; i < tempos.length; i++) {
      final instante = DateTime.parse(tempos[i]);
      // Valores nulos (horas sem dado) são tratados como ausentes, não como zero.
      if (chuva[i] != null) precipitacao.add(PontoSerie(instante, (chuva[i] as num).toDouble()));
      if (prob[i] != null) probabilidade.add(PontoSerie(instante, (prob[i] as num).toDouble()));
    }
    return PrevisaoChuva(
      precipitacao: precipitacao,
      probabilidade: probabilidade,
      coletadaEm: coletadaEm,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'precipitacao': precipitacao.map((p) => p.toJson()).toList(),
    'probabilidade': probabilidade.map((p) => p.toJson()).toList(),
    'coletadaEm': coletadaEm.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };

  factory PrevisaoChuva.fromJson(Map<String, dynamic> json) => PrevisaoChuva(
    precipitacao: (json['precipitacao'] as List).map((e) => PontoSerie.fromJson(e as Map<String, dynamic>)).toList(),
    probabilidade: (json['probabilidade'] as List).map((e) => PontoSerie.fromJson(e as Map<String, dynamic>)).toList(),
    coletadaEm: DateTime.parse(json['coletadaEm'] as String),
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  List<PontoSerie> ultimas24h(DateTime agora) =>
      precipitacao.where((p) => !p.instante.isAfter(agora) && p.instante.isAfter(agora.subtract(const Duration(hours: 24)))).toList();

  List<PontoSerie> proximas(DateTime agora, int horas) =>
      precipitacao.where((p) => p.instante.isAfter(agora) && !p.instante.isAfter(agora.add(Duration(hours: horas)))).toList();

  double acumuladoUltimas24h(DateTime agora) => ultimas24h(agora).soma;

  double acumuladoProximas24h(DateTime agora) => proximas(agora, 24).soma;

  /// Hora de maior chuva prevista nas próximas [horas] (null se não houver dado).
  PontoSerie? picoProximas(DateTime agora, int horas) {
    final futuro = proximas(agora, horas);
    if (futuro.isEmpty) return null;
    return futuro.reduce((a, b) => b.valor > a.valor ? b : a);
  }

  double probabilidadeEm(DateTime instante) {
    for (final p in probabilidade) {
      if (p.instante == instante) return p.valor;
    }
    return 0;
  }

  double probabilidadeMaximaProximas(DateTime agora, int horas) =>
      probabilidade.where((p) => p.instante.isAfter(agora) && !p.instante.isAfter(agora.add(Duration(hours: horas)))).toList().maximo;
}
