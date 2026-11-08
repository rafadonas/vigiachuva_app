import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/rotas.dart';
import '../../app/tema.dart';
import '../../core/formatacao.dart';
import '../../data/modelos/alerta.dart';
import '../../data/modelos/ponto_serie.dart';
import '../../estado/preferencias_controller.dart';
import '../../estado/territorio_controller.dart';
import '../componentes/componentes.dart';
import '../componentes/graficos.dart';

/// Dashboard 2: drenagem (nível do córrego e umidade do solo). Dados SIMULADOS.
class TelaPainelDrenagem extends StatelessWidget {
  const TelaPainelDrenagem({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioController>();
    final prefs = context.watch<PreferenciasController>();
    final agora = t.agora;
    final ac = prefs.altoContraste;

    Widget corpo;
    if (t.estado == EstadoCarga.carregando || t.estado == EstadoCarga.inicial) {
      corpo = const EstadoCarregando();
    } else if (t.nivelCorrego.isEmpty) {
      corpo = const EstadoVazio(icone: Icons.waves, titulo: 'Sem dados de drenagem', mensagem: 'Nenhuma leitura disponível.');
    } else {
      final nivel = t.nivelCorrego.ate(agora);
      final umidade = t.umidadeSolo.ate(agora);
      final lN = prefs.limiares.nivelCorregoM;
      final lU = prefs.limiares.umidadeSoloPct;
      final tendenciaNivel = nivel.length >= 6
          ? nivel.sublist(nivel.length - 3).media - nivel.sublist(nivel.length - 6, nivel.length - 3).media
          : null;
      final tendenciaUmidade = umidade.length >= 6
          ? umidade.sublist(umidade.length - 3).media - umidade.sublist(umidade.length - 6, umidade.length - 3).media
          : null;
      corpo = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const ListTile(
              leading: Icon(Icons.science_outlined),
              title: Text('Dados simulados'),
              subtitle: Text(
                'Sem sensores reais no protótipo: o nível e a umidade são calculados a partir da chuva real por um modelo didático.',
              ),
            ),
          ),
          const TituloSecao('Nível do córrego (Baixada)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Espaco.m),
              child: GraficoSerie(
                serie: t.nivelCorrego,
                agora: agora,
                unidade: 'm',
                limiares: [
                  LinhaLimiar(
                    lN.atencao,
                    'ATENÇÃO',
                    (ac ? Theme.of(context).colorScheme.primary : TemaVigiaChuva.corNivel(NivelAlerta.atencao)),
                  ),
                  LinhaLimiar(
                    lN.alerta,
                    'ALERTA',
                    (ac ? Theme.of(context).colorScheme.primary : TemaVigiaChuva.corNivel(NivelAlerta.alerta)),
                  ),
                  LinhaLimiar(
                    lN.critico,
                    'CRÍTICO',
                    (ac ? Theme.of(context).colorScheme.primary : TemaVigiaChuva.corNivel(NivelAlerta.critico)),
                  ),
                ],
                descricaoAcessivel:
                    'Gráfico de linha do nível do córrego. Agora: ${decimal(nivel.last.valor, casas: 2)} metros. '
                    'Limite de alerta: ${decimal(lN.alerta)} metros.',
              ),
            ),
          ),
          const SizedBox(height: Espaco.m),
          GradeResponsiva(
            filhos: [
              CartaoIndicador(
                titulo: 'Nível do córrego agora',
                icone: Icons.waves,
                valor: decimal(nivel.last.valor, casas: 2),
                unidade: 'm',
                tendencia: tendenciaNivel,
                detalhe: 'Máximo nas últimas 24 h: ${decimal(nivel.sublist(nivel.length > 24 ? nivel.length - 24 : 0).maximo, casas: 2)} m',
                aoTocar: () => Navigator.pushNamed(context, Rotas.indicador, arguments: 'nivel_corrego'),
              ),
              CartaoIndicador(
                titulo: 'Umidade do solo (Encosta Norte)',
                icone: Icons.terrain,
                valor: umidade.isEmpty ? '—' : decimal(umidade.last.valor),
                unidade: '%',
                tendencia: tendenciaUmidade,
                detalhe: 'Limite de ALERTA: ${decimal(lU.alerta)}%',
                aoTocar: () => Navigator.pushNamed(context, Rotas.indicador, arguments: 'umidade_solo'),
              ),
            ],
          ),
          const TituloSecao('Umidade do solo'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Espaco.m),
              child: GraficoSerie(
                serie: t.umidadeSolo,
                agora: agora,
                unidade: '%',
                minY: 0,
                maxY: 100,
                limiares: [
                  LinhaLimiar(
                    lU.alerta,
                    'ALERTA',
                    (ac ? Theme.of(context).colorScheme.primary : TemaVigiaChuva.corNivel(NivelAlerta.alerta)),
                  ),
                ],
                descricaoAcessivel:
                    'Gráfico de linha da umidade do solo. Agora: ${decimal(umidade.isEmpty ? 0 : umidade.last.valor)} por cento.',
              ),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Painel de drenagem')),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.m),
        children: [LarguraMaxima(child: corpo)],
      ),
    );
  }
}
