import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/rotas.dart';
import '../../app/tema.dart';
import '../../core/formatacao.dart';
import '../../estado/ocorrencias_controller.dart';
import '../../estado/preferencias_controller.dart';
import '../componentes/componentes.dart';

/// Preferências de aparência, limiares de alerta e privacidade.
class AbaAjustes extends StatelessWidget {
  const AbaAjustes({super.key});

  Future<void> _confirmarApagar(BuildContext context) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar seus relatos?'),
        content: const Text('Todos os relatos feitos neste aparelho serão apagados. Isso não pode ser desfeito.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (confirma == true && context.mounted) {
      await context.read<OcorrenciasController>().apagarMeusRelatos();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seus relatos foram apagados.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferenciasController>();
    final meusRelatos = context.watch<OcorrenciasController>().doUsuario.length;
    final l = prefs.limiares;
    return ListView(
      padding: const EdgeInsets.all(Espaco.m),
      children: [
        LarguraMaxima(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloSecao('Aparência e acessibilidade'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Tema escuro'),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      value: prefs.temaEscuro,
                      onChanged: prefs.definirTemaEscuro,
                    ),
                    SwitchListTile(
                      title: const Text('Alto contraste'),
                      subtitle: const Text('Preto, branco e amarelo, com bordas reforçadas'),
                      secondary: const Icon(Icons.contrast),
                      value: prefs.altoContraste,
                      onChanged: prefs.definirAltoContraste,
                    ),
                    const ListTile(
                      leading: Icon(Icons.text_increase),
                      title: Text('Tamanho do texto'),
                      subtitle: Text('O app segue o tamanho de fonte definido nas configurações do aparelho.'),
                    ),
                  ],
                ),
              ),
              const TituloSecao('Limiares de alerta'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Configurar limiares'),
                  subtitle: Text(
                    'Chuva: ${decimal(l.chuvaMmH.atencao)} / ${decimal(l.chuvaMmH.alerta)} / ${decimal(l.chuvaMmH.critico)} mm/h\n'
                    'Córrego: ${decimal(l.nivelCorregoM.atencao)} / ${decimal(l.nivelCorregoM.alerta)} / ${decimal(l.nivelCorregoM.critico)} m\n'
                    'Solo: ${decimal(l.umidadeSoloPct.atencao)} / ${decimal(l.umidadeSoloPct.alerta)} / ${decimal(l.umidadeSoloPct.critico)} %',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, Rotas.limiares),
                ),
              ),
              const TituloSecao('Privacidade'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Consentimento para enviar relatos'),
                      subtitle: const Text('Relatos são anônimos: só região, tipo, nível da água, descrição e horário.'),
                      secondary: const Icon(Icons.privacy_tip_outlined),
                      value: prefs.podeEnviarRelatos,
                      onChanged: prefs.definirConsentimento,
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text('Apagar meus relatos ($meusRelatos)'),
                      subtitle: const Text('Remove todos os relatos feitos neste aparelho'),
                      enabled: meusRelatos > 0,
                      onTap: meusRelatos > 0 ? () => _confirmarApagar(context) : null,
                    ),
                  ],
                ),
              ),
              const TituloSecao('Sobre'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Dados, métricas e limitações'),
                  subtitle: const Text('Fontes, como os alertas são gerados e quando não confiar'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, Rotas.sobreDados),
                ),
              ),
              const SizedBox(height: Espaco.g),
            ],
          ),
        ),
      ],
    );
  }
}
