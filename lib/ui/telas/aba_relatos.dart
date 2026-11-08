import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/rotas.dart';
import '../../app/tema.dart';
import '../../core/formatacao.dart';
import '../../core/territorio.dart';
import '../../data/modelos/ocorrencia.dart';
import '../../estado/ocorrencias_controller.dart';
import '../componentes/componentes.dart';

/// Lista de relatos (os seus primeiro na ordem de data, com os de exemplo identificados).
class AbaRelatos extends StatelessWidget {
  const AbaRelatos({super.key});

  @override
  Widget build(BuildContext context) {
    final controle = context.watch<OcorrenciasController>();
    if (!controle.carregado) return const EstadoCarregando(mensagem: 'Carregando relatos...');
    final relatos = controle.todas;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Espaco.m, Espaco.m, Espaco.m, 96),
      children: [
        LarguraMaxima(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Relatos anônimos de moradores. Os marcados como "exemplo" são fictícios e acompanham o protótipo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: Espaco.m),
              if (relatos.isEmpty)
                EstadoVazio(
                  icone: Icons.forum_outlined,
                  titulo: 'Nenhum relato ainda',
                  mensagem: 'Viu um alagamento ou um bueiro entupido? Registre para ajudar a comunidade.',
                  acao: FilledButton(
                    onPressed: () => Navigator.pushNamed(context, Rotas.novaOcorrencia),
                    child: const Text('Registrar relato'),
                  ),
                )
              else
                for (final o in relatos) ...[ItemRelato(ocorrencia: o), const SizedBox(height: Espaco.p)],
            ],
          ),
        ),
      ],
    );
  }
}

class ItemRelato extends StatelessWidget {
  const ItemRelato({super.key, required this.ocorrencia});
  final Ocorrencia ocorrencia;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(
          ocorrencia.grave ? Icons.warning_amber_rounded : Icons.water_drop_outlined,
          color: ocorrencia.grave ? tema.colorScheme.error : tema.colorScheme.primary,
          semanticLabel: ocorrencia.grave ? 'Grave' : 'Comum',
        ),
        title: Text(ocorrencia.categoria.rotulo),
        subtitle: Text(
          '${Territorio.regiao(ocorrencia.regiaoId).nome} · ${dataHora(ocorrencia.registradaEm)}\n'
          '${ocorrencia.nivelAgua.rotulo} · ${ocorrencia.descricao}',
        ),
        isThreeLine: true,
        trailing: ocorrencia.exemplo ? const Chip(label: Text('exemplo'), visualDensity: VisualDensity.compact) : null,
      ),
    );
  }
}
