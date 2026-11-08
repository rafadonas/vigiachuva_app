/// Formatação no padrão brasileiro, sem depender de dados de localidade.
library;

String doisDigitos(int n) => n.toString().padLeft(2, '0');

String dataHora(DateTime d) => '${doisDigitos(d.day)}/${doisDigitos(d.month)} ${doisDigitos(d.hour)}h${doisDigitos(d.minute)}';

String hora(DateTime d) => '${doisDigitos(d.hour)}h';

String dataCurta(DateTime d) => '${doisDigitos(d.day)}/${doisDigitos(d.month)}';

String decimal(double v, {int casas = 1}) => v.toStringAsFixed(casas).replaceAll('.', ',');

String milhar(int v) {
  final texto = v.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
    buffer.write(texto[i]);
  }
  return '${v < 0 ? '-' : ''}$buffer';
}

String percentual(double fracao) => '${(fracao * 100).round()}%';

/// "há 5 min", "há 3 h", "há 2 dias"
String tempoDecorrido(DateTime desde, DateTime agora) {
  final diferenca = agora.difference(desde);
  if (diferenca.inMinutes < 1) return 'agora mesmo';
  if (diferenca.inMinutes < 60) return 'há ${diferenca.inMinutes} min';
  if (diferenca.inHours < 24) return 'há ${diferenca.inHours} h';
  return 'há ${diferenca.inDays} dia${diferenca.inDays > 1 ? 's' : ''}';
}
