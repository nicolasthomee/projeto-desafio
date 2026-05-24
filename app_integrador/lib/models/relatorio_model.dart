// modelo imutável das estatísticas agregadas do período selecionado
// retornado pelo endpoint GET /relatorios da api

class RelatorioModel {
  final double mediaPecas;          // média de peças produzidas por dia
  final int maximoPecas;            // dia com maior produção no período
  final int minimoPecas;            // dia com menor produção no período
  final int totalDias;              // qtd de dias c/ dados no período (0 = sem dados)
  final double mediaTempoParadoSeg; // média de segundos parado por dia
  final int totalAlertas;           // soma de alertas no período inteiro

  const RelatorioModel({
    required this.mediaPecas,
    required this.maximoPecas,
    required this.minimoPecas,
    required this.totalDias,
    required this.mediaTempoParadoSeg,
    required this.totalAlertas,
  });

  // converte o json da api p/ um RelatorioModel
  // usa (json['x'] as num).toDouble() pq a api pode retornar int ou double
  factory RelatorioModel.fromJson(Map<String, dynamic> json) {
    return RelatorioModel(
      mediaPecas: (json['media_pecas'] as num).toDouble(),
      maximoPecas: json['maximo_pecas'] as int,
      minimoPecas: json['minimo_pecas'] as int,
      totalDias: json['total_dias'] as int,
      mediaTempoParadoSeg: (json['media_tempo_parado_seg'] as num).toDouble(),
      totalAlertas: json['total_alertas'] as int,
    );
  }
}
