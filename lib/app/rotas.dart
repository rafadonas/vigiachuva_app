import 'package:flutter/material.dart';

import '../ui/telas/tela_consentimento.dart';
import '../ui/telas/tela_detalhe_alerta.dart';
import '../ui/telas/tela_detalhe_indicador.dart';
import '../ui/telas/tela_limiares.dart';
import '../ui/telas/tela_nova_ocorrencia.dart';
import '../ui/telas/tela_painel_chuva.dart';
import '../ui/telas/tela_painel_drenagem.dart';
import '../ui/telas/tela_painel_ocorrencias.dart';
import '../ui/telas/tela_principal.dart';
import '../ui/telas/tela_sobre_dados.dart';

/// Rotas nomeadas do app. Telas de detalhe recebem o id por parâmetro (arguments).
class Rotas {
  Rotas._();

  static const consentimento = '/consentimento';
  static const principal = '/';
  static const painelChuva = '/painel/chuva';
  static const painelDrenagem = '/painel/drenagem';
  static const painelOcorrencias = '/painel/ocorrencias';
  static const indicador = '/indicador'; // arguments: String (id do indicador)
  static const alerta = '/alerta'; // arguments: String (id do alerta)
  static const novaOcorrencia = '/ocorrencia/nova';
  static const limiares = '/ajustes/limiares';
  static const sobreDados = '/sobre';

  static String painel(String id) => switch (id) {
    'chuva' => painelChuva,
    'drenagem' => painelDrenagem,
    _ => painelOcorrencias,
  };

  static Route<dynamic> gerar(RouteSettings config) {
    // Na web, as telas de detalhe também aceitam o id pela URL (ex.: #/alerta?id=chuva-todas).
    final uri = Uri.parse(config.name ?? principal);
    final parametro = config.arguments as String? ?? uri.queryParameters['id'];
    final Widget tela = switch (uri.path) {
      consentimento => const TelaConsentimento(),
      principal => const TelaPrincipal(),
      painelChuva => const TelaPainelChuva(),
      painelDrenagem => const TelaPainelDrenagem(),
      painelOcorrencias => const TelaPainelOcorrencias(),
      indicador => TelaDetalheIndicador(indicadorId: parametro ?? ''),
      alerta => TelaDetalheAlerta(alertaId: parametro ?? ''),
      novaOcorrencia => const TelaNovaOcorrencia(),
      limiares => const TelaLimiares(),
      sobreDados => const TelaSobreDados(),
      _ => const TelaPrincipal(),
    };
    return MaterialPageRoute(builder: (_) => tela, settings: config);
  }
}
