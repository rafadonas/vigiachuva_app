import 'dart:math';

import '../core/territorio.dart';
import '../data/modelos/alerta.dart';
import '../data/modelos/ocorrencia.dart';
import 'motor_alertas.dart';

/// Descrição de cada indicador exibido nos painéis (usada na tela de detalhe).
class DefinicaoIndicador {
  const DefinicaoIndicador({
    required this.id,
    required this.titulo,
    required this.unidade,
    required this.painel,
    required this.definicao,
    required this.fonte,
    required this.calculo,
    required this.limitacoes,
  });

  final String id;
  final String titulo;
  final String unidade;
  final String painel;
  final String definicao;
  final String fonte;
  final String calculo;
  final List<String> limitacoes;
}

const catalogoIndicadores = <String, DefinicaoIndicador>{
  'chuva_24h': DefinicaoIndicador(
    id: 'chuva_24h',
    titulo: 'Chuva nas últimas 24 h',
    unidade: 'mm',
    painel: 'chuva',
    definicao: 'Quanto choveu no território nas últimas 24 horas.',
    fonte: 'Open-Meteo (dado real, CC BY 4.0), valores horários do modelo meteorológico.',
    calculo: 'Soma das precipitações horárias das últimas 24 h.',
    limitacoes: ['É uma estimativa do modelo para a área, não a leitura de um pluviômetro local.'],
  ),
  'chuva_pico_6h': DefinicaoIndicador(
    id: 'chuva_pico_6h',
    titulo: 'Pico de chuva previsto (6 h)',
    unidade: 'mm/h',
    painel: 'chuva',
    definicao: 'Maior intensidade de chuva prevista para uma hora nas próximas 6 horas.',
    fonte: 'Open-Meteo (dado real, CC BY 4.0).',
    calculo: 'Máximo das precipitações horárias previstas entre agora e daqui a 6 h; é o valor comparado com os limiares de chuva.',
    limitacoes: ['A incerteza cresce com a antecedência.', 'Pancadas muito localizadas podem não aparecer no modelo.'],
  ),
  'nivel_corrego': DefinicaoIndicador(
    id: 'nivel_corrego',
    titulo: 'Nível do córrego',
    unidade: 'm',
    painel: 'drenagem',
    definicao: 'Altura da água no ponto de medição da Baixada do Córrego.',
    fonte: 'SIMULADO: derivado da chuva real por um modelo didático (nível-base de 1,6 m + 4,5 cm por mm de chuva nas últimas 6 h).',
    calculo: 'Projeção = maior valor entre a tendência das últimas 6 h e a projeção do modelo para as próximas 6 h.',
    limitacoes: ['Sem calibração com medições reais.', 'Um ponto não representa o córrego inteiro.'],
  ),
  'umidade_solo': DefinicaoIndicador(
    id: 'umidade_solo',
    titulo: 'Umidade do solo na encosta',
    unidade: '%',
    painel: 'drenagem',
    definicao: 'Quanto o solo da Encosta Norte está encharcado.',
    fonte: 'SIMULADO: o solo encharca com a chuva real (0,6 ponto percentual por mm) e seca devagar (modelo didático).',
    calculo: 'Valor atual e máximo previsto para as próximas 6 h.',
    limitacoes: ['Risco de deslizamento depende também do tipo de solo e da inclinação.'],
  ),
  'ocorrencias_7d': DefinicaoIndicador(
    id: 'ocorrencias_7d',
    titulo: 'Relatos da comunidade (7 dias)',
    unidade: 'relatos',
    painel: 'ocorrencias',
    definicao: 'Relatos de alagamento, bueiro entupido, córrego transbordando e outros, feitos pelos moradores.',
    fonte: 'Relatos feitos no app (anônimos) e relatos de exemplo fictícios que acompanham o protótipo.',
    calculo: 'Contagem por dia, por categoria e por região nos últimos 7 dias.',
    limitacoes: ['Relatos não são verificados.', 'Subnotificação em áreas com menos acesso ao app.'],
  ),
};

/// Indicador de benefício social: quantas pessoas vivem em regiões com alerta ativo,
/// com quanta antecedência a chuva forte foi avisada e quantos relatos a comunidade fez.
class BeneficioSocial {
  const BeneficioSocial({required this.pessoasEmAreasAlertadas, required this.antecedenciaHoras, required this.relatos7Dias});

  final int pessoasEmAreasAlertadas;
  final int? antecedenciaHoras;
  final int relatos7Dias;

  factory BeneficioSocial.calcular(List<Alerta> alertas, List<Ocorrencia> ocorrencias, DateTime agora) {
    final regioes = <String>{};
    for (final a in alertas) {
      if (a.regiaoId == MotorAlertas.regiaoTodas) {
        regioes.addAll(Territorio.regioes.map((r) => r.id));
      } else {
        regioes.add(a.regiaoId);
      }
    }
    final pessoas = regioes.fold(0, (soma, id) => soma + Territorio.regiao(id).populacaoEstimada);
    final alertaChuva = alertas.where((a) => a.fonte == FonteAlerta.chuva && a.previstoPara != null).toList();
    // Mesmo arredondamento do motor de alertas (para cima, nunca negativo).
    final antecedencia = alertaChuva.isEmpty ? null : max(0, (alertaChuva.first.previstoPara!.difference(agora).inMinutes / 60).ceil());
    final relatos = ocorrencias.where((o) => o.registradaEm.isAfter(agora.subtract(const Duration(days: 7)))).length;
    return BeneficioSocial(pessoasEmAreasAlertadas: pessoas, antecedenciaHoras: antecedencia, relatos7Dias: relatos);
  }
}

String nomeRegiao(String regiaoId) => regiaoId == MotorAlertas.regiaoTodas ? 'Todo o território' : Territorio.regiao(regiaoId).nome;
