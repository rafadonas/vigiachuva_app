import 'package:flutter_test/flutter_test.dart';
import 'package:vigiachuva/data/modelos/alerta.dart';
import 'package:vigiachuva/data/modelos/limiares.dart';
import 'package:vigiachuva/data/modelos/ocorrencia.dart';
import 'package:vigiachuva/data/modelos/ponto_serie.dart';
import 'package:vigiachuva/dominio/indicadores.dart';
import 'package:vigiachuva/dominio/motor_alertas.dart';

import 'apoio.dart';

void main() {
  const motor = MotorAlertas();
  const limiares = ConfiguracaoLimiares();

  List<Alerta> gerar({
    PrevisaoChuvaParams chuva = const PrevisaoChuvaParams(),
    List<PontoSerie> nivel = const [],
    List<Ocorrencia> ocorrencias = const [],
    bool doCache = false,
  }) => motor.gerar(
    chuva: chuva.semDados
        ? null
        : previsaoTeste(chuvaFutura: chuva.futura, probabilidade: chuva.probabilidade, coletadaEm: chuva.coletadaEm),
    chuvaDoCache: doCache,
    nivelCorrego: nivel,
    umidadeSolo: const [],
    ocorrencias: ocorrencias,
    limiares: limiares,
    agora: agoraTeste,
  );

  group('classificação por limiares', () {
    test('valores abaixo, no limite e acima de cada nível', () {
      const l = Limiares(10, 30, 50);
      expect(MotorAlertas.classificar(9.9, l), isNull);
      expect(MotorAlertas.classificar(10, l), NivelAlerta.atencao);
      expect(MotorAlertas.classificar(30, l), NivelAlerta.alerta);
      expect(MotorAlertas.classificar(80, l), NivelAlerta.critico);
    });
  });

  group('alerta de chuva', () {
    test('pico de 35 mm/h em 2 h gera ALERTA com justificativa, confiança e limitações', () {
      final alertas = gerar(chuva: const PrevisaoChuvaParams(futura: [5, 35, 12], probabilidade: 90));
      final chuva = alertas.firstWhere((a) => a.fonte == FonteAlerta.chuva);
      expect(chuva.nivel, NivelAlerta.alerta);
      expect(chuva.evidencias.join(' '), contains('35,0 mm/h'));
      expect(chuva.confianca, closeTo(0.9, 0.001)); // 90% × antecedência 1,0 × atualização 1,0
      expect(chuva.limitacoes, isNotEmpty);
      expect(chuva.acaoSugerida, isNotEmpty);
    });

    test('pico a mais de 3 h e dado antigo do cache reduzem a confiança', () {
      final alertas = gerar(
        chuva: PrevisaoChuvaParams(
          futura: const [0, 0, 0, 0, 60],
          probabilidade: 80,
          coletadaEm: agoraTeste.subtract(const Duration(hours: 5)),
        ),
        doCache: true,
      );
      final chuva = alertas.firstWhere((a) => a.fonte == FonteAlerta.chuva);
      expect(chuva.nivel, NivelAlerta.critico);
      expect(chuva.confianca, closeTo(0.8 * 0.85 * 0.7, 0.001));
      expect(chuva.limitacoes.last, contains('Sem conexão'));
    });

    test('chuva fraca não gera alerta e sem previsão não há alerta de chuva', () {
      expect(gerar(chuva: const PrevisaoChuvaParams(futura: [2, 3, 1])).where((a) => a.fonte == FonteAlerta.chuva), isEmpty);
      expect(gerar(chuva: const PrevisaoChuvaParams(semDados: true)).where((a) => a.fonte == FonteAlerta.chuva), isEmpty);
    });
  });

  group('alerta do córrego', () {
    List<PontoSerie> serie(List<double> valores) => [
      for (var i = 0; i < valores.length; i++) PontoSerie(agoraTeste.subtract(Duration(hours: valores.length - 1 - i)), valores[i]),
    ];

    test('o sistema se cala com menos de 6 leituras', () {
      final alertas = gerar(nivel: serie([3.9, 3.9, 3.9, 3.9, 3.9]));
      expect(alertas.where((a) => a.fonte == FonteAlerta.corrego), isEmpty);
    });

    test('tendência de subida projeta acima do limite CRÍTICO', () {
      final alertas = gerar(nivel: serie([2.0, 2.1, 2.2, 3.0, 3.1, 3.2]));
      final corrego = alertas.firstWhere((a) => a.fonte == FonteAlerta.corrego);
      expect(corrego.nivel, NivelAlerta.critico); // 3,1 + (3,1 - 2,1) = 4,1 m ≥ 3,8 m
      expect(corrego.confianca, lessThanOrEqualTo(0.6));
    });
  });

  group('alerta por relatos', () {
    Ocorrencia grave(String id, int horasAtras) => Ocorrencia(
      id: id,
      regiaoId: 'baixada',
      categoria: CategoriaOcorrencia.alagamento,
      nivelAgua: NivelAgua.joelho,
      descricao: 'Rua alagada até o joelho.',
      registradaEm: agoraTeste.subtract(Duration(hours: horasAtras)),
    );

    test('2 relatos graves em 24 h geram ATENÇÃO; 4 geram ALERTA; relatos antigos não contam', () {
      expect(gerar(ocorrencias: [grave('a', 1), grave('b', 30)]).where((a) => a.fonte == FonteAlerta.ocorrencias), isEmpty);
      expect(gerar(ocorrencias: [grave('a', 1), grave('b', 2)]).single.nivel, NivelAlerta.atencao);
      expect(gerar(ocorrencias: [for (var i = 0; i < 4; i++) grave('$i', i + 1)]).single.nivel, NivelAlerta.alerta);
    });
  });

  test('alertas vêm ordenados do mais grave para o menos grave', () {
    final alertas = gerar(
      chuva: const PrevisaoChuvaParams(futura: [55]),
      ocorrencias: [
        for (var i = 0; i < 2; i++)
          Ocorrencia(
            id: '$i',
            regiaoId: 'centro',
            categoria: CategoriaOcorrencia.corrego,
            nivelAgua: NivelAgua.joelho,
            descricao: 'Córrego transbordou.',
            registradaEm: agoraTeste,
          ),
      ],
    );
    expect(alertas.first.nivel, NivelAlerta.critico);
    expect(alertas.last.nivel, NivelAlerta.atencao);
  });

  test('benefício social soma a população das regiões com alerta', () {
    final alertas = gerar(chuva: const PrevisaoChuvaParams(futura: [0, 40]));
    final beneficio = BeneficioSocial.calcular(alertas, const [], agoraTeste);
    expect(beneficio.pessoasEmAreasAlertadas, 48000); // alerta de chuva cobre todo o território
    expect(beneficio.antecedenciaHoras, 2);
  });
}

class PrevisaoChuvaParams {
  const PrevisaoChuvaParams({this.futura = const [], this.probabilidade = 80, this.coletadaEm, this.semDados = false});
  final List<double> futura;
  final double probabilidade;
  final DateTime? coletadaEm;
  final bool semDados;
}
