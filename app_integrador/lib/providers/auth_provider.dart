// gerencia o estado de autenticação em toda a aplicação
// usa ChangeNotifier: qdo o estado muda, as telas q "ouvem" esse provider
// são reconstruídas automaticamente pelo context.watch<AuthProvider>()
//
// ciclo de vida:
//   login() e cadastrar() são async — enquanto esperam a resp http,
//   a thread da ui fica livre p/ responder a toques e animações.
//   qdo a future completa, notifyListeners() avisa a ui p/ atualizar.

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;     // jwt do usuário logado (null = n logado)
  String? _email;     // e-mail do usuário atual
  bool _carregando = false; // true enquanto aguarda resposta da api
  String? _erro;      // mensagem de erro p/ exibir na tela

  // getters — somente leitura fora do provider (sem setters públicos)
  // assim ninguém altera o estado diretamente, só pelo provider
  String? get token      => _token;
  String? get email      => _email;
  bool    get carregando => _carregando;
  String? get erro       => _erro;
  bool    get logado     => _token != null; // true se tem token

  // chamado ao iniciar o app — tenta restaurar sessão salva no dispositivo
  Future<void> inicializar() async {
    _token = await AuthService.getToken(); // lê do SharedPreferences
    _email = await AuthService.getEmail();
    notifyListeners(); // avisa a ui q o estado pode ter mudado
  }

  // faz login: chama a api, salva o token e notifica a ui
  Future<void> login(String email, String senha) async {
    _setCarregando(true);
    try {
      _token = await ApiService.login(email, senha);
      _email = email;
      await AuthService.salvarSessao(_token!, email); // persiste no dispositivo
      _erro = null;
    } catch (e) {
      // remove o prefixo "Exception: " q o dart adiciona automaticamente
      _erro = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setCarregando(false); // sempre desativa o loading, mesmo c/ erro
    }
  }

  // cadastra novo usuário e já faz login automaticamente se der certo
  Future<void> cadastrar(String email, String senha) async {
    _setCarregando(true);
    try {
      _token = await ApiService.cadastrar(email, senha);
      _email = email;
      await AuthService.salvarSessao(_token!, email);
      _erro = null;
    } catch (e) {
      _erro = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setCarregando(false);
    }
  }

  // limpa o token, e-mail e a sessão salva — desconecta o usuário
  Future<void> logout() async {
    await AuthService.logout(); // remove do SharedPreferences
    _token = null;
    _email = null;
    _erro  = null;
    notifyListeners();
  }

  // limpa a mensagem de erro — chamado antes de tentar login/cadastro novamente
  void limparErro() {
    _erro = null;
    notifyListeners();
  }

  // helper interno p/ atualizar o estado de loading e notificar a ui
  void _setCarregando(bool valor) {
    _carregando = valor;
    notifyListeners();
  }
}
