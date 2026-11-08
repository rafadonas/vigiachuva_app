import 'dart:math';

import '../modelos/ocorrencia.dart';
import '../modelos/ponto_serie.dart';
import '../modelos/previsao_chuva.dart';

/// Gera os dados SINTÉTICOS do território (não há sensores reais no protótipo).
///
/// O nível do córrego e a umidade do solo são derivados da chuva REAL (Open-Meteo)
/// por um modelo didático, não calibrado: chuva acumulada nas últimas horas faz o
/// córrego subir e o solo encharcar. Sem dados de chuva, usa-se um padrão seco.
class DadosSinteticos {
  DadosSinteticos({int? semente}) : _semente = semente;

  final int? _semente;

  static const double nivelBaseM = 1.6;
  static const double umidadeBasePct = 62;

  /// Série horária do nível do córrego (m) cobrindo o mesmo período da previsão de chuva.
  List<PontoSerie> nivelCorrego(PrevisaoChuva? chuva, DateTime agora) {
    final aleatorio = Random(_semente ?? _sementeDoDia(agora));
    final instantes = _instantes(chuva, agora);
    final mapaChuva = {for (final p in chuva?.precipitacao ?? const <PontoSerie>[]) p.instante: p.valor};
    final serie = <PontoSerie>[];
    final janela = <double>[];
    for (final t in instantes) {
      janela.add(mapaChuva[t] ?? 0);
      if (janela.length > 6) janela.removeAt(0);
      final chuva6h = janela.fold(0.0, (s, v) => s + v);
      final ruido = (aleatorio.nextDouble() - 0.5) * 0.08;
      final nivel = (nivelBaseM + chuva6h * 0.045 + ruido).clamp(0.3, 6.0);
      serie.add(PontoSerie(t, double.parse(nivel.toStringAsFixed(2))));
    }
    return serie;
  }

  /// Série horária da umidade do solo (%) na encosta.
  List<PontoSerie> umidadeSolo(PrevisaoChuva? chuva, DateTime agora) {
    final aleatorio = Random((_semente ?? _sementeDoDia(agora)) + 1);
    final instantes = _instantes(chuva, agora);
    final mapaChuva = {for (final p in chuva?.precipitacao ?? const <PontoSerie>[]) p.instante: p.valor};
    final serie = <PontoSerie>[];
    var umidade = umidadeBasePct;
    for (final t in instantes) {
      final mm = mapaChuva[t] ?? 0;
      // encharca com a chuva (0,6 ponto percentual por mm) e seca devagar (4% da diferença para a base por hora)
      umidade = umidade + mm * 0.6 - (umidade - umidadeBasePct) * 0.04 + (aleatorio.nextDouble() - 0.5) * 0.6;
      umidade = umidade.clamp(20.0, 100.0);
      serie.add(PontoSerie(t, double.parse(umidade.toStringAsFixed(1))));
    }
    return serie;
  }

  /// Relatos de EXEMPLO para os painéis não começarem vazios (marcados como exemplo).
  List<Ocorrencia> ocorrenciasExemplo(DateTime agora) {
    Ocorrencia o(String id, int horasAtras, String regiao, CategoriaOcorrencia c, NivelAgua n, String d) => Ocorrencia(
      id: 'exemplo-$id',
      regiaoId: regiao,
      categoria: c,
      nivelAgua: n,
      descricao: d,
      registradaEm: agora.subtract(Duration(hours: horasAtras)),
      exemplo: true,
    );
    return [
      o('1', 5, 'baixada', CategoriaOcorrencia.alagamento, NivelAgua.joelho, 'Rua da feira tomada pela água depois do temporal.'),
      o('2', 9, 'baixada', CategoriaOcorrencia.corrego, NivelAgua.acimaJoelho, 'Córrego saiu do leito perto da ponte de pedestres.'),
      o('3', 20, 'centro', CategoriaOcorrencia.bueiro, NivelAgua.tornozelo, 'Boca de lobo entupida em frente à escola.'),
      o('4', 30, 'encosta', CategoriaOcorrencia.deslizamento, NivelAgua.nenhum, 'Terra cedendo no barranco da escadaria.'),
      o('5', 52, 'centro', CategoriaOcorrencia.arvore, NivelAgua.nenhum, 'Galho grande caído sobre a calçada.'),
      o('6', 75, 'baixada', CategoriaOcorrencia.bueiro, NivelAgua.tornozelo, 'Bueiro transbordando no ponto de ônibus.'),
      o('7', 110, 'encosta', CategoriaOcorrencia.alagamento, NivelAgua.tornozelo, 'Enxurrada descendo a rua principal.'),
      o('8', 140, 'centro', CategoriaOcorrencia.outro, NivelAgua.nenhum, 'Lixo acumulado na margem do córrego.'),
    ];
  }

  List<DateTime> _instantes(PrevisaoChuva? chuva, DateTime agora) {
    if (chuva != null && chuva.precipitacao.isNotEmpty) {
      return chuva.precipitacao.map((p) => p.instante).toList();
    }
    final horaAtual = DateTime(agora.year, agora.month, agora.day, agora.hour);
    return [for (var h = -24; h <= 24; h++) horaAtual.add(Duration(hours: h))];
  }

  int _sementeDoDia(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
}
