import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/rotas.dart';
import '../../app/tema.dart';
import '../../core/formatacao.dart';
import '../../dominio/indicadores.dart';
import '../../estado/territorio_controller.dart';
import '../componentes/componentes.dart';

/// Detalhe do alerta (recebe o id por parâmetro): justificativa, confiança, limitações,
/// ação sugerida e o lembrete de que a decisão é humana.
class TelaDetalheAlerta extends StatelessWidget {
  const TelaDetalheAlerta({super.key, required this.alertaId});
  final String alertaId;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioController>();
    final alerta = t.alertaPorId(alertaId);
    if (alerta == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alerta')),
        body: const EstadoVazio(
          icone: Icons.notifications_off_outlined,
          titulo: 'Este alerta não está mais ativo',
          mensagem: 'Os dados foram atualizados e o valor ficou abaixo do limiar.',
        ),
      );
    }
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Alerta ${alerta.nivel.rotulo}')),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.m),
        children: [
          LarguraMaxima(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Espaco.p,
                  runSpacing: Espaco.p,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SeloNivel(alerta.nivel),
                    Chip(avatar: const Icon(Icons.place_outlined, size: 18), label: Text(nomeRegiao(alerta.regiaoId))),
                    Chip(avatar: const Icon(Icons.sensors, size: 18), label: Text(alerta.fonte.rotulo)),
                  ],
                ),
                const SizedBox(height: Espaco.m),
                Semantics(header: true, child: Text(alerta.titulo, style: tema.textTheme.headlineSmall)),
                const SizedBox(height: Espaco.p),
                Text(alerta.resumo, style: tema.textTheme.bodyLarge),
                Text('Gerado em ${dataHora(alerta.geradoEm)}', style: tema.textTheme.bodySmall),
                const TituloSecao('Por que este alerta? (evidências)'),
                ListaMarcadores(alerta.evidencias, icone: Icons.check),
                const TituloSecao('Nível de confiança'),
                BarraConfianca(valor: alerta.confianca, rotulo: alerta.rotuloConfianca),
                const SizedBox(height: Espaco.p),
                Text(alerta.explicacaoConfianca),
                const TituloSecao('Limitações: quando não confiar'),
                ListaMarcadores(alerta.limitacoes, icone: Icons.remove),
                const TituloSecao('Ação sugerida'),
                Card(
                  child: ListTile(
                    leading: Icon(TemaVigiaChuva.iconeNivel(alerta.nivel)),
                    title: Text(alerta.acaoSugerida),
                    subtitle: const Text('Sugestão para apoiar a decisão, não uma ordem automática.'),
                  ),
                ),
                const SizedBox(height: Espaco.m),
                const AvisoDecisaoHumana(),
                const SizedBox(height: Espaco.m),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, Rotas.indicador, arguments: alerta.indicadorId),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                  icon: const Icon(Icons.show_chart),
                  label: const Text('Ver o indicador que gerou o alerta'),
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
