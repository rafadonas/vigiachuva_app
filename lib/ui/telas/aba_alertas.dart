import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/rotas.dart';
import '../../app/tema.dart';
import '../../core/formatacao.dart';
import '../../data/modelos/alerta.dart';
import '../../dominio/indicadores.dart';
import '../../estado/territorio_controller.dart';
import '../componentes/componentes.dart';

/// Lista de alertas ativos, do mais grave para o menos grave.
class AbaAlertas extends StatelessWidget {
  const AbaAlertas({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioController>();
    if (t.estado == EstadoCarga.inicial || t.estado == EstadoCarga.carregando) {
      return const EstadoCarregando(mensagem: 'Calculando alertas...');
    }
    return ListView(
      padding: const EdgeInsets.all(Espaco.m),
      children: [
        LarguraMaxima(
          child: Column(
            children: [
              const AvisoDecisaoHumana(),
              const SizedBox(height: Espaco.m),
              if (t.alertas.isEmpty)
                const EstadoVazio(
                  icone: Icons.notifications_off_outlined,
                  titulo: 'Nenhum alerta ativo',
                  mensagem: 'As previsões e os relatos estão abaixo dos limiares configurados. Você pode ajustar os limiares em Ajustes.',
                )
              else
                for (final a in t.alertas) ...[CartaoAlerta(alerta: a), const SizedBox(height: Espaco.m)],
            ],
          ),
        ),
      ],
    );
  }
}

/// Cartão resumido de um alerta; abre o detalhe por rota nomeada com o id do alerta.
class CartaoAlerta extends StatelessWidget {
  const CartaoAlerta({super.key, required this.alerta});
  final Alerta alerta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Semantics(
      button: true,
      label:
          'Alerta ${alerta.nivel.rotulo}: ${alerta.titulo}. ${nomeRegiao(alerta.regiaoId)}. ${alerta.resumo} '
          'Confiança ${alerta.rotuloConfianca}. Toque para ver a justificativa.',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, Rotas.alerta, arguments: alerta.id),
          child: Padding(
            padding: const EdgeInsets.all(Espaco.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Espaco.p,
                  runSpacing: Espaco.p,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SeloNivel(alerta.nivel),
                    Text(alerta.fonte.rotulo, style: tema.textTheme.labelLarge),
                    Text.rich(
                      TextSpan(
                        children: [
                          const WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.place_outlined, size: 16)),
                          TextSpan(text: ' ${nomeRegiao(alerta.regiaoId)}'),
                        ],
                      ),
                      style: tema.textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: Espaco.p),
                Text(alerta.titulo, style: tema.textTheme.titleMedium),
                const SizedBox(height: Espaco.xs),
                Text(alerta.resumo),
                const SizedBox(height: Espaco.p),
                Row(
                  children: [
                    const Icon(Icons.speed, size: 18),
                    const SizedBox(width: Espaco.xs),
                    Expanded(child: Text('Confiança ${alerta.rotuloConfianca} (${percentual(alerta.confianca)})')),
                  ],
                ),
                const SizedBox(height: Espaco.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Ver justificativa',
                        style: TextStyle(color: tema.colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.chevron_right, color: tema.colorScheme.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
