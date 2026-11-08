import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/rotas.dart';
import '../../app/tema.dart';
import '../../estado/preferencias_controller.dart';
import '../componentes/componentes.dart';

/// Consentimento explícito na primeira abertura (LGPD): explica quais dados o app usa.
class TelaConsentimento extends StatefulWidget {
  const TelaConsentimento({super.key});

  @override
  State<TelaConsentimento> createState() => _TelaConsentimentoState();
}

class _TelaConsentimentoState extends State<TelaConsentimento> {
  bool _li = false; // estado LOCAL: só esta tela precisa dele

  Future<void> _responder(bool aceita) async {
    await context.read<PreferenciasController>().definirConsentimento(aceita);
    if (!mounted) return;
    // initialRoute '/consentimento' empilha '/' por baixo; limpamos a pilha
    // para a tela principal não exibir um botão de voltar para o consentimento.
    Navigator.of(context).pushNamedAndRemoveUntil(Rotas.principal, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LarguraMaxima(
          maximo: 640,
          child: ListView(
            padding: const EdgeInsets.all(Espaco.g),
            children: [
              Icon(Icons.water_drop, size: 56, color: tema.colorScheme.primary, semanticLabel: 'Logotipo VigiaChuva'),
              const SizedBox(height: Espaco.m),
              Semantics(header: true, child: Text('Bem-vindo ao VigiaChuva', style: tema.textTheme.headlineSmall)),
              const SizedBox(height: Espaco.p),
              const Text('Painel que antecipa riscos de chuva forte e alagamento no seu território, para gestores públicos e moradores.'),
              const TituloSecao('Como usamos os dados'),
              const ListaMarcadores([
                'Previsão de chuva: dados públicos da Open-Meteo, sem nenhuma informação sua.',
                'Relatos de ocorrência: guardamos só a região, o tipo do problema, o nível da água, a descrição e o horário. Não pedimos nome, telefone, e-mail nem endereço exato.',
                'Seus relatos ficam salvos neste aparelho e podem ser apagados a qualquer momento em Ajustes > Privacidade.',
                'Nível do córrego e umidade do solo são dados simulados, identificados como tal em todo o app.',
              ], icone: Icons.check),
              const SizedBox(height: Espaco.m),
              const AvisoDecisaoHumana(),
              const SizedBox(height: Espaco.m),
              CheckboxListTile(
                value: _li,
                onChanged: (v) => setState(() => _li = v ?? false),
                title: const Text('Li e concordo com o uso dos meus relatos anônimos para gerar indicadores e alertas.'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: Espaco.m),
              FilledButton(onPressed: _li ? () => _responder(true) : null, child: const Text('Concordo e quero continuar')),
              const SizedBox(height: Espaco.p),
              OutlinedButton(
                onPressed: () => _responder(false),
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('Continuar sem enviar relatos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
