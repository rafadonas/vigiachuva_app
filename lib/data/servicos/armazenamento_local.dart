import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/limiares.dart';
import '../modelos/ocorrencia.dart';
import '../modelos/previsao_chuva.dart';

/// Persistência local (shared_preferences): cache da previsão, relatos, limiares e preferências.
/// É o que mantém o app útil sem conexão.
class ArmazenamentoLocal {
  ArmazenamentoLocal(this._prefs);

  final SharedPreferences _prefs;

  static const _chavePrevisao = 'cache_previsao_chuva';
  static const _chaveOcorrencias = 'ocorrencias_usuario';
  static const _chaveLimiares = 'limiares';
  static const _chaveTemaEscuro = 'tema_escuro';
  static const _chaveAltoContraste = 'alto_contraste';
  static const _chaveConsentimento = 'consentimento'; // null = ainda não respondeu

  static Future<ArmazenamentoLocal> abrir() async => ArmazenamentoLocal(await SharedPreferences.getInstance());

  PrevisaoChuva? lerPrevisao() {
    final texto = _prefs.getString(_chavePrevisao);
    if (texto == null) return null;
    try {
      return PrevisaoChuva.fromJson(jsonDecode(texto) as Map<String, dynamic>);
    } on Object {
      return null; // cache corrompido: ignora e busca de novo
    }
  }

  Future<void> salvarPrevisao(PrevisaoChuva previsao) => _prefs.setString(_chavePrevisao, jsonEncode(previsao.toJson()));

  List<Ocorrencia> lerOcorrencias() {
    final texto = _prefs.getString(_chaveOcorrencias);
    if (texto == null) return [];
    try {
      return (jsonDecode(texto) as List).map((e) => Ocorrencia.fromJson(e as Map<String, dynamic>)).toList();
    } on Object {
      return [];
    }
  }

  Future<void> salvarOcorrencias(List<Ocorrencia> lista) =>
      _prefs.setString(_chaveOcorrencias, jsonEncode(lista.map((o) => o.toJson()).toList()));

  ConfiguracaoLimiares lerLimiares() {
    final texto = _prefs.getString(_chaveLimiares);
    if (texto == null) return const ConfiguracaoLimiares();
    try {
      return ConfiguracaoLimiares.fromJson(jsonDecode(texto) as Map<String, dynamic>);
    } on Object {
      return const ConfiguracaoLimiares();
    }
  }

  Future<void> salvarLimiares(ConfiguracaoLimiares l) => _prefs.setString(_chaveLimiares, jsonEncode(l.toJson()));

  bool get temaEscuro => _prefs.getBool(_chaveTemaEscuro) ?? false;
  Future<void> salvarTemaEscuro(bool v) => _prefs.setBool(_chaveTemaEscuro, v);

  bool get altoContraste => _prefs.getBool(_chaveAltoContraste) ?? false;
  Future<void> salvarAltoContraste(bool v) => _prefs.setBool(_chaveAltoContraste, v);

  bool? get consentimento => _prefs.getBool(_chaveConsentimento);
  Future<void> salvarConsentimento(bool v) => _prefs.setBool(_chaveConsentimento, v);
}
