import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/tema.dart';
import '../../core/formatacao.dart';
import '../../data/modelos/alerta.dart';
import '../../estado/preferencias_controller.dart';

/// Título de seção com espaçamento padrão; marcado como cabeçalho para leitores de tela.
class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key, this.acao});
  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Espaco.g, bottom: Espaco.p),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(texto, style: Theme.of(context).textTheme.titleLarge)),
          ),
          ?acao,
        ],
      ),
    );
  }
}

/// Cartão de indicador (valor grande + rótulo + tendência). Tocável quando há [aoTocar].
class CartaoIndicador extends StatelessWidget {
  const CartaoIndicador({
    super.key,
    required this.titulo,
    required this.valor,
    required this.unidade,
    this.detalhe,
    this.tendencia,
    this.icone,
    this.aoTocar,
  });

  final String titulo;
  final String valor;
  final String unidade;
  final String? detalhe;

  /// > 0 subindo, < 0 descendo, 0 estável, null sem tendência.
  final double? tendencia;
  final IconData? icone;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final textoTendencia = switch (tendencia) {
      null => null,
      > 0.05 => 'subindo',
      < -0.05 => 'descendo',
      _ => 'estável',
    };
    final iconeTendencia = switch (textoTendencia) {
      'subindo' => Icons.trending_up,
      'descendo' => Icons.trending_down,
      'estável' => Icons.trending_flat,
      _ => null,
    };
    return Semantics(
      button: aoTocar != null,
      label:
          '$titulo: $valor $unidade${textoTendencia != null ? ', tendência $textoTendencia' : ''}'
          '${detalhe != null ? '. $detalhe' : ''}${aoTocar != null ? '. Toque para ver detalhes' : ''}',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(Espaco.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icone != null) ...[Icon(icone, size: 20, color: tema.colorScheme.primary), const SizedBox(width: Espaco.p)],
                    Expanded(child: Text(titulo, style: tema.textTheme.labelLarge)),
                    if (aoTocar != null) Icon(Icons.chevron_right, color: tema.colorScheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: Espaco.p),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: Espaco.xs,
                  children: [
                    Text(valor, style: tema.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(unidade, style: tema.textTheme.titleSmall),
                    ),
                  ],
                ),
                if (iconeTendencia != null)
                  Row(
                    children: [
                      Icon(iconeTendencia, size: 18),
                      const SizedBox(width: Espaco.xs),
                      Flexible(child: Text('Tendência: $textoTendencia', style: tema.textTheme.bodySmall)),
                    ],
                  ),
                if (detalhe != null) ...[const SizedBox(height: Espaco.xs), Text(detalhe!, style: tema.textTheme.bodySmall)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Selo colorido com o nível do alerta (cor + ícone + texto: não depende só da cor).
class SeloNivel extends StatelessWidget {
  const SeloNivel(this.nivel, {super.key});
  final NivelAlerta nivel;

  @override
  Widget build(BuildContext context) {
    final altoContraste = context.watch<PreferenciasController>().altoContraste;
    final esquema = Theme.of(context).colorScheme;
    // No alto contraste o selo usa a cor primária do tema (amarelo no escuro, preto no claro).
    final cor = altoContraste ? esquema.primary : TemaVigiaChuva.corNivel(nivel);
    final corTexto = altoContraste ? esquema.onPrimary : Colors.white;
    return Semantics(
      label: 'Nível ${nivel.rotulo}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.p, vertical: Espaco.xs),
        decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TemaVigiaChuva.iconeNivel(nivel), size: 16, color: corTexto),
            const SizedBox(width: Espaco.xs),
            Text(
              nivel.rotulo,
              style: TextStyle(color: corTexto, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso fixo: o alerta apoia, mas não substitui, a decisão humana.
class AvisoDecisaoHumana extends StatelessWidget {
  const AvisoDecisaoHumana({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Espaco.m),
        decoration: BoxDecoration(
          color: tema.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tema.colorScheme.secondary),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person_outline, color: tema.colorScheme.onSecondaryContainer),
            const SizedBox(width: Espaco.p),
            Expanded(
              child: Text(
                'Os alertas apoiam, mas não substituem, a decisão humana. O VigiaChuva sugere ações; '
                'quem decide é a Defesa Civil ou a liderança responsável. Em emergência, ligue 199 (Defesa Civil) ou 193 (Bombeiros).',
                style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faixa exibida quando o app está usando dados salvos (sem conexão).
class BannerOffline extends StatelessWidget {
  const BannerOffline({super.key, required this.coletadaEm, required this.agora, this.aoTentarDeNovo});
  final DateTime coletadaEm;
  final DateTime agora;
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Material(
        color: tema.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(Espaco.m),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: tema.colorScheme.onTertiaryContainer),
              const SizedBox(width: Espaco.p),
              Expanded(
                child: Text(
                  'Sem conexão: mostrando a previsão salva ${tempoDecorrido(coletadaEm, agora)} (${dataHora(coletadaEm)}).',
                  style: TextStyle(color: tema.colorScheme.onTertiaryContainer),
                ),
              ),
              if (aoTentarDeNovo != null) TextButton(onPressed: aoTentarDeNovo, child: const Text('Tentar de novo')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado de carregamento padrão.
class EstadoCarregando extends StatelessWidget {
  const EstadoCarregando({super.key, this.mensagem = 'Carregando dados do território...'});
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.g),
        child: Semantics(
          liveRegion: true,
          label: mensagem,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: Espaco.m),
              Text(mensagem, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado de erro padrão, com botão para tentar de novo.
class EstadoErro extends StatelessWidget {
  const EstadoErro({super.key, required this.mensagem, this.aoTentarDeNovo});
  final String mensagem;
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      color: tema.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(Espaco.m),
        child: Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: tema.colorScheme.onErrorContainer),
                  const SizedBox(width: Espaco.p),
                  Expanded(
                    child: Text(
                      'Não foi possível carregar',
                      style: tema.textTheme.titleMedium?.copyWith(color: tema.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Espaco.p),
              Text(mensagem, style: TextStyle(color: tema.colorScheme.onErrorContainer)),
              if (aoTentarDeNovo != null) ...[
                const SizedBox(height: Espaco.m),
                FilledButton.icon(onPressed: aoTentarDeNovo, icon: const Icon(Icons.refresh), label: const Text('Tentar de novo')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado de lista vazia padrão.
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({super.key, required this.icone, required this.titulo, required this.mensagem, this.acao});
  final IconData icone;
  final String titulo;
  final String mensagem;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espaco.gg, horizontal: Espaco.m),
      child: Column(
        children: [
          Icon(icone, size: 56, color: tema.colorScheme.primary),
          const SizedBox(height: Espaco.m),
          Text(titulo, style: tema.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: Espaco.p),
          Text(mensagem, textAlign: TextAlign.center),
          if (acao != null) ...[const SizedBox(height: Espaco.m), acao!],
        ],
      ),
    );
  }
}

/// Barra de confiança com rótulo textual (Alta/Média/Baixa) e percentual.
class BarraConfianca extends StatelessWidget {
  const BarraConfianca({super.key, required this.valor, required this.rotulo});
  final double valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Nível de confiança $rotulo, ${percentual(valor)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confiança: $rotulo (${percentual(valor)})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Espaco.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: valor, minHeight: 10),
          ),
        ],
      ),
    );
  }
}

/// Lista com marcadores (evidências, limitações).
class ListaMarcadores extends StatelessWidget {
  const ListaMarcadores(this.itens, {super.key, this.icone = Icons.circle});
  final List<String> itens;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in itens)
          Padding(
            padding: const EdgeInsets.only(bottom: Espaco.p),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 6), child: Icon(icone, size: 8)),
                const SizedBox(width: Espaco.p),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Centraliza o conteúdo e limita a largura em telas grandes (tablet, web).
class LarguraMaxima extends StatelessWidget {
  const LarguraMaxima({super.key, required this.child, this.maximo = 900});
  final Widget child;
  final double maximo;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maximo),
        child: child,
      ),
    );
  }
}

/// Grade responsiva: 1 coluna no celular, 2 a partir de 600 px, 3 a partir de 900 px.
class GradeResponsiva extends StatelessWidget {
  const GradeResponsiva({super.key, required this.filhos});
  final List<Widget> filhos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricoes) {
        final colunas = restricoes.maxWidth >= 900 ? 3 : (restricoes.maxWidth >= 600 ? 2 : 1);
        final largura = (restricoes.maxWidth - (colunas - 1) * Espaco.m) / colunas;
        return Wrap(
          spacing: Espaco.m,
          runSpacing: Espaco.m,
          children: [for (final f in filhos) SizedBox(width: largura, child: f)],
        );
      },
    );
  }
}
