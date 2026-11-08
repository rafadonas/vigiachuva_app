import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/rotas.dart';
import '../../app/tema.dart';
import '../../core/formatacao.dart';
import '../../core/territorio.dart';
import '../../data/modelos/ponto_serie.dart';
import '../../dominio/indicadores.dart';
import '../../estado/ocorrencias_controller.dart';
import '../../estado/territorio_controller.dart';
import '../componentes/componentes.dart';
import 'aba_alertas.dart';

/// Visão geral: situação do território, alerta mais grave, os 3 painéis e o benefício social.
class AbaInicio extends StatelessWidget {
  const AbaInicio({super.key, required this.irParaAlertas});
  final VoidCallback irParaAlertas;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TerritorioController>();
    final relatos = context.watch<OcorrenciasController>().todas;

    if (t.estado == EstadoCarga.inicial || t.estado == EstadoCarga.carregando) {
      return const EstadoCarregando();
    }

    final agora = t.agora;
    final previsao = t.previsao;
    final nivelAtual = t.nivelCorrego.ate(agora);
    final relatos7d = relatos.where((o) => o.registradaEm.isAfter(agora.subtract(const Duration(days: 7)))).length;
    final beneficio = t.beneficioSocial;

    return RefreshIndicator(
      onRefresh: () => context.read<TerritorioController>().carregar(),
      child: ListView(
        padding: const EdgeInsets.all(Espaco.m),
        children: [
          LarguraMaxima(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text('${Territorio.nome} · ${Territorio.municipio}', style: Theme.of(context).textTheme.titleLarge),
                ),
                Text('Atualizado ${dataHora(agora)} · ${milhar(Territorio.populacaoTotal)} moradores (estimativa fictícia)'),
                const SizedBox(height: Espaco.m),
                if (t.offline && previsao != null) ...[
                  BannerOffline(
                    coletadaEm: previsao.coletadaEm,
                    agora: agora,
                    aoTentarDeNovo: () => context.read<TerritorioController>().carregar(),
                  ),
                  const SizedBox(height: Espaco.m),
                ],
                if (t.estado == EstadoCarga.erro) ...[
                  EstadoErro(
                    mensagem:
                        '${t.mensagemErro ?? 'Erro desconhecido.'} A previsão de chuva não está disponível e não há dados salvos. '
                        'Os painéis de drenagem e de relatos continuam funcionando com dados locais.',
                    aoTentarDeNovo: () => context.read<TerritorioController>().carregar(),
                  ),
                  const SizedBox(height: Espaco.m),
                ],
                const TituloSecao('Situação agora'),
                if (t.alertas.isEmpty)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.verified_outlined),
                      title: Text('Nenhum alerta ativo'),
                      subtitle: Text('Nenhuma previsão ou regra atingiu os limiares configurados.'),
                    ),
                  )
                else ...[
                  CartaoAlerta(alerta: t.alertas.first),
                  if (t.alertas.length > 1)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: irParaAlertas, child: Text('Ver todos os ${t.alertas.length} alertas')),
                    ),
                ],
                const TituloSecao('Painéis do território'),
                GradeResponsiva(
                  filhos: [
                    CartaoIndicador(
                      titulo: 'Chuva: pico previsto (6 h)',
                      icone: Icons.water_drop_outlined,
                      valor: previsao == null ? '—' : decimal(previsao.picoProximas(agora, 6)?.valor ?? 0),
                      unidade: 'mm/h',
                      detalhe: previsao == null
                          ? 'Sem dados de chuva'
                          : '${decimal(previsao.acumuladoUltimas24h(agora))} mm nas últimas 24 h',
                      aoTocar: () => Navigator.pushNamed(context, Rotas.painelChuva),
                    ),
                    CartaoIndicador(
                      titulo: 'Drenagem: nível do córrego',
                      icone: Icons.waves,
                      valor: nivelAtual.isEmpty ? '—' : decimal(nivelAtual.last.valor, casas: 2),
                      unidade: 'm',
                      tendencia: nivelAtual.length >= 6
                          ? nivelAtual.sublist(nivelAtual.length - 3).media -
                                nivelAtual.sublist(nivelAtual.length - 6, nivelAtual.length - 3).media
                          : null,
                      detalhe: 'Dado simulado',
                      aoTocar: () => Navigator.pushNamed(context, Rotas.painelDrenagem),
                    ),
                    CartaoIndicador(
                      titulo: 'Relatos da comunidade',
                      icone: Icons.forum_outlined,
                      valor: '$relatos7d',
                      unidade: 'em 7 dias',
                      detalhe:
                          '${relatos.where((o) => o.grave && o.registradaEm.isAfter(agora.subtract(const Duration(hours: 24)))).length} graves nas últimas 24 h',
                      aoTocar: () => Navigator.pushNamed(context, Rotas.painelOcorrencias),
                    ),
                  ],
                ),
                const TituloSecao('Benefício social'),
                _CartaoBeneficio(beneficio: beneficio),
                const SizedBox(height: Espaco.m),
                const AvisoDecisaoHumana(),
                const SizedBox(height: Espaco.m),
                Text('Dados meteorológicos: Open-Meteo.com (CC BY 4.0).', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: Espaco.g),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoBeneficio extends StatelessWidget {
  const _CartaoBeneficio({required this.beneficio});
  final BeneficioSocial beneficio;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label:
                  '${milhar(beneficio.pessoasEmAreasAlertadas)} moradores em regiões com alerta ativo podem ser avisados antes do problema.',
              excludeSemantics: true,
              child: Row(
                children: [
                  Icon(Icons.groups_outlined, size: 40, color: tema.colorScheme.primary),
                  const SizedBox(width: Espaco.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          milhar(beneficio.pessoasEmAreasAlertadas),
                          style: tema.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Text('moradores em regiões com alerta ativo, que podem ser avisados antes do problema'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: Espaco.g),
            Text(
              beneficio.antecedenciaHoras == null
                  ? 'Sem alerta de chuva no momento: nenhuma antecedência a medir.'
                  : beneficio.antecedenciaHoras == 0
                  ? 'Antecedência do aviso de chuva forte: pico iminente (menos de 1 hora).'
                  : 'Antecedência do aviso de chuva forte: cerca de ${beneficio.antecedenciaHoras} h antes do pico previsto.',
            ),
            const SizedBox(height: Espaco.xs),
            Text('${beneficio.relatos7Dias} relatos da comunidade nos últimos 7 dias ajudam a priorizar a limpeza de bueiros e córregos.'),
            const SizedBox(height: Espaco.p),
            Text('População por região é estimativa fictícia do território-piloto.', style: tema.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
