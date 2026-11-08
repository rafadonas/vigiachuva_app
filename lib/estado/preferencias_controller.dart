import 'package:flutter/foundation.dart';

import '../data/modelos/limiares.dart';
import '../data/servicos/armazenamento_local.dart';

/// Estado GLOBAL de preferências: tema, contraste, consentimento e limiares.
/// Tudo é persistido localmente e sobrevive ao fechar o app.
class PreferenciasController extends ChangeNotifier {
  PreferenciasController(this._local)
    : _temaEscuro = _local.temaEscuro,
      _altoContraste = _local.altoContraste,
      _consentimento = _local.consentimento,
      _limiares = _local.lerLimiares();

  final ArmazenamentoLocal _local;
  bool _temaEscuro;
  bool _altoContraste;
  bool? _consentimento;
  ConfiguracaoLimiares _limiares;

  bool get temaEscuro => _temaEscuro;
  bool get altoContraste => _altoContraste;

  /// null = a pessoa ainda não respondeu à tela de consentimento.
  bool? get consentimento => _consentimento;
  bool get podeEnviarRelatos => _consentimento == true;
  ConfiguracaoLimiares get limiares => _limiares;

  Future<void> definirTemaEscuro(bool valor) async {
    _temaEscuro = valor;
    notifyListeners();
    await _local.salvarTemaEscuro(valor);
  }

  Future<void> definirAltoContraste(bool valor) async {
    _altoContraste = valor;
    notifyListeners();
    await _local.salvarAltoContraste(valor);
  }

  Future<void> definirConsentimento(bool valor) async {
    _consentimento = valor;
    notifyListeners();
    await _local.salvarConsentimento(valor);
  }

  Future<void> definirLimiares(ConfiguracaoLimiares novos) async {
    // Última barreira: a tela já valida, mas o estado global nunca aceita limiares fora de ordem.
    if (!novos.chuvaMmH.valido || !novos.nivelCorregoM.valido || !novos.umidadeSoloPct.valido) {
      throw ArgumentError('Limiares inválidos: é preciso 0 ≤ ATENÇÃO < ALERTA < CRÍTICO.');
    }
    _limiares = novos;
    notifyListeners();
    await _local.salvarLimiares(novos);
  }

  Future<void> restaurarLimiaresPadrao() => definirLimiares(const ConfiguracaoLimiares());
}
