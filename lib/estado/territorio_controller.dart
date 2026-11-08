import 'package:flutter/foundation.dart';

import '../data/modelos/alerta.dart';
import '../data/modelos/ponto_serie.dart';
import '../data/modelos/previsao_chuva.dart';
import '../data/repositorio_territorio.dart';
import '../data/servicos/dados_sinteticos.dart';
import '../dominio/indicadores.dart';
import '../dominio/motor_alertas.dart';
import 'ocorrencias_controller.dart';
import 'preferencias_controller.dart';

enum EstadoCarga { inicial, carregando, pronto, erro }

/// Estado GLOBAL do território: previsão de chuva, séries sintéticas e alertas.
/// Compartilhado pelo Início, pelos painéis, pela lista e pelo detalhe dos alertas.
/// Recalcula os alertas sempre que os limiares ou os relatos mudam.
class TerritorioController extends ChangeNotifier {
  TerritorioController({
    required RepositorioTerritorio repositorio,
    required DadosSinteticos sinteticos,
    required PreferenciasController preferencias,
    required OcorrenciasController ocorrencias,
    MotorAlertas motor = const MotorAlertas(),
    DateTime Function()? relogio,
  }) : _repositorio = repositorio,
       _sinteticos = sinteticos,
       _preferencias = preferencias,
       _ocorrencias = ocorrencias,
       _motor = motor,
       _relogio = relogio ?? DateTime.now {
    _preferencias.addListener(_recalcularAlertas);
    _ocorrencias.addListener(_recalcularAlertas);
  }

  final RepositorioTerritorio _repositorio;
  final DadosSinteticos _sinteticos;
  final PreferenciasController _preferencias;
  final OcorrenciasController _ocorrencias;
  final MotorAlertas _motor;
  final DateTime Function() _relogio;

  EstadoCarga _estado = EstadoCarga.inicial;
  PrevisaoChuva? _previsao;
  bool _doCache = false;
  String? _mensagemErro;
  List<PontoSerie> _nivel = [];
  List<PontoSerie> _umidade = [];
  List<Alerta> _alertas = [];
  DateTime _agora = DateTime.now();

  EstadoCarga get estado => _estado;
  PrevisaoChuva? get previsao => _previsao;
  bool get offline => _doCache;
  String? get mensagemErro => _mensagemErro;
  List<PontoSerie> get nivelCorrego => _nivel;
  List<PontoSerie> get umidadeSolo => _umidade;
  List<Alerta> get alertas => _alertas;
  DateTime get agora => _agora;
  BeneficioSocial get beneficioSocial => BeneficioSocial.calcular(_alertas, _ocorrencias.todas, _agora);

  Alerta? alertaPorId(String id) {
    for (final a in _alertas) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<Alerta> alertasDoIndicador(String indicadorId) => _alertas.where((a) => a.indicadorId == indicadorId).toList();

  Future<void> carregar() async {
    _estado = EstadoCarga.carregando;
    _mensagemErro = null;
    notifyListeners();

    try {
      final resultado = await _repositorio.obterPrevisao();
      _agora = _relogio();
      _previsao = resultado.previsao;
      _doCache = resultado.doCache;
      _mensagemErro = resultado.erro;
      _nivel = _sinteticos.nivelCorrego(_previsao, _agora);
      _umidade = _sinteticos.umidadeSolo(_previsao, _agora);
      _calcular();
      _estado = _previsao == null ? EstadoCarga.erro : EstadoCarga.pronto;
    } on Object catch (erro) {
      // Nunca deixa a tela presa em "carregando": qualquer falha inesperada vira estado de erro.
      _estado = EstadoCarga.erro;
      _mensagemErro = 'Falha inesperada ao carregar os dados ($erro).';
    } finally {
      notifyListeners();
    }
  }

  void _calcular() {
    _alertas = _motor.gerar(
      chuva: _previsao,
      chuvaDoCache: _doCache,
      nivelCorrego: _nivel,
      umidadeSolo: _umidade,
      ocorrencias: _ocorrencias.todas,
      limiares: _preferencias.limiares,
      agora: _agora,
    );
  }

  void _recalcularAlertas() {
    if (_estado == EstadoCarga.inicial || _estado == EstadoCarga.carregando) return;
    _calcular();
    notifyListeners();
  }

  @override
  void dispose() {
    _preferencias.removeListener(_recalcularAlertas);
    _ocorrencias.removeListener(_recalcularAlertas);
    super.dispose();
  }
}
