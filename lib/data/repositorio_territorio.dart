import 'modelos/previsao_chuva.dart';
import 'servicos/armazenamento_local.dart';
import 'servicos/open_meteo_servico.dart';

/// Resultado da busca de previsão: dado novo, dado do cache (offline) ou erro sem dado.
class ResultadoPrevisao {
  const ResultadoPrevisao({this.previsao, this.doCache = false, this.erro});

  final PrevisaoChuva? previsao;
  final bool doCache;
  final String? erro;
}

/// Decide de onde vem a previsão: tenta a internet; se falhar, usa o último dado salvo.
class RepositorioTerritorio {
  RepositorioTerritorio(this._api, this._local);

  final OpenMeteoServico _api;
  final ArmazenamentoLocal _local;

  Future<ResultadoPrevisao> obterPrevisao() async {
    try {
      final nova = await _api.buscarPrevisao();
      await _local.salvarPrevisao(nova);
      return ResultadoPrevisao(previsao: nova);
    } on FalhaFonteExterna catch (falha) {
      final cache = _local.lerPrevisao();
      if (cache != null) {
        return ResultadoPrevisao(previsao: cache, doCache: true, erro: falha.mensagem);
      }
      return ResultadoPrevisao(erro: falha.mensagem);
    }
  }
}
