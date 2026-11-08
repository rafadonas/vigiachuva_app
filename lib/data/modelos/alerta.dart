/// Alerta preditivo com tudo que o gestor precisa para decidir:
/// evidências, nível de confiança, limitações e ação sugerida.
enum NivelAlerta {
  atencao('ATENÇÃO'),
  alerta('ALERTA'),
  critico('CRÍTICO');

  const NivelAlerta(this.rotulo);
  final String rotulo;
}

enum FonteAlerta {
  chuva('Chuva prevista'),
  corrego('Nível do córrego'),
  solo('Umidade do solo'),
  ocorrencias('Relatos da comunidade');

  const FonteAlerta(this.rotulo);
  final String rotulo;
}

class Alerta {
  const Alerta({
    required this.id,
    required this.fonte,
    required this.nivel,
    required this.regiaoId,
    required this.titulo,
    required this.resumo,
    required this.evidencias,
    required this.confianca,
    required this.explicacaoConfianca,
    required this.limitacoes,
    required this.acaoSugerida,
    required this.indicadorId,
    required this.geradoEm,
    this.previstoPara,
  });

  final String id;
  final FonteAlerta fonte;
  final NivelAlerta nivel;
  final String regiaoId;
  final String titulo;
  final String resumo;

  /// Justificativa: os dados que levaram ao alerta.
  final List<String> evidencias;

  /// Confiança de 0 a 1, com explicação de como foi calculada.
  final double confianca;
  final String explicacaoConfianca;

  /// Quando NÃO confiar neste alerta.
  final List<String> limitacoes;
  final String acaoSugerida;
  final String indicadorId;
  final DateTime geradoEm;
  final DateTime? previstoPara;

  String get rotuloConfianca {
    if (confianca >= 0.7) return 'Alta';
    if (confianca >= 0.4) return 'Média';
    return 'Baixa';
  }
}
