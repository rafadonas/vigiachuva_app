/// Limites de ATENÇÃO, ALERTA e CRÍTICO de uma grandeza (ex.: chuva em mm/h).
class Limiares {
  const Limiares(this.atencao, this.alerta, this.critico);

  final double atencao;
  final double alerta;
  final double critico;

  bool get valido => atencao >= 0 && atencao < alerta && alerta < critico;

  Map<String, dynamic> toJson() => {'atencao': atencao, 'alerta': alerta, 'critico': critico};

  factory Limiares.fromJson(Map<String, dynamic> json) =>
      Limiares((json['atencao'] as num).toDouble(), (json['alerta'] as num).toDouble(), (json['critico'] as num).toDouble());
}

/// Conjunto de limiares configuráveis pelo gestor (tela Ajustes > Limiares).
/// Valores padrão são referências adotadas pela equipe para o protótipo, não calibrações oficiais.
class ConfiguracaoLimiares {
  const ConfiguracaoLimiares({
    this.chuvaMmH = const Limiares(10, 30, 50),
    this.nivelCorregoM = const Limiares(2.5, 3.2, 3.8),
    this.umidadeSoloPct = const Limiares(80, 90, 95),
  });

  final Limiares chuvaMmH;
  final Limiares nivelCorregoM;
  final Limiares umidadeSoloPct;

  Map<String, dynamic> toJson() => {'chuva': chuvaMmH.toJson(), 'nivel': nivelCorregoM.toJson(), 'umidade': umidadeSoloPct.toJson()};

  factory ConfiguracaoLimiares.fromJson(Map<String, dynamic> json) => ConfiguracaoLimiares(
    chuvaMmH: Limiares.fromJson(json['chuva'] as Map<String, dynamic>),
    nivelCorregoM: Limiares.fromJson(json['nivel'] as Map<String, dynamic>),
    umidadeSoloPct: Limiares.fromJson(json['umidade'] as Map<String, dynamic>),
  );
}
