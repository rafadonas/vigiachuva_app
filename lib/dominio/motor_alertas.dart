import 'dart:math';

import '../core/formatacao.dart';
import '../core/territorio.dart';
import '../data/modelos/alerta.dart';
import '../data/modelos/limiares.dart';
import '../data/modelos/ocorrencia.dart';
import '../data/modelos/ponto_serie.dart';
import '../data/modelos/previsao_chuva.dart';

/// Gera alertas a partir de REGRAS sobre previsões e dados. Não decide nada sozinho:
/// cada alerta traz evidências, confiança, limitações e uma ação SUGERIDA.
class MotorAlertas {
  const MotorAlertas();

  static const String regiaoTodas = 'todas';

  static NivelAlerta? classificar(double valor, Limiares l) {
    if (valor >= l.critico) return NivelAlerta.critico;
    if (valor >= l.alerta) return NivelAlerta.alerta;
    if (valor >= l.atencao) return NivelAlerta.atencao;
    return null;
  }

  static double limiteDe(NivelAlerta nivel, Limiares l) => switch (nivel) {
    NivelAlerta.critico => l.critico,
    NivelAlerta.alerta => l.alerta,
    NivelAlerta.atencao => l.atencao,
  };

  static const Map<NivelAlerta, String> _acoes = {
    NivelAlerta.atencao: 'Acompanhar a evolução e verificar bueiros e bocas de lobo da região.',
    NivelAlerta.alerta: 'Avisar lideranças comunitárias e deixar equipes de apoio de prontidão.',
    NivelAlerta.critico: 'Avaliar com a Defesa Civil a retirada preventiva de moradores das áreas de risco.',
  };

  List<Alerta> gerar({
    required PrevisaoChuva? chuva,
    required bool chuvaDoCache,
    required List<PontoSerie> nivelCorrego,
    required List<PontoSerie> umidadeSolo,
    required List<Ocorrencia> ocorrencias,
    required ConfiguracaoLimiares limiares,
    required DateTime agora,
  }) {
    final alertas = <Alerta>[
      ...?_alertaChuva(chuva, chuvaDoCache, limiares.chuvaMmH, agora),
      ...?_alertaCorrego(nivelCorrego, limiares.nivelCorregoM, agora, chuva == null),
      ...?_alertaSolo(umidadeSolo, limiares.umidadeSoloPct, agora, chuva == null),
      ..._alertasOcorrencias(ocorrencias, agora),
    ];
    alertas.sort((a, b) {
      final porNivel = b.nivel.index.compareTo(a.nivel.index);
      return porNivel != 0 ? porNivel : b.confianca.compareTo(a.confianca);
    });
    return alertas;
  }

  // ---------------------------------------------------------------- chuva

  List<Alerta>? _alertaChuva(PrevisaoChuva? chuva, bool doCache, Limiares l, DateTime agora) {
    if (chuva == null) return null;
    final pico = chuva.picoProximas(agora, 6);
    if (pico == null) return null;
    final nivel = classificar(pico.valor, l);
    if (nivel == null) return null;

    final horasAtePico = max(0, pico.instante.difference(agora).inMinutes / 60).ceil();
    var probabilidade = chuva.probabilidadeEm(pico.instante) / 100;
    if (probabilidade == 0) probabilidade = chuva.probabilidadeMaximaProximas(agora, 6) / 100;
    final fatorHorizonte = horasAtePico <= 3 ? 1.0 : 0.85;
    final idadeDado = agora.difference(chuva.coletadaEm);
    final fatorAtualizacao = doCache && idadeDado.inHours >= 3 ? 0.7 : 1.0;
    final confianca = (probabilidade * fatorHorizonte * fatorAtualizacao).clamp(0.05, 0.95);

    return [
      Alerta(
        id: 'chuva-$regiaoTodas',
        fonte: FonteAlerta.chuva,
        nivel: nivel,
        regiaoId: regiaoTodas,
        titulo: 'Chuva forte prevista nas próximas horas',
        resumo: 'Pico de ${decimal(pico.valor)} mm/h previsto para ${hora(pico.instante)} (daqui a cerca de $horasAtePico h).',
        evidencias: [
          'Pico previsto: ${decimal(pico.valor)} mm/h às ${dataHora(pico.instante)}.',
          'Limite de ${nivel.rotulo} configurado: ${decimal(limiteDe(nivel, l))} mm/h.',
          'Chuva acumulada prevista nas próximas 24 h: ${decimal(chuva.acumuladoProximas24h(agora))} mm.',
          'Chuva nas últimas 24 h: ${decimal(chuva.acumuladoUltimas24h(agora))} mm.',
          'Chance de chuva no horário do pico, segundo o modelo: ${(probabilidade * 100).round()}%.',
        ],
        confianca: confianca,
        explicacaoConfianca:
            'Calculada como chance de chuva do modelo (${(probabilidade * 100).round()}%)'
            ' × fator de antecedência (${decimal(fatorHorizonte, casas: 2)}: picos a mais de 3 h são menos certos)'
            ' × fator de atualização (${decimal(fatorAtualizacao, casas: 2)}: dado salvo há mais de 3 h vale menos).',
        limitacoes: [
          'O modelo meteorológico tem resolução de quilômetros: pancadas muito localizadas podem não aparecer.',
          'Previsões de chuva intensa acertam menos que as de chuva fraca, sobretudo além de 3 horas.',
          'A chuva prevista não considera a drenagem local (bueiros entupidos, obras).',
          if (doCache) 'Sem conexão: este alerta usa a previsão salva em ${dataHora(chuva.coletadaEm)}.',
        ],
        acaoSugerida: _acoes[nivel]!,
        indicadorId: 'chuva_pico_6h',
        geradoEm: agora,
        previstoPara: pico.instante,
      ),
    ];
  }

  // ---------------------------------------------------------------- córrego

  List<Alerta>? _alertaCorrego(List<PontoSerie> serie, Limiares l, DateTime agora, bool semChuvaReal) {
    final passado = serie.ate(agora);
    if (passado.length < 6) return null; // o sistema se cala com pouco histórico
    final recente = passado.sublist(passado.length - 3).media;
    final anterior = passado.sublist(passado.length - 6, passado.length - 3).media;
    final projecaoTendencia = recente + (recente - anterior);
    final futuro = serie.depoisDe(agora).where((p) => !p.instante.isAfter(agora.add(const Duration(hours: 6)))).toList();
    final projecaoModelo = futuro.isEmpty ? recente : futuro.maximo;
    final previsto = max(projecaoTendencia, projecaoModelo);
    final nivel = classificar(previsto, l);
    if (nivel == null) return null;

    final divergencia = (projecaoTendencia - projecaoModelo).abs();
    final confianca = (0.6 - min(divergencia, 0.5) * 0.4 - (semChuvaReal ? 0.15 : 0)).clamp(0.15, 0.6);
    return [
      Alerta(
        id: 'corrego-baixada',
        fonte: FonteAlerta.corrego,
        nivel: nivel,
        regiaoId: 'baixada',
        titulo: 'Córrego pode subir acima do limite',
        resumo: 'Nível estimado de ${decimal(previsto, casas: 2)} m nas próximas 6 h (agora: ${decimal(passado.last.valor, casas: 2)} m).',
        evidencias: [
          'Nível atual: ${decimal(passado.last.valor, casas: 2)} m; média das últimas 3 h: ${decimal(recente, casas: 2)} m.',
          'Tendência: ${recente >= anterior ? 'subindo' : 'descendo'} ${decimal((recente - anterior).abs(), casas: 2)} m em relação às 3 h anteriores.',
          'Projeção pela tendência: ${decimal(projecaoTendencia, casas: 2)} m; projeção pelo modelo de chuva: ${decimal(projecaoModelo, casas: 2)} m.',
          'Limite de ${nivel.rotulo} configurado: ${decimal(limiteDe(nivel, l), casas: 2)} m.',
        ],
        confianca: confianca,
        explicacaoConfianca:
            'Começa em 60% (dado sintético de um único ponto) e cai quando as duas projeções divergem '
            '(diferença de ${decimal(divergencia, casas: 2)} m)${semChuvaReal ? ' e quando não há previsão real de chuva' : ''}.',
        limitacoes: [
          'Nível do córrego SIMULADO a partir da chuva por um modelo didático, sem calibração com medições reais.',
          'Um único ponto de medição não representa o córrego inteiro.',
          'Não considera galerias entupidas, maré de lixo ou obras na calha.',
        ],
        acaoSugerida: _acoes[nivel]!,
        indicadorId: 'nivel_corrego',
        geradoEm: agora,
      ),
    ];
  }

  // ---------------------------------------------------------------- solo

  List<Alerta>? _alertaSolo(List<PontoSerie> serie, Limiares l, DateTime agora, bool semChuvaReal) {
    final passado = serie.ate(agora);
    if (passado.length < 6) return null;
    final futuro = serie.depoisDe(agora).where((p) => !p.instante.isAfter(agora.add(const Duration(hours: 6)))).toList();
    final previsto = max(passado.last.valor, futuro.isEmpty ? 0.0 : futuro.maximo);
    final nivel = classificar(previsto, l);
    if (nivel == null) return null;
    return [
      Alerta(
        id: 'solo-encosta',
        fonte: FonteAlerta.solo,
        nivel: nivel,
        regiaoId: 'encosta',
        titulo: 'Solo encharcado na encosta',
        resumo: 'Umidade do solo pode chegar a ${decimal(previsto)}% nas próximas 6 h.',
        evidencias: [
          'Umidade atual: ${decimal(passado.last.valor)}%; prevista (máx. em 6 h): ${decimal(previsto)}%.',
          'Limite de ${nivel.rotulo} configurado: ${decimal(limiteDe(nivel, l))}%.',
          'Solo saturado perde resistência e aumenta o risco de deslizamento em encostas ocupadas.',
        ],
        confianca: semChuvaReal ? 0.3 : 0.45,
        explicacaoConfianca:
            'Fixada em ${semChuvaReal ? '30' : '45'}%: a umidade é simulada e a relação entre umidade e deslizamento depende do tipo de solo e da inclinação, que o protótipo não mede.',
        limitacoes: [
          'Umidade do solo SIMULADA a partir da chuva (modelo didático).',
          'Umidade alta não significa deslizamento certo: depende do solo, da inclinação e da ocupação.',
        ],
        acaoSugerida: _acoes[nivel]!,
        indicadorId: 'umidade_solo',
        geradoEm: agora,
      ),
    ];
  }

  // ---------------------------------------------------------------- relatos

  List<Alerta> _alertasOcorrencias(List<Ocorrencia> ocorrencias, DateTime agora) {
    final alertas = <Alerta>[];
    final limite = agora.subtract(const Duration(hours: 24));
    for (final regiao in Territorio.regioes) {
      final graves = ocorrencias.where((o) => o.regiaoId == regiao.id && o.grave && o.registradaEm.isAfter(limite)).toList();
      if (graves.length < 2) continue;
      final nivel = graves.length >= 4 ? NivelAlerta.alerta : NivelAlerta.atencao;
      final exemplos = graves.where((o) => o.exemplo).length;
      alertas.add(
        Alerta(
          id: 'relatos-${regiao.id}',
          fonte: FonteAlerta.ocorrencias,
          nivel: nivel,
          regiaoId: regiao.id,
          titulo: 'Vários relatos graves em ${regiao.nome}',
          resumo: '${graves.length} relatos graves nas últimas 24 h.',
          evidencias: [
            '${graves.length} relatos graves (água no joelho ou acima, córrego transbordando ou deslizamento) em 24 h.',
            'Regra: 2 ou mais relatos graves = ATENÇÃO; 4 ou mais = ALERTA.',
            ...graves.take(3).map((o) => '${dataHora(o.registradaEm)}: ${o.categoria.rotulo} (${o.nivelAgua.rotulo}).'),
            if (exemplos > 0) '$exemplos destes relatos são exemplos fictícios que acompanham o protótipo.',
          ],
          confianca: (0.3 + graves.length * 0.1).clamp(0.3, 0.8),
          explicacaoConfianca: 'Cresce com o número de relatos independentes: 30% + 10% por relato grave, até 80%.',
          limitacoes: [
            'Relatos não são verificados no local e podem se repetir sobre o mesmo ponto.',
            'Áreas com menos acesso ao app tendem a relatar menos (subnotificação).',
          ],
          acaoSugerida: _acoes[nivel]!,
          indicadorId: 'ocorrencias_7d',
          geradoEm: agora,
        ),
      );
    }
    return alertas;
  }
}
