import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/rotas.dart';
import '../../app/tema.dart';
import '../../core/formatacao.dart';
import '../../core/territorio.dart';
import '../../data/modelos/ocorrencia.dart';
import '../../data/modelos/ponto_serie.dart';
import '../../estado/ocorrencias_controller.dart';
import '../../estado/territorio_controller.dart';
import '../componentes/componentes.dart';
import '../componentes/graficos.dart';
import 'aba_relatos.dart';

/// Dashboard 3: relatos da comunidade por dia, categoria e região (últimos 7 dias).
class TelaPainelOcorrencias extends StatelessWidget {
  const TelaPainelOcorrencias({super.key});

  @override
  Widget build(BuildContext context) {
    final controle = context.watch<OcorrenciasController>();
    final agora = context.watch<TerritorioController>().agora;
    Widget corpo;
    if (!controle.carregado) {
      corpo = const EstadoCarregando(mensagem: 'Carregando relatos...');
    } else {
      final semana = controle.todas.where((o) => o.registradaEm.isAfter(agora.subtract(const Duration(days: 7)))).toList();
      if (semana.isEmpty) {
        corpo = EstadoVazio(
          icone: Icons.forum_outlined,
          titulo: 'Nenhum relato nos últimos 7 dias',
          mensagem: 'Quando moradores registrarem ocorrências, elas aparecem aqui.',
          acao: FilledButton(onPressed: () => Navigator.pushNamed(context, Rotas.novaOcorrencia), child: const Text('Registrar relato')),
        );
      } else {
        final hoje = DateTime(agora.year, agora.month, agora.day);
        final porDia = [
          for (var d = 6; d >= 0; d--)
            PontoSerie(
              hoje.subtract(Duration(days: d)).add(const Duration(hours: 12)),
              semana.where((o) => _mesmoDia(o.registradaEm, hoje.subtract(Duration(days: d)))).length.toDouble(),
            ),
        ];
        final porCategoria = {for (final c in CategoriaOcorrencia.values) c.rotulo: semana.where((o) => o.categoria == c).length}
          ..removeWhere((_, v) => v == 0);
        final porRegiao = {for (final r in Territorio.regioes) r.nome: semana.where((o) => o.regiaoId == r.id).length};
        final graves = semana.where((o) => o.grave).length;
        final ultimos3 = porDia.sublist(4).soma;
        final anteriores3 = porDia.sublist(1, 4).soma;

        corpo = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradeResponsiva(
              filhos: [
                CartaoIndicador(
                  titulo: 'Relatos em 7 dias',
                  icone: Icons.forum_outlined,
                  valor: '${semana.length}',
                  unidade: semana.length == 1 ? 'relato' : 'relatos',
                  tendencia: ultimos3 - anteriores3,
                  detalhe: 'Últimos 3 dias: ${ultimos3.round()} · 3 dias anteriores: ${anteriores3.round()}',
                  aoTocar: () => Navigator.pushNamed(context, Rotas.indicador, arguments: 'ocorrencias_7d'),
                ),
                CartaoIndicador(
                  titulo: 'Relatos graves',
                  icone: Icons.warning_amber_rounded,
                  valor: '$graves',
                  unidade: 'de ${semana.length}',
                  detalhe: 'Água no joelho ou acima, córrego transbordando ou deslizamento',
                ),
              ],
            ),
            const TituloSecao('Relatos por dia'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Espaco.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in porDia)
                      Semantics(
                        label: '${dataCurta(p.instante)}: ${p.valor.round()} ${p.valor.round() == 1 ? 'relato' : 'relatos'}',
                        excludeSemantics: true,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              SizedBox(width: 48, child: Text(dataCurta(p.instante))),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(value: porDia.maximo == 0 ? 0 : p.valor / porDia.maximo, minHeight: 12),
                                ),
                              ),
                              SizedBox(width: 32, child: Text('${p.valor.round()}', textAlign: TextAlign.end)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const TituloSecao('Por categoria'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Espaco.m),
                child: GraficoBarrasHorizontais(itens: porCategoria),
              ),
            ),
            const TituloSecao('Por região'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Espaco.m),
                child: GraficoBarrasHorizontais(itens: porRegiao),
              ),
            ),
            const TituloSecao('Mais recentes'),
            for (final o in semana.take(5)) ...[ItemRelato(ocorrencia: o), const SizedBox(height: Espaco.p)],
          ],
        );
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Painel de ocorrências')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, Rotas.novaOcorrencia),
        icon: const Icon(Icons.add),
        label: const Text('Novo relato'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Espaco.m, Espaco.m, Espaco.m, 96),
        children: [LarguraMaxima(child: corpo)],
      ),
    );
  }

  static bool _mesmoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
