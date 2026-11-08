import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/formatacao.dart';
import '../../data/modelos/ponto_serie.dart';

/// Linha horizontal de referência (limiar) desenhada no gráfico.
class LinhaLimiar {
  const LinhaLimiar(this.valor, this.rotulo, this.cor);
  final double valor;
  final String rotulo;
  final Color cor;
}

/// Gráfico de série temporal reutilizável. Passado e futuro têm cores diferentes,
/// "agora" é marcado por uma linha vertical. Leitores de tela recebem um resumo em texto.
class GraficoSerie extends StatelessWidget {
  const GraficoSerie({
    super.key,
    required this.serie,
    required this.agora,
    required this.unidade,
    required this.descricaoAcessivel,
    this.barras = false,
    this.limiares = const [],
    this.altura = 220,
    this.minY,
    this.maxY,
  });

  final List<PontoSerie> serie;
  final DateTime agora;
  final String unidade;
  final String descricaoAcessivel;
  final bool barras;
  final List<LinhaLimiar> limiares;
  final double altura;
  final double? minY;

  /// Teto opcional do eixo Y (ex.: 100 para percentuais).
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    if (serie.isEmpty) {
      return SizedBox(
        height: altura,
        child: const Center(child: Text('Sem dados para exibir.')),
      );
    }
    final inicio = serie.first.instante;
    double x(DateTime t) => t.difference(inicio).inMinutes / 60;
    final xAgora = x(agora);
    // Escala pelos dados; o primeiro limiar sempre aparece, os demais só se couberem
    // (assim um dia seco não vira um gráfico de barras achatadas).
    final menorLimiar = limiares.isEmpty ? 0.0 : limiares.map((l) => l.valor).reduce((a, b) => a < b ? a : b);
    final maxValor = [serie.maximo * 1.3, menorLimiar * 1.2].reduce((a, b) => a > b ? a : b);
    final maxY = this.maxY ?? (maxValor <= 0 ? 1.0 : maxValor);
    final limiaresVisiveis = limiares.where((l) => l.valor <= maxY).toList();
    final corPassado = cores.primary;
    final corFuturo = cores.secondary.withValues(alpha: 0.75);

    final titulos = FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        axisNameWidget: Text(unidade, style: const TextStyle(fontSize: 11)),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (v, meta) {
            // Omite o rótulo do topo quando ele não cai num intervalo (evita números sobrepostos).
            if (v == meta.max && (v / meta.appliedInterval - (v / meta.appliedInterval).round()).abs() > 0.01) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              child: Text(decimal(v), style: const TextStyle(fontSize: 10)),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: 6,
          getTitlesWidget: (v, meta) {
            // No gráfico de barras cada barra tem rótulo próprio: mostra só a cada 6 h.
            if (barras && v.round() % 6 != 0) return const SizedBox.shrink();
            final t = inicio.add(Duration(minutes: (v * 60).round()));
            return SideTitleWidget(
              meta: meta,
              child: Text(hora(t), style: const TextStyle(fontSize: 10)),
            );
          },
        ),
      ),
    );
    final linhasExtras = ExtraLinesData(
      verticalLines: [
        VerticalLine(
          x: xAgora,
          color: cores.onSurface,
          strokeWidth: 1.5,
          dashArray: [4, 4],
          label: VerticalLineLabel(
            show: true,
            labelResolver: (_) => 'agora',
            style: TextStyle(color: cores.onSurface, fontSize: 10),
          ),
        ),
      ],
      horizontalLines: [
        for (final l in limiaresVisiveis)
          HorizontalLine(
            y: l.valor,
            color: l.cor,
            strokeWidth: 1.5,
            dashArray: [6, 3],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              labelResolver: (_) => l.rotulo,
              style: TextStyle(color: l.cor, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );

    final grafico = barras
        ? BarChart(
            BarChartData(
              minY: minY ?? 0,
              maxY: maxY,
              titlesData: titulos,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(horizontalLines: linhasExtras.horizontalLines),
              barTouchData: BarTouchData(enabled: true),
              barGroups: [
                for (final p in serie)
                  BarChartGroupData(
                    x: x(p.instante).round(),
                    barRods: [
                      BarChartRodData(
                        toY: p.valor,
                        width: 4,
                        color: p.instante.isAfter(agora) ? corFuturo : corPassado,
                        borderRadius: BorderRadius.zero,
                      ),
                    ],
                  ),
              ],
            ),
          )
        : LineChart(
            LineChartData(
              minY: minY ?? 0,
              maxY: maxY,
              titlesData: titulos,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              extraLinesData: linhasExtras,
              lineBarsData: [
                LineChartBarData(
                  spots: [for (final p in serie.ate(agora)) FlSpot(x(p.instante), p.valor)],
                  color: corPassado,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                ),
                LineChartBarData(
                  spots: [
                    for (final p in serie.where((p) => !p.instante.isBefore(agora.subtract(const Duration(hours: 1)))))
                      FlSpot(x(p.instante), p.valor),
                  ],
                  color: corFuturo,
                  barWidth: 2.5,
                  dashArray: [6, 4],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          );

    return Semantics(
      label: descricaoAcessivel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: altura,
            child: Padding(padding: const EdgeInsets.only(right: 8, top: 8), child: grafico),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _Legenda(cor: corPassado, texto: 'Observado (até agora)'),
              _Legenda(cor: corFuturo, texto: 'Previsto / projetado'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.cor, required this.texto});
  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 6),
      Text(texto, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

/// Barras horizontais simples (contagem por categoria/região), acessíveis e responsivas.
class GraficoBarrasHorizontais extends StatelessWidget {
  const GraficoBarrasHorizontais({super.key, required this.itens});
  final Map<String, int> itens;

  @override
  Widget build(BuildContext context) {
    final maximo = itens.values.fold(0, (a, b) => a > b ? a : b);
    final cores = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final e in itens.entries)
          Semantics(
            label: '${e.key}: ${e.value}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(e.key)),
                      Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: maximo == 0 ? 0 : e.value / maximo,
                      minHeight: 10,
                      color: cores.primary,
                      backgroundColor: cores.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
