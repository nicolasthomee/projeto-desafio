// persiste o token jwt usando SharedPreferences (armazenamento local do app)
// o token sobrevive ao fechamento do app — o usuário n precisa logar
// toda vez q abre o aplicativo

import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // chaves usadas p/ salvar/recuperar os valores no SharedPreferences
  static const _keyToken = 'jwt_token';
  static const _keyEmail = 'user_email';

  // salva o token e o e-mail após login/cadastro bem-sucedido
  static Future<void> salvarSessao(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyEmail, email);
  }

  // recupera o token salvo — retorna null se n houver sessão
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // recupera o e-mail do usuário logado atualmente
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  // verifica se há uma sessão ativa — true se o token existe e n está vazio
  static Future<bool> estaLogado() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // remove o token e o e-mail do armazenamento — efetua o logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyEmail);
  }
}
