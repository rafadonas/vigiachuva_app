import 'package:flutter/material.dart';

import '../../app/tema.dart';
import '../componentes/componentes.dart';

/// Transparência: fontes, métricas, limitações, vieses e quando as previsões não são confiáveis.
class TelaSobreDados extends StatelessWidget {
  const TelaSobreDados({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dados, métricas e limitações')),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.m),
        children: const [
          LarguraMaxima(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TituloSecao('Fontes'),
                ListaMarcadores([
                  'Chuva (REAL): API pública Open-Meteo, previsão horária para o território. Dados sob licença CC BY 4.0, uso não comercial.',
                  'Nível do córrego e umidade do solo (SIMULADOS): calculados a partir da chuva real por um modelo didático, sem calibração.',
                  'Relatos (do usuário + exemplos fictícios): registrados no app, anônimos, salvos no aparelho.',
                  'Regiões e população: território-piloto fictício.',
                ]),
                TituloSecao('Como os alertas são gerados'),
                ListaMarcadores([
                  'Chuva: o maior valor horário previsto nas próximas 6 h é comparado com os limiares (padrão 10, 30 e 50 mm/h).',
                  'Córrego: duas projeções (tendência das últimas 6 h e modelo de chuva) e a maior é comparada com os limiares (padrão 2,5; 3,2; 3,8 m).',
                  'Solo: umidade prevista para as próximas 6 h comparada com 80%, 90% e 95%.',
                  'Relatos: 2 ou mais relatos graves na mesma região em 24 h geram ATENÇÃO; 4 ou mais, ALERTA.',
                ]),
                TituloSecao('Métricas de confiança'),
                ListaMarcadores([
                  'Chuva: probabilidade de chuva do modelo × antecedência × idade do dado.',
                  'Córrego: no máximo 60% (dado simulado), reduzida quando as duas projeções discordam.',
                  'Relatos: cresce com o número de relatos independentes (máximo de 80%).',
                  'Alta: 70% ou mais · Média: de 40% a 69% · Baixa: abaixo de 40%.',
                ]),
                TituloSecao('Quando as previsões NÃO são confiáveis'),
                ListaMarcadores([
                  'Com menos de 6 horas de histórico, o app não projeta o córrego (o sistema se cala).',
                  'Pancadas de verão muito localizadas podem não aparecer no modelo meteorológico.',
                  'Previsões além de 3 horas e dados salvos há mais de 3 horas (modo offline) têm a confiança reduzida.',
                  'O nível do córrego e a umidade são simulados: servem para demonstrar o fluxo, não para decisões reais.',
                ]),
                TituloSecao('Possíveis vieses'),
                ListaMarcadores([
                  'Subnotificação: regiões com menos acesso ao app geram menos relatos e parecem mais seguras do que são.',
                  'Relatos podem se repetir sobre o mesmo ponto e superestimar um local.',
                  'Os limiares padrão não foram calibrados com o histórico de alagamentos do território.',
                  'O horário segue o fuso de São Paulo; em aparelhos com outro fuso, as horas exibidas podem ficar deslocadas.',
                ]),
                TituloSecao('Privacidade e inclusão'),
                ListaMarcadores([
                  'Sem nome, telefone, e-mail ou endereço exato: só região, tipo, nível da água, descrição e horário.',
                  'Consentimento explícito na primeira abertura, revogável em Ajustes; seus relatos podem ser apagados.',
                  'Tema escuro, alto contraste, suporte a fonte ampliada e descrições para leitores de tela.',
                ]),
                SizedBox(height: Espaco.m),
                AvisoDecisaoHumana(),
                SizedBox(height: Espaco.g),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
