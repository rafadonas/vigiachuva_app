import 'package:vigiachuva/data/modelos/ponto_serie.dart';
import 'package:vigiachuva/data/modelos/previsao_chuva.dart';

/// "Agora" fixo usado nos testes.
final agoraTeste = DateTime(2026, 11, 7, 15);

/// Monta uma previsão com 24 h passadas e 24 h futuras. [chuvaFutura] define a chuva por hora a partir de agora+1h.
PrevisaoChuva previsaoTeste({List<double> chuvaFutura = const [], double probabilidade = 80, DateTime? coletadaEm}) {
  final pontos = <PontoSerie>[];
  final prob = <PontoSerie>[];
  for (var h = -24; h <= 24; h++) {
    final t = agoraTeste.add(Duration(hours: h));
    final indiceFuturo = h - 1;
    final valor = (h >= 1 && indiceFuturo < chuvaFutura.length) ? chuvaFutura[indiceFuturo] : 0.0;
    pontos.add(PontoSerie(t, valor));
    prob.add(PontoSerie(t, probabilidade));
  }
  return PrevisaoChuva(precipitacao: pontos, probabilidade: prob, coletadaEm: coletadaEm ?? agoraTeste, latitude: -23.5, longitude: -46.4);
}

/// JSON no formato real da Open-Meteo (recorte).
Map<String, dynamic> jsonOpenMeteo() => {
  'latitude': -23.514938,
  'longitude': -46.42105,
  'hourly_units': {'time': 'iso8601', 'precipitation': 'mm', 'precipitation_probability': '%'},
  'hourly': {
    'time': ['2026-11-07T14:00', '2026-11-07T15:00', '2026-11-07T16:00', '2026-11-07T17:00'],
    'precipitation': [0.0, 1.2, 35.5, null],
    'precipitation_probability': [10, 40, 85, null],
  },
};
