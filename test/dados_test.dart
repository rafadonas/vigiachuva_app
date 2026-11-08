import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigiachuva/data/modelos/previsao_chuva.dart';
import 'package:vigiachuva/data/repositorio_territorio.dart';
import 'package:vigiachuva/data/servicos/armazenamento_local.dart';
import 'package:vigiachuva/data/servicos/dados_sinteticos.dart';
import 'package:vigiachuva/data/servicos/open_meteo_servico.dart';
import 'package:vigiachuva/dominio/validadores.dart';

import 'apoio.dart';

void main() {
  group('Open-Meteo', () {
    test('converte a resposta horária e ignora horas sem dado (null)', () {
      final p = PrevisaoChuva.daOpenMeteo(jsonOpenMeteo(), agoraTeste);
      expect(p.precipitacao.length, 3);
      expect(p.precipitacao[2].valor, 35.5);
      expect(p.probabilidadeEm(DateTime(2026, 11, 7, 16)), 85);
    });

    test('resposta sem bloco "hourly" é rejeitada', () {
      expect(() => PrevisaoChuva.daOpenMeteo({'latitude': 0, 'longitude': 0}, agoraTeste), throwsFormatException);
    });
  });

  group('repositório (online e offline)', () {
    late ArmazenamentoLocal local;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      local = await ArmazenamentoLocal.abrir();
    });

    test('online: busca na API e salva no cache', () async {
      final api = OpenMeteoServico(cliente: MockClient((_) async => http.Response(jsonEncode(jsonOpenMeteo()), 200)));
      final r = await RepositorioTerritorio(api, local).obterPrevisao();
      expect(r.doCache, isFalse);
      expect(r.previsao, isNotNull);
      expect(local.lerPrevisao(), isNotNull);
    });

    test('offline: usa a previsão salva e informa o erro', () async {
      await local.salvarPrevisao(previsaoTeste(chuvaFutura: [12]));
      final api = OpenMeteoServico(cliente: MockClient((_) async => throw http.ClientException('sem rede')));
      final r = await RepositorioTerritorio(api, local).obterPrevisao();
      expect(r.doCache, isTrue);
      expect(r.previsao, isNotNull);
      expect(r.erro, contains('Sem conexão'));
    });

    test('offline sem cache: devolve erro sem previsão', () async {
      final api = OpenMeteoServico(cliente: MockClient((_) async => http.Response('erro', 503)));
      final r = await RepositorioTerritorio(api, local).obterPrevisao();
      expect(r.previsao, isNull);
      expect(r.erro, contains('503'));
    });
  });

  group('dados sintéticos', () {
    test('córrego sobe com a chuva e fica na faixa física', () {
      final seca = DadosSinteticos(semente: 1).nivelCorrego(previsaoTeste(), agoraTeste);
      final chuvosa = DadosSinteticos(semente: 1).nivelCorrego(previsaoTeste(chuvaFutura: [30, 30, 30]), agoraTeste);
      expect(
        chuvosa.map((p) => p.valor).reduce((a, b) => a > b ? a : b),
        greaterThan(seca.map((p) => p.valor).reduce((a, b) => a > b ? a : b)),
      );
      expect(chuvosa.every((p) => p.valor >= 0.3 && p.valor <= 6), isTrue);
    });

    test('relatos de exemplo são marcados como exemplo', () {
      expect(DadosSinteticos().ocorrenciasExemplo(agoraTeste).every((o) => o.exemplo), isTrue);
    });
  });

  group('validadores', () {
    test('descrição: vazia, curta, com telefone e válida', () {
      expect(validarDescricao(''), isNotNull);
      expect(validarDescricao('curta'), contains('faltam'));
      expect(validarDescricao('Liguem para 11 98765-4321 urgente'), contains('anônimos'));
      expect(validarDescricao('fulano@email.com viu a rua alagar'), contains('anônimos'));
      expect(validarDescricao('Rua da feira alagada há 30 minutos.'), isNull);
      expect(validarDescricao('Pior alagamento desde o verão de 2024-2025.'), isNull);
      expect(validarDescricao('Chamem no 98765-4321, rua alagada'), contains('anônimos'));
      expect(validarDescricao('Contato 1132654321 sobre o bueiro'), contains('anônimos'));
    });

    test('limiares: número com vírgula, negativo, acima do máximo e ordem', () {
      expect(lerDecimal('12,5'), 12.5);
      expect(validarLimiar('abc', maximo: 200), isNotNull);
      expect(validarLimiar('-1', maximo: 200), contains('negativo'));
      expect(validarLimiar('250', maximo: 200), contains('máximo'));
      expect(validarOrdem(30, 10, 50), isNotNull);
      expect(validarOrdem(10, 30, 50), isNull);
    });
  });
}
