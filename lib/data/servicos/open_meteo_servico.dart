import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/territorio.dart';
import '../modelos/previsao_chuva.dart';

/// Falha ao obter dados de uma fonte externa, com mensagem pronta para o usuário.
class FalhaFonteExterna implements Exception {
  const FalhaFonteExterna(this.mensagem);
  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Cliente da API pública Open-Meteo (uso não comercial, sem chave; dados CC BY 4.0).
class OpenMeteoServico {
  OpenMeteoServico({http.Client? cliente, this.tempoLimite = const Duration(seconds: 10)}) : _cliente = cliente ?? http.Client();

  final http.Client _cliente;
  final Duration tempoLimite;

  static Uri montarUri() => Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': Territorio.latitude.toString(),
    'longitude': Territorio.longitude.toString(),
    'hourly': 'precipitation,precipitation_probability',
    'past_days': '1',
    'forecast_days': '2',
    'timezone': 'America/Sao_Paulo',
  });

  Future<PrevisaoChuva> buscarPrevisao() async {
    try {
      final resposta = await _cliente.get(montarUri()).timeout(tempoLimite);
      if (resposta.statusCode != 200) {
        throw FalhaFonteExterna('O serviço de previsão respondeu com erro ${resposta.statusCode}.');
      }
      final json = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
      return PrevisaoChuva.daOpenMeteo(json, DateTime.now());
    } on TimeoutException {
      throw const FalhaFonteExterna('O serviço de previsão demorou demais para responder.');
    } on FormatException catch (e) {
      throw FalhaFonteExterna('A previsão veio em formato inesperado (${e.message}).');
    } on TypeError {
      throw const FalhaFonteExterna('A previsão veio em formato inesperado (campos com tipo diferente do esperado).');
    } on http.ClientException {
      throw const FalhaFonteExterna('Sem conexão com a internet ou serviço de previsão indisponível.');
    }
  }
}
