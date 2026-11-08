import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/rotas.dart';
import 'app/tema.dart';
import 'data/repositorio_territorio.dart';
import 'data/servicos/armazenamento_local.dart';
import 'data/servicos/dados_sinteticos.dart';
import 'data/servicos/open_meteo_servico.dart';
import 'estado/ocorrencias_controller.dart';
import 'estado/preferencias_controller.dart';
import 'estado/territorio_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final local = await ArmazenamentoLocal.abrir();
  final sinteticos = DadosSinteticos();
  final preferencias = PreferenciasController(local);
  final ocorrencias = OcorrenciasController(local, sinteticos)..carregar();
  final territorio = TerritorioController(
    repositorio: RepositorioTerritorio(OpenMeteoServico(), local),
    sinteticos: sinteticos,
    preferencias: preferencias,
    ocorrencias: ocorrencias,
  );
  runApp(VigiaChuvaApp(preferencias: preferencias, ocorrencias: ocorrencias, territorio: territorio));
  territorio.carregar();
}

class VigiaChuvaApp extends StatelessWidget {
  const VigiaChuvaApp({super.key, required this.preferencias, required this.ocorrencias, required this.territorio});

  final PreferenciasController preferencias;
  final OcorrenciasController ocorrencias;
  final TerritorioController territorio;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: preferencias),
        ChangeNotifierProvider.value(value: ocorrencias),
        ChangeNotifierProvider.value(value: territorio),
      ],
      child: Consumer<PreferenciasController>(
        builder: (context, prefs, _) {
          final claro = prefs.altoContraste ? TemaVigiaChuva.altoContraste(escuro: false) : TemaVigiaChuva.claro();
          final escuro = prefs.altoContraste ? TemaVigiaChuva.altoContraste(escuro: true) : TemaVigiaChuva.escuro();
          return MaterialApp(
            title: 'VigiaChuva',
            debugShowCheckedModeBanner: false,
            theme: claro,
            darkTheme: escuro,
            themeMode: prefs.temaEscuro ? ThemeMode.dark : ThemeMode.light,
            // Primeira abertura: pede consentimento antes de tudo.
            initialRoute: prefs.consentimento == null ? Rotas.consentimento : Rotas.principal,
            onGenerateRoute: Rotas.gerar,
          );
        },
      ),
    );
  }
}
