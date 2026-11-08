import 'package:flutter/foundation.dart';

import '../data/modelos/ocorrencia.dart';
import '../data/servicos/armazenamento_local.dart';
import '../data/servicos/dados_sinteticos.dart';

/// Estado GLOBAL dos relatos da comunidade (os do usuário ficam salvos no aparelho).
class OcorrenciasController extends ChangeNotifier {
  OcorrenciasController(this._local, this._sinteticos, {DateTime Function()? relogio}) : _relogio = relogio ?? DateTime.now;

  final ArmazenamentoLocal _local;
  final DadosSinteticos _sinteticos;
  final DateTime Function() _relogio;

  List<Ocorrencia> _doUsuario = [];
  List<Ocorrencia> _exemplos = [];
  bool _carregado = false;

  bool get carregado => _carregado;
  List<Ocorrencia> get doUsuario => List.unmodifiable(_doUsuario);

  /// Todos os relatos (do usuário e de exemplo), do mais recente para o mais antigo.
  List<Ocorrencia> get todas {
    final lista = [..._doUsuario, ..._exemplos];
    lista.sort((a, b) => b.registradaEm.compareTo(a.registradaEm));
    return lista;
  }

  void carregar() {
    _doUsuario = _local.lerOcorrencias();
    _exemplos = _sinteticos.ocorrenciasExemplo(_relogio());
    _carregado = true;
    notifyListeners();
  }

  Future<void> adicionar({
    required String regiaoId,
    required CategoriaOcorrencia categoria,
    required NivelAgua nivelAgua,
    required String descricao,
  }) async {
    final agora = _relogio();
    final nova = Ocorrencia(
      id: 'u-${agora.microsecondsSinceEpoch}',
      regiaoId: regiaoId,
      categoria: categoria,
      nivelAgua: nivelAgua,
      descricao: descricao.trim(),
      registradaEm: agora,
    );
    _doUsuario = [nova, ..._doUsuario];
    notifyListeners();
    await _local.salvarOcorrencias(_doUsuario);
  }

  /// Direito de exclusão: apaga todos os relatos feitos neste aparelho.
  Future<void> apagarMeusRelatos() async {
    _doUsuario = [];
    notifyListeners();
    await _local.salvarOcorrencias(_doUsuario);
  }
}
