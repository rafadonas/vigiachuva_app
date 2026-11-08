import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/tema.dart';
import '../../core/formatacao.dart';
import '../../data/modelos/limiares.dart';
import '../../dominio/validadores.dart';
import '../../estado/preferencias_controller.dart';
import '../componentes/componentes.dart';

/// Formulário de configuração dos limiares de alerta, com validação de faixa e de ordem.
class TelaLimiares extends StatefulWidget {
  const TelaLimiares({super.key});

  @override
  State<TelaLimiares> createState() => _TelaLimiaresState();
}

class _TelaLimiaresState extends State<TelaLimiares> {
  final _formulario = GlobalKey<FormState>();
  late final Map<String, List<TextEditingController>> _campos;

  static const _grupos = [
    ('chuva', 'Chuva (mm/h)', 200.0),
    ('nivel', 'Nível do córrego (m)', 10.0),
    ('umidade', 'Umidade do solo (%)', 100.0),
  ];

  @override
  void initState() {
    super.initState();
    final l = context.read<PreferenciasController>().limiares;
    List<TextEditingController> c(Limiares x) => [
      TextEditingController(text: decimal(x.atencao)),
      TextEditingController(text: decimal(x.alerta)),
      TextEditingController(text: decimal(x.critico)),
    ];
    _campos = {'chuva': c(l.chuvaMmH), 'nivel': c(l.nivelCorregoM), 'umidade': c(l.umidadeSoloPct)};
  }

  @override
  void dispose() {
    for (final lista in _campos.values) {
      for (final c in lista) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Limiares _ler(String grupo) {
    final v = _campos[grupo]!.map((c) => lerDecimal(c.text)!).toList();
    return Limiares(v[0], v[1], v[2]);
  }

  Future<void> _salvar() async {
    if (!_formulario.currentState!.validate()) return;
    await context.read<PreferenciasController>().definirLimiares(
      ConfiguracaoLimiares(chuvaMmH: _ler('chuva'), nivelCorregoM: _ler('nivel'), umidadeSoloPct: _ler('umidade')),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Limiares salvos. Os alertas foram recalculados.')));
    Navigator.pop(context);
  }

  Future<void> _restaurar() async {
    await context.read<PreferenciasController>().restaurarLimiaresPadrao();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Limiares padrão restaurados.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Limiares de alerta')),
      body: SafeArea(
        child: LarguraMaxima(
          maximo: 640,
          child: Form(
            key: _formulario,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(Espaco.m),
              children: [
                const Text(
                  'Um alerta é emitido quando a previsão atinge o limite. Os valores padrão são referências do protótipo, '
                  'não calibrações oficiais: ajuste com a Defesa Civil local.',
                ),
                for (final (id, titulo, maximo) in _grupos) ...[
                  TituloSecao(titulo),
                  for (final (i, nome) in [(0, 'ATENÇÃO'), (1, 'ALERTA'), (2, 'CRÍTICO')]) ...[
                    TextFormField(
                      controller: _campos[id]![i],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'Limite de $nome'),
                      validator: (texto) {
                        final erro = validarLimiar(texto, maximo: maximo);
                        if (erro != null) return erro;
                        if (i == 2) {
                          final v = _campos[id]!.map((c) => lerDecimal(c.text)).toList();
                          return validarOrdem(v[0], v[1], v[2]);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Espaco.p),
                  ],
                ],
                const SizedBox(height: Espaco.m),
                FilledButton.icon(onPressed: _salvar, icon: const Icon(Icons.save_outlined), label: const Text('Salvar limiares')),
                const SizedBox(height: Espaco.p),
                TextButton(onPressed: _restaurar, child: const Text('Restaurar valores padrão')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
