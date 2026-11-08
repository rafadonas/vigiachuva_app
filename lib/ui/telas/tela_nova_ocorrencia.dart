import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/tema.dart';
import '../../core/territorio.dart';
import '../../data/modelos/ocorrencia.dart';
import '../../dominio/validadores.dart';
import '../../estado/ocorrencias_controller.dart';
import '../../estado/preferencias_controller.dart';
import '../componentes/componentes.dart';

/// Formulário de relato do cidadão, com validação e consentimento explícito.
class TelaNovaOcorrencia extends StatefulWidget {
  const TelaNovaOcorrencia({super.key});

  @override
  State<TelaNovaOcorrencia> createState() => _TelaNovaOcorrenciaState();
}

class _TelaNovaOcorrenciaState extends State<TelaNovaOcorrencia> {
  // Estado LOCAL do formulário: só existe enquanto a tela está aberta.
  final _formulario = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  String? _regiaoId;
  CategoriaOcorrencia? _categoria;
  NivelAgua? _nivel;
  bool _confirmaAnonimo = false;
  bool _enviando = false;

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final valido = _formulario.currentState!.validate();
    if (!valido) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confira os campos destacados em vermelho.')));
      return;
    }
    setState(() => _enviando = true);
    try {
      await context.read<OcorrenciasController>().adicionar(
        regiaoId: _regiaoId!,
        categoria: _categoria!,
        nivelAgua: _nivel!,
        descricao: _descricao.text,
      );
    } on Object catch (erro) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível salvar o relato ($erro). Tente de novo.')));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relato registrado. Obrigado por ajudar sua comunidade!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferenciasController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Novo relato')),
      body: SafeArea(
        child: LarguraMaxima(
          maximo: 640,
          child: !prefs.podeEnviarRelatos
              ? ListView(
                  padding: const EdgeInsets.all(Espaco.m),
                  children: [
                    EstadoVazio(
                      icone: Icons.privacy_tip_outlined,
                      titulo: 'Consentimento necessário',
                      mensagem: 'Para enviar relatos, autorize o uso anônimo dos seus relatos. Você pode revogar quando quiser em Ajustes.',
                      acao: FilledButton(onPressed: () => prefs.definirConsentimento(true), child: const Text('Autorizar uso anônimo')),
                    ),
                  ],
                )
              : Form(
                  key: _formulario,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    padding: const EdgeInsets.all(Espaco.m),
                    children: [
                      const Text('Não informe nome, telefone, e-mail ou número de casa: o relato descreve o local, não pessoas.'),
                      const SizedBox(height: Espaco.m),
                      DropdownButtonFormField<String>(
                        initialValue: _regiaoId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Região *', prefixIcon: Icon(Icons.place_outlined)),
                        items: [for (final r in Territorio.regioes) DropdownMenuItem(value: r.id, child: Text(r.nome))],
                        onChanged: (v) => setState(() => _regiaoId = v),
                        validator: (v) => validarSelecao(v, 'a região'),
                      ),
                      const SizedBox(height: Espaco.m),
                      DropdownButtonFormField<CategoriaOcorrencia>(
                        initialValue: _categoria,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'O que está acontecendo? *',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: [for (final c in CategoriaOcorrencia.values) DropdownMenuItem(value: c, child: Text(c.rotulo))],
                        onChanged: (v) => setState(() => _categoria = v),
                        validator: (v) => validarSelecao(v, 'o tipo de ocorrência'),
                      ),
                      const SizedBox(height: Espaco.m),
                      DropdownButtonFormField<NivelAgua>(
                        initialValue: _nivel,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Nível da água *', prefixIcon: Icon(Icons.water)),
                        items: [for (final n in NivelAgua.values) DropdownMenuItem(value: n, child: Text(n.rotulo))],
                        onChanged: (v) => setState(() => _nivel = v),
                        validator: (v) => validarSelecao(v, 'o nível da água'),
                      ),
                      const SizedBox(height: Espaco.m),
                      TextFormField(
                        controller: _descricao,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          labelText: 'Descrição *',
                          hintText: 'Ex.: rua da feira alagada há 30 minutos, carros não passam.',
                          alignLabelWithHint: true,
                        ),
                        validator: validarDescricao,
                      ),
                      FormField<bool>(
                        initialValue: _confirmaAnonimo,
                        validator: (v) => v == true ? null : 'Confirme que o relato não tem dados pessoais.',
                        builder: (campo) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              value: _confirmaAnonimo,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text('Confirmo que o relato não contém dados pessoais.'),
                              onChanged: (v) {
                                setState(() => _confirmaAnonimo = v ?? false);
                                campo.didChange(v);
                              },
                            ),
                            if (campo.hasError) Text(campo.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ],
                        ),
                      ),
                      const SizedBox(height: Espaco.m),
                      FilledButton.icon(
                        onPressed: _enviando ? null : _enviar,
                        icon: _enviando
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.send),
                        label: const Text('Enviar relato'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
