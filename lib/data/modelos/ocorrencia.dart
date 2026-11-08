/// Relato de um cidadão. Não guarda nome, telefone, e-mail nem endereço exato:
/// só a região, o tipo do problema e uma descrição (dados anonimizados).
enum CategoriaOcorrencia {
  alagamento('Alagamento de rua'),
  bueiro('Bueiro ou boca de lobo entupido'),
  corrego('Córrego transbordando'),
  deslizamento('Deslizamento ou risco em encosta'),
  arvore('Árvore ou fiação caída'),
  outro('Outro');

  const CategoriaOcorrencia(this.rotulo);
  final String rotulo;
}

enum NivelAgua {
  nenhum('Sem água acumulada'),
  tornozelo('Até o tornozelo (~10 cm)'),
  joelho('Até o joelho (~50 cm)'),
  acimaJoelho('Acima do joelho');

  const NivelAgua(this.rotulo);
  final String rotulo;
}

class Ocorrencia {
  const Ocorrencia({
    required this.id,
    required this.regiaoId,
    required this.categoria,
    required this.nivelAgua,
    required this.descricao,
    required this.registradaEm,
    this.exemplo = false,
  });

  final String id;
  final String regiaoId;
  final CategoriaOcorrencia categoria;
  final NivelAgua nivelAgua;
  final String descricao;
  final DateTime registradaEm;

  /// Ocorrências de exemplo (sintéticas) vêm com o app para os painéis não ficarem vazios.
  final bool exemplo;

  /// Grave: risco à vida ou água no joelho ou acima.
  bool get grave =>
      categoria == CategoriaOcorrencia.corrego ||
      categoria == CategoriaOcorrencia.deslizamento ||
      nivelAgua.index >= NivelAgua.joelho.index;

  Map<String, dynamic> toJson() => {
    'id': id,
    'regiaoId': regiaoId,
    'categoria': categoria.name,
    'nivelAgua': nivelAgua.name,
    'descricao': descricao,
    'registradaEm': registradaEm.toIso8601String(),
    'exemplo': exemplo,
  };

  factory Ocorrencia.fromJson(Map<String, dynamic> json) => Ocorrencia(
    id: json['id'] as String,
    regiaoId: json['regiaoId'] as String,
    categoria: CategoriaOcorrencia.values.byName(json['categoria'] as String),
    nivelAgua: NivelAgua.values.byName(json['nivelAgua'] as String),
    descricao: json['descricao'] as String,
    registradaEm: DateTime.parse(json['registradaEm'] as String),
    exemplo: json['exemplo'] as bool? ?? false,
  );
}
