import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/rotas.dart';
import '../../estado/territorio_controller.dart';
import 'aba_ajustes.dart';
import 'aba_alertas.dart';
import 'aba_inicio.dart';
import 'aba_relatos.dart';

/// Estrutura principal com navegação inferior (Início, Alertas, Relatos, Ajustes).
class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _aba = 0; // estado LOCAL da navegação

  static const _titulos = ['VigiaChuva', 'Alertas', 'Relatos da comunidade', 'Ajustes'];

  @override
  Widget build(BuildContext context) {
    final totalAlertas = context.select<TerritorioController, int>((t) => t.alertas.length);
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_aba]),
        actions: [
          if (_aba == 0)
            IconButton(
              tooltip: 'Atualizar dados',
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<TerritorioController>().carregar(),
            ),
          IconButton(
            tooltip: 'Sobre os dados e limitações',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, Rotas.sobreDados),
          ),
        ],
      ),
      body: IndexedStack(
        index: _aba,
        children: [
          AbaInicio(irParaAlertas: () => setState(() => _aba = 1)),
          const AbaAlertas(),
          const AbaRelatos(),
          const AbaAjustes(),
        ],
      ),
      floatingActionButton: _aba == 2
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, Rotas.novaOcorrencia),
              icon: const Icon(Icons.add),
              label: const Text('Novo relato'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Início'),
          NavigationDestination(
            icon: Badge.count(count: totalAlertas, isLabelVisible: totalAlertas > 0, child: const Icon(Icons.notifications_outlined)),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Alertas',
            tooltip: '$totalAlertas alertas ativos',
          ),
          const NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'Relatos'),
          const NavigationDestination(icon: Icon(Icons.tune), label: 'Ajustes'),
        ],
      ),
    );
  }
}
