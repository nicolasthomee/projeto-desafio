// modelo imutável do histórico diário de produção
// gerado qdo o comando FECHAR_DIA é enviado ao esp32

class HistoricoModel {
  final int id;
  final String? data;         // data do expediente no formato "yyyy-MM-dd" (nullable)
  final int totalPecas;       // total de peças produzidas no dia
  final int tempoParadoSeg;   // total de segundos c/ a linha parada no dia
  final int totalAlertas;     // qtd de alertas disparados no dia
  final DateTime? criadoEm;   // timestamp de criação do registro

  const HistoricoModel({
    required this.id,
    this.data,
    required this.totalPecas,
    required this.tempoParadoSeg,
    required this.totalAlertas,
    this.criadoEm,
  });

  // converte o json da api p/ um objeto HistoricoModel
  factory HistoricoModel.fromJson(Map<String, dynamic> json) {
    return HistoricoModel(
      id: json['id'] as int,
      data: json['data'] as String?,
      totalPecas: json['total_pecas'] as int,
      tempoParadoSeg: json['tempo_parado_seg'] as int,
      totalAlertas: json['total_alertas'] as int,
      criadoEm: json['criado_em'] != null
          ? DateTime.tryParse(json['criado_em'] as String)
          : null,
    );
  }

  // converte os segundos p/ formato legível: "2h 15min" ou "45min"
  // usado na lista de cards do histórico
  String get tempoParadoFormatado {
    final horas   = tempoParadoSeg ~/ 3600;    // divisão inteira p/ horas
    final minutos = (tempoParadoSeg % 3600) ~/ 60; // resto em minutos
    if (horas > 0) return '${horas}h ${minutos}min';
    return '${minutos}min';
  }
}
