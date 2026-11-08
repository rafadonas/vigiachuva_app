/// Um valor em um instante de uma série temporal (chuva, nível do córrego, umidade).
class PontoSerie {
  const PontoSerie(this.instante, this.valor);

  final DateTime instante;
  final double valor;

  Map<String, dynamic> toJson() => {'t': instante.toIso8601String(), 'v': valor};

  factory PontoSerie.fromJson(Map<String, dynamic> json) => PontoSerie(DateTime.parse(json['t'] as String), (json['v'] as num).toDouble());
}

/// Funções de apoio para séries temporais ordenadas por instante.
extension SerieTemporal on List<PontoSerie> {
  List<PontoSerie> ate(DateTime limite) => where((p) => !p.instante.isAfter(limite)).toList();

  List<PontoSerie> depoisDe(DateTime limite) => where((p) => p.instante.isAfter(limite)).toList();

  double get soma => fold(0.0, (s, p) => s + p.valor);

  double get maximo => isEmpty ? 0 : map((p) => p.valor).reduce((a, b) => a > b ? a : b);

  double get media => isEmpty ? 0 : soma / length;
}
