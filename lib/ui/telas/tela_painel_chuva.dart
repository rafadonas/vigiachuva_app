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

/// Dashboard 1: chuva observada (24 h) e prevista (24 h), dados reais da Open-Meteo.
class TelaPainelChuva extends StatelessWidget {
  const TelaPainelChuva({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioController>();
    final limiares = context.watch<PreferenciasController>().limiares.chuvaMmH;
    final altoContraste = context.watch<PreferenciasController>().altoContraste;
    final previsao = t.previsao;
    final agora = t.agora;

    Widget corpo;
    if (t.estado == EstadoCarga.carregando || t.estado == EstadoCarga.inicial) {
      corpo = const EstadoCarregando(mensagem: 'Buscando previsão de chuva...');
    } else if (previsao == null) {
      corpo = EstadoErro(
        mensagem: '${t.mensagemErro ?? ''} Conecte-se à internet ao menos uma vez para salvar a previsão e usá-la depois sem conexão.',
        aoTentarDeNovo: () => context.read<TerritorioController>().carregar(),
      );
    } else {
      final passado = previsao.ultimas24h(agora);
      final futuro = previsao.proximas(agora, 24);
      final serie = [...passado, ...futuro];
      final pico = previsao.picoProximas(agora, 6);
      final ultimas6 = passado.length >= 6 ? passado.sublist(passado.length - 6).soma : passado.soma;
      final proximas6 = previsao.proximas(agora, 6).soma;
      corpo = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.offline) ...[
            BannerOffline(
              coletadaEm: previsao.coletadaEm,
              agora: agora,
              aoTentarDeNovo: () => context.read<TerritorioController>().carregar(),
            ),
            const SizedBox(height: Espaco.m),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Espaco.m),
              child: GraficoSerie(
                serie: serie,
                agora: agora,
                unidade: 'mm/h',
                barras: true,
                limiares: [
                  LinhaLimiar(
                    limiares.atencao,
                    'ATENÇÃO',
                    (altoContraste ? Theme.of(context).colorScheme.primary : TemaVigiaChuva.corNivel(NivelAlerta.atencao)),
                  ),
                  LinhaLimiar(
                    limiares.alerta,
                    'ALERTA',
                    (altoContraste ? Theme.of(context).colorScheme.primary : TemaVigiaChuva.corNivel(NivelAlerta.alerta)),
                  ),
                ],
                descricaoAcessivel:
                    'Gráfico de barras da chuva por hora. Últimas 24 horas: ${decimal(passado.soma)} milímetros no total. '
                    'Próximas 24 horas: ${decimal(futuro.soma)} milímetros previstos, com pico de ${decimal(pico?.valor ?? 0)} milímetros por hora.',
              ),
            ),
          ),
          const TituloSecao('Indicadores'),
          GradeResponsiva(
            filhos: [
              CartaoIndicador(
                titulo: 'Pico previsto nas próximas 6 h',
                icone: Icons.thunderstorm_outlined,
                valor: decimal(pico?.valor ?? 0),
                unidade: 'mm/h',
                detalhe: pico == null
                    ? null
                    : 'às ${hora(pico.instante)} · chance de chuva ${previsao.probabilidadeEm(pico.instante).round()}%',
                aoTocar: () => Navigator.pushNamed(context, Rotas.indicador, arguments: 'chuva_pico_6h'),
              ),
              CartaoIndicador(
                titulo: 'Chuva nas últimas 24 h',
                icone: Icons.history,
                valor: decimal(previsao.acumuladoUltimas24h(agora)),
                unidade: 'mm',
                tendencia: proximas6 - ultimas6,
                detalhe: 'Próximas 6 h: ${decimal(proximas6)} mm · últimas 6 h: ${decimal(ultimas6)} mm',
                aoTocar: () => Navigator.pushNamed(context, Rotas.indicador, arguments: 'chuva_24h'),
              ),
              CartaoIndicador(
                titulo: 'Previsto para as próximas 24 h',
                icone: Icons.update,
                valor: decimal(previsao.acumuladoProximas24h(agora)),
                unidade: 'mm',
                detalhe: 'Chance máxima de chuva: ${previsao.probabilidadeMaximaProximas(agora, 24).round()}%',
              ),
            ],
          ),
          const SizedBox(height: Espaco.m),
          Text(
            'Fonte: Open-Meteo.com (CC BY 4.0), modelo para ${decimal(previsao.latitude, casas: 2)}, ${decimal(previsao.longitude, casas: 2)}. '
            'Coletado em ${dataHora(previsao.coletadaEm)}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Painel de chuva')),
      body: RefreshIndicator(
        onRefresh: () => context.read<TerritorioController>().carregar(),
        child: ListView(
          padding: const EdgeInsets.all(Espaco.m),
          children: [LarguraMaxima(child: corpo)],
        ),
      ),
    );
  }
}
