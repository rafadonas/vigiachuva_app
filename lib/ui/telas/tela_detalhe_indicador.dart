import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/rotas.dart';
import '../../app/tema.dart';
import '../../core/formatacao.dart';
import '../../data/modelos/ponto_serie.dart';
import '../../dominio/indicadores.dart';
import '../../estado/ocorrencias_controller.dart';
import '../../estado/territorio_controller.dart';
import '../componentes/componentes.dart';
import '../componentes/graficos.dart';
import 'aba_alertas.dart';

/// Detalhe de um indicador (recebe o id por parâmetro de rota): definição, fonte,
/// cálculo, limitações, histórico e os alertas que ele originou.
class TelaDetalheIndicador extends StatelessWidget {
  const TelaDetalheIndicador({super.key, required this.indicadorId});
  final String indicadorId;

  List<PontoSerie> _serie(TerritorioController t, OcorrenciasController o) {
    final agora = t.agora;
    switch (indicadorId) {
      case 'chuva_24h':
      case 'chuva_pico_6h':
        final p = t.previsao;
        return p == null ? [] : [...p.ultimas24h(agora), ...p.proximas(agora, 24)];
      case 'nivel_corrego':
        return t.nivelCorrego;
      case 'umidade_solo':
        return t.umidadeSolo;
      default:
        final hoje = DateTime(agora.year, agora.month, agora.day);
        return [
          for (var d = 6; d >= 0; d--)
            PontoSerie(
              hoje.subtract(Duration(days: d)).add(const Duration(hours: 12)),
              o.todas
                  .where((x) {
                    final dia = hoje.subtract(Duration(days: d));
                    return x.registradaEm.year == dia.year && x.registradaEm.month == dia.month && x.registradaEm.day == dia.day;
                  })
                  .length
                  .toDouble(),
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final definicao = catalogoIndicadores[indicadorId];
    final t = context.watch<TerritorioController>();
    final o = context.watch<OcorrenciasController>();
    if (definicao == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Indicador')),
        body: const EstadoVazio(icone: Icons.search_off, titulo: 'Indicador não encontrado', mensagem: 'Volte e escolha outro indicador.'),
      );
    }
    final serie = _serie(t, o);
    final alertas = t.alertasDoIndicador(indicadorId);
    final ehDiario = indicadorId == 'ocorrencias_7d';
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(definicao.titulo)),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.m),
        children: [
          LarguraMaxima(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(definicao.definicao, style: tema.textTheme.bodyLarge),
                const SizedBox(height: Espaco.m),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Espaco.m),
                    child: serie.isEmpty
                        ? const EstadoVazio(
                            icone: Icons.cloud_off,
                            titulo: 'Sem dados',
                            mensagem: 'Este indicador depende da previsão de chuva, que não está disponível.',
                          )
                        : ehDiario
                        ? GraficoBarrasHorizontais(itens: {for (final p in serie) dataCurta(p.instante): p.valor.round()})
                        : GraficoSerie(
                            serie: serie,
                            agora: t.agora,
                            unidade: definicao.unidade,
                            barras: indicadorId.startsWith('chuva'),
                            altura: 260,
                            descricaoAcessivel:
                                'Histórico de ${definicao.titulo}: mínimo ${decimal(serie.map((p) => p.valor).reduce((a, b) => a < b ? a : b))}, '
                                'máximo ${decimal(serie.maximo)} ${definicao.unidade}.',
                          ),
                  ),
                ),
                const TituloSecao('Fonte dos dados'),
                Text(definicao.fonte),
                const TituloSecao('Como é calculado'),
                Text(definicao.calculo),
                const TituloSecao('Limitações'),
                ListaMarcadores(definicao.limitacoes),
                TituloSecao('Alertas gerados por este indicador (${alertas.length})'),
                if (alertas.isEmpty)
                  const Text('Nenhum alerta ativo: os valores estão abaixo dos limiares configurados.')
                else
                  for (final a in alertas) ...[CartaoAlerta(alerta: a), const SizedBox(height: Espaco.p)],
                const SizedBox(height: Espaco.m),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, Rotas.painel(definicao.painel)),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Abrir o painel deste indicador'),
                ),
                const SizedBox(height: Espaco.g),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
