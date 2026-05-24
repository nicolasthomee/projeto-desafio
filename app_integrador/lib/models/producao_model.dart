// modelo imutável do registro de produção em tempo real
// todos os campos são final — o objeto n pode ser alterado após criação
// fromJson é um factory constructor: cria a instância diretamente do json da api

class ProducaoModel {
  final int id;
  final int contador;       // total de peças contadas pelo sensor ir
  final String status;      // estado da linha: RODANDO | PARADA | ALERTA | STANDBY | ENCERRADO
  final String alerta;      // tipo de alerta atual: NORMAL | SEM_PRODUCAO | STANDBY
  final int tempoParado;    // segundos acumulados c/ a linha parada
  final DateTime? criadoEm; // timestamp do registro (nullable pq pode vir null da api)

  // construtor const: permite criar instâncias em tempo de compilação
  // reforça q o objeto é imutável desde sua criação
  const ProducaoModel({
    required this.id,
    required this.contador,
    required this.status,
    required this.alerta,
    required this.tempoParado,
    this.criadoEm,
  });

  // converte o json da api p/ um objeto ProducaoModel
  // ex de json: {"id": 1, "contador": 42, "status": "RODANDO", ...}
  factory ProducaoModel.fromJson(Map<String, dynamic> json) {
    return ProducaoModel(
      id: json['id'] as int,
      contador: json['contador'] as int,
      status: json['status'] as String,
      alerta: json['alerta'] as String,
      tempoParado: json['tempo_parado'] as int,
      // DateTime.tryParse retorna null se a string n for uma data válida
      criadoEm: json['criado_em'] != null
          ? DateTime.tryParse(json['criado_em'] as String)
          : null,
    );
  }

  // retorna o emoji correspondente ao status p/ exibir no banner do dashboard
  String get statusEmoji {
    switch (status) {
      case 'RODANDO':   return '🟢';
      case 'PARADA':    return '🔴';
      case 'ALERTA':    return '🚨';
      case 'STANDBY':   return '🔵';
      case 'ENCERRADO': return '⚫';
      default:          return '⚪';
    }
  }
}
