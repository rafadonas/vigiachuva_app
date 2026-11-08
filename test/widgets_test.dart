import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigiachuva/data/repositorio_territorio.dart';
import 'package:vigiachuva/data/servicos/armazenamento_local.dart';
import 'package:vigiachuva/data/servicos/dados_sinteticos.dart';
import 'package:vigiachuva/data/servicos/open_meteo_servico.dart';
import 'package:vigiachuva/estado/ocorrencias_controller.dart';
import 'package:vigiachuva/estado/preferencias_controller.dart';
import 'package:vigiachuva/estado/territorio_controller.dart';
import 'package:vigiachuva/main.dart';
import 'package:vigiachuva/app/rotas.dart';

/// Monta o app inteiro com a API simulada (sem internet) e consentimento já dado.
Future<VigiaChuvaApp> montarApp({bool comInternet = true, bool? consentimento = true}) async {
  SharedPreferences.setMockInitialValues({'consentimento': ?consentimento});
  final local = await ArmazenamentoLocal.abrir();
  final agora = DateTime.now();
  final hora = DateTime(agora.year, agora.month, agora.day, agora.hour);
  String t(int h) => hora.add(Duration(hours: h)).toIso8601String().substring(0, 16);
  final json = {
    'latitude': -23.5,
    'longitude': -46.4,
    'hourly': {
      'time': [for (var h = -24; h <= 24; h++) t(h)],
      'precipitation': [for (var h = -24; h <= 24; h++) h == 2 ? 42.0 : 1.0],
      'precipitation_probability': [for (var h = -24; h <= 24; h++) 80],
    },
  };
  final cliente = MockClient((_) async => comInternet ? http.Response(jsonEncode(json), 200) : throw http.ClientException('sem rede'));
  final sinteticos = DadosSinteticos(semente: 7);
  final preferencias = PreferenciasController(local);
  final ocorrencias = OcorrenciasController(local, sinteticos)..carregar();
  final territorio = TerritorioController(
    repositorio: RepositorioTerritorio(OpenMeteoServico(cliente: cliente), local),
    sinteticos: sinteticos,
    preferencias: preferencias,
    ocorrencias: ocorrencias,
  );
  await territorio.carregar();
  return VigiaChuvaApp(preferencias: preferencias, ocorrencias: ocorrencias, territorio: territorio);
}

void main() {
  testWidgets('início mostra alerta, painéis e benefício social; navega até o detalhe do alerta', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(await montarApp());
    await tester.pumpAndSettle();

    expect(find.text('Situação agora'), findsOneWidget);
    expect(find.text('Benefício social'), findsOneWidget);

    await tester.tap(find.text('Alertas').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Chuva forte prevista nas próximas horas'), 200);
    await tester.tap(find.text('Chuva forte prevista nas próximas horas'));
    await tester.pumpAndSettle();
    expect(find.text('Por que este alerta? (evidências)'), findsOneWidget);
    expect(find.textContaining('decisão humana'), findsWidgets);
  });

  testWidgets('sem internet e sem cache: mostra estado de erro com botão de tentar de novo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(await montarApp(comInternet: false));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('primeira abertura pede consentimento', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(await montarApp(consentimento: null));
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo ao VigiaChuva'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Continuar sem enviar relatos'), 200);
    await tester.tap(find.text('Continuar sem enviar relatos'));
    await tester.pumpAndSettle();
    expect(find.text('Situação agora'), findsOneWidget); // entrou no app sem consentir com relatos
    expect(find.byType(BackButton), findsNothing); // não dá para "voltar" ao consentimento
  });

  testWidgets('formulário de relato mostra erros e salva um relato válido', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    final app = await montarApp();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relatos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo relato'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar relato'));
    await tester.pumpAndSettle();
    expect(find.text('Selecione a região.'), findsOneWidget);
    expect(find.text('Descreva o que está acontecendo.'), findsOneWidget);

    await tester.tap(find.text('Região *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Centro do Bairro').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('O que está acontecendo? *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alagamento de rua').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nível da água *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Até o joelho (~50 cm)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Rua da escola alagada, carros não passam.');
    await tester.tap(find.text('Confirmo que o relato não contém dados pessoais.'));
    await tester.tap(find.text('Enviar relato'));
    await tester.pumpAndSettle();

    expect(app.ocorrencias.doUsuario, hasLength(1));
    expect(app.ocorrencias.doUsuario.single.regiaoId, 'centro');
  });

  testWidgets('layout não quebra com fonte ampliada (200%) em tela pequena', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final app = await montarApp();
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Alertas').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // detalhe do alerta pela rota nomeada, com o id como parâmetro
    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(Rotas.alerta, arguments: app.territorio.alertas.first.id);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Nível de confiança'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.text('Nível de confiança'), findsOneWidget); // detalhe do alerta
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Ver o indicador que gerou o alerta'), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Ver o indicador que gerou o alerta'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
