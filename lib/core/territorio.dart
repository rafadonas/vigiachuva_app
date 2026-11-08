/// Território-piloto do VigiaChuva.
///
/// As coordenadas apontam para o extremo leste de São Paulo e são usadas para
/// buscar a previsão REAL de chuva na Open-Meteo. As regiões, populações e
/// equipamentos abaixo são FICTÍCIOS (dados sintéticos para fins acadêmicos).
library;

class Regiao {
  const Regiao({required this.id, required this.nome, required this.populacaoEstimada, required this.descricao});

  final String id;
  final String nome;
  final int populacaoEstimada;
  final String descricao;
}

class Territorio {
  Territorio._();

  static const String nome = 'Várzea Leste';
  static const String municipio = 'São Paulo/SP';
  static const double latitude = -23.50;
  static const double longitude = -46.40;

  static const List<Regiao> regioes = [
    Regiao(
      id: 'baixada',
      nome: 'Baixada do Córrego',
      populacaoEstimada: 18000,
      descricao: 'Área baixa às margens do córrego, sujeita a transbordamento.',
    ),
    Regiao(
      id: 'encosta',
      nome: 'Encosta Norte',
      populacaoEstimada: 9500,
      descricao: 'Morro com ocupação em encosta, sujeito a deslizamentos com solo encharcado.',
    ),
    Regiao(
      id: 'centro',
      nome: 'Centro do Bairro',
      populacaoEstimada: 20500,
      descricao: 'Comércio e escolas; alagamentos pontuais em ruas com bueiros entupidos.',
    ),
  ];

  static int get populacaoTotal => regioes.fold(0, (soma, r) => soma + r.populacaoEstimada);

  static Regiao regiao(String id) => regioes.firstWhere((r) => r.id == id, orElse: () => regioes.first);
}
