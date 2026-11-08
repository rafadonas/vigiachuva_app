/// Validações dos formulários (funções puras, cobertas por testes).
library;

// Telefone: com DDD, celular começando em 9, ou 8+ dígitos seguidos. Não pega anos como "2024-2025".
final _telefone = RegExp(r'\(?\b\d{2}\)?\s?9?\d{4}[-\s]?\d{4}\b|\b9\d{4}[-\s]?\d{4}\b|\b\d{8,11}\b');
final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');

String? validarDescricao(String? texto) {
  final valor = texto?.trim() ?? '';
  if (valor.isEmpty) return 'Descreva o que está acontecendo.';
  if (valor.length < 10) return 'Use pelo menos 10 caracteres (faltam ${10 - valor.length}).';
  if (valor.length > 300) return 'Use no máximo 300 caracteres.';
  if (_email.hasMatch(valor) || _telefone.hasMatch(valor)) {
    return 'Não inclua telefone ou e-mail: os relatos são anônimos.';
  }
  return null;
}

String? validarSelecao(Object? valor, String campo) => valor == null ? 'Selecione $campo.' : null;

/// Converte "12,5" ou "12.5" em número. Devolve null se inválido.
double? lerDecimal(String? texto) {
  if (texto == null) return null;
  return double.tryParse(texto.trim().replaceAll(',', '.'));
}

String? validarLimiar(String? texto, {required double maximo}) {
  final valor = lerDecimal(texto);
  if (valor == null) return 'Digite um número (ex.: 12,5).';
  if (valor < 0) return 'O valor não pode ser negativo.';
  if (valor > maximo) return 'O valor máximo é ${maximo.toStringAsFixed(0)}.';
  return null;
}

/// Confere ATENÇÃO < ALERTA < CRÍTICO. Devolve a mensagem de erro ou null.
String? validarOrdem(double? atencao, double? alerta, double? critico) {
  if (atencao == null || alerta == null || critico == null) return null;
  if (!(atencao < alerta && alerta < critico)) {
    return 'Os limites precisam crescer: ATENÇÃO < ALERTA < CRÍTICO.';
  }
  return null;
}
