// centraliza todas as chamadas http p/ a api fastapi
// separa a lógica de rede da ui — a tela n sabe como os dados chegam
//
// importante: troque BASE_URL pelo ip do notebook na rede local.
// p/ descobrir: no windows, abra o cmd e execute "ipconfig"

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/producao_model.dart';
import '../models/historico_model.dart';
import '../models/relatorio_model.dart';

class ApiService {
  // ip e porta da fastapi rodando no notebook
  // altere aqui se mudar de rede ou de máquina
  static const String baseUrl = 'http://192.168.3.135:8000';

  // se a api n responder em 10s, lança TimeoutException — evita esperar indefinidamente
  static const Duration _timeout = Duration(seconds: 10);

  // monta os headers c/ o jwt bearer token p/ autenticar os requests protegidos
  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // extrai a mensagem de erro do corpo da resposta
  // se o corpo não for JSON válido (ex: 500 retorna HTML), usa o fallback
  static String _mensagemErro(http.Response response, {required String fallback}) {
    if (response.statusCode == 500) return 'Erro interno do servidor (500)';
    try {
      final body = jsonDecode(response.body);
      return body['detail']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // ── autenticação ───────────────────────────────────────────────────────────

  // cadastra novo usuário na api e retorna o jwt após login automático
  static Future<String> cadastrar(String email, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/cadastro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    ).timeout(_timeout);

    if (response.statusCode == 201) {
      return await login(email, senha);
    }

    throw Exception(_mensagemErro(response, fallback: 'Erro ao cadastrar'));
  }

  // faz login e retorna o jwt — armazenado pelo AuthService p/ requests futuros
  static Future<String> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'] as String;
    }

    throw Exception(_mensagemErro(response, fallback: 'E-mail ou senha incorretos'));
  }

  // ── produção ───────────────────────────────────────────────────────────────

  // busca o registro mais recente de produção — chamado a cada 5s pelo polling
  static Future<ProducaoModel> getProducaoAtual(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/producao'),
      headers: _headers(token),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return ProducaoModel.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 401) throw Exception('Sessão expirada');
    throw Exception('Erro ao buscar produção: ${response.statusCode}');
  }

  // ── histórico ──────────────────────────────────────────────────────────────

  // busca o histórico diário; dataInicio e dataFim são opcionais
  // se n passados, retorna td o histórico disponível
  static Future<List<HistoricoModel>> getHistorico(
    String token, {
    String? dataInicio, // formato: "yyyy-MM-dd"
    String? dataFim,
  }) async {
    final params = <String, String>{};
    if (dataInicio != null) params['data_inicio'] = dataInicio;
    if (dataFim != null)    params['data_fim']    = dataFim;

    // adiciona os filtros como query params na url: /historico?data_inicio=...
    final uri = Uri.parse('$baseUrl/historico').replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: _headers(token),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      final List<dynamic> lista = jsonDecode(response.body);
      // mapeia cada json da lista p/ um objeto HistoricoModel
      return lista.map((e) => HistoricoModel.fromJson(e)).toList();
    }
    if (response.statusCode == 401) throw Exception('Sessão expirada');
    throw Exception('Erro ao buscar histórico: ${response.statusCode}');
  }

  // ── relatórios ─────────────────────────────────────────────────────────────

  // busca as estatísticas agregadas do período; tbm suporta filtros de data
  static Future<RelatorioModel> getRelatorio(
    String token, {
    String? dataInicio,
    String? dataFim,
  }) async {
    final params = <String, String>{};
    if (dataInicio != null) params['data_inicio'] = dataInicio;
    if (dataFim != null)    params['data_fim']    = dataFim;

    final uri = Uri.parse('$baseUrl/relatorios').replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: _headers(token),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return RelatorioModel.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 401) throw Exception('Sessão expirada');
    throw Exception('Erro ao buscar relatório: ${response.statusCode}');
  }

  // ── comando ────────────────────────────────────────────────────────────────

  // envia um comando ao esp32 via api → mqtt
  // a api publica a mensagem no tópico mqtt e o esp32 executa
  static Future<void> enviarComando(String token, String comando) async {
    final response = await http.post(
      Uri.parse('$baseUrl/comando'),
      headers: _headers(token),
      body: jsonEncode({'comando': comando}), // ex: {"comando": "PAUSAR"}
    ).timeout(_timeout);

    if (response.statusCode == 200) return;
    if (response.statusCode == 401) throw Exception('Sessão expirada');
    throw Exception(_mensagemErro(response, fallback: 'Erro ao enviar comando'));
  }
}
