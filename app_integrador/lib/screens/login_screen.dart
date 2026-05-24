// tela de login — primeira tela q o usuário vê
// usa glassmorphism: fundo gradiente + card c/ blur + borda branca semitransparente
import 'dart:ui'; // necessário p/ o ImageFilter.blur (efeito de vidro fosco)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'cadastro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // chave do formulário — usada p/ chamar validate() em todos os campos de uma vez
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(); // controla o campo de e-mail
  final _senhaCtrl = TextEditingController(); // controla o campo de senha
  bool _verSenha   = false; // alterna entre mostrar/ocultar a senha

  @override
  void dispose() {
    // libera a memória dos controllers qdo a tela é destruída
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  // função chamada ao apertar "entrar"
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return; // para se algum campo inválido
    final auth = context.read<AuthProvider>();
    auth.limparErro(); // remove mensagem de erro anterior
    await auth.login(_emailCtrl.text.trim(), _senhaCtrl.text);
    if (!mounted) return; // importante: verifica se o widget ainda existe
    if (auth.logado) {
      // vai p/ o dashboard e remove a tela de login da pilha de navegação
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // context.watch reconstrói a tela automaticamente qdo o auth muda
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        // fundo gradiente colorido (azul → roxo → rosa) no estilo apple
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFCDE4FF), // azul claro
              Color(0xFFEBE3FF), // lilás
              Color(0xFFFFE8F0), // rosinha
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // permite scroll se o teclado empurrar o conteúdo p/ cima
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: ClipRRect(
                  // clip necessário p/ o blur n vazar pra fora do card
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    // blur de 24px cria o efeito de vidro fosco atrás do card
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xB8FFFFFF), // branco c/ 72% opacidade
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0x99FFFFFF), // borda branca semitransparente
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14007AFF), // sombra azulada suave
                            blurRadius: 40,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // o card só ocupa o espaço necessário
                        children: [
                          // ícone da fábrica c/ gradiente azul
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x4D007AFF),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.precision_manufacturing_outlined,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // título do app
                          const Text(
                            'Monitoramento\nIndustrial',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1E),
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Entre para continuar',
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // campo de e-mail
                          _buildField(
                            controller: _emailCtrl,
                            label: 'E-mail',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || !v.contains('@'))
                                ? 'E-mail inválido'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // campo de senha c/ botão de ver/ocultar
                          _buildField(
                            controller: _senhaCtrl,
                            label: 'Senha',
                            icon: Icons.lock_outline_rounded,
                            obscureText: !_verSenha, // oculta os caracteres se _verSenha=false
                            suffix: GestureDetector(
                              onTap: () =>
                                  setState(() => _verSenha = !_verSenha),
                              child: Icon(
                                _verSenha
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF8E8E93),
                                size: 20,
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),

                          // banner de erro — só aparece se o auth retornou erro
                          if (auth.erro != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0x14FF3B30), // vermelho 8% opac
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0x33FF3B30)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: Color(0xFFFF3B30), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.erro!,
                                      style: const TextStyle(
                                        color: Color(0xFFFF3B30),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // botão de login — desativado qdo está carregando
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.carregando ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007AFF),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    const Color(0x66007AFF), // azul 40% opac qdo desativado
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              // mostra spinner se carregando, senão o texto "entrar"
                              child: auth.carregando
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Entrar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // link p/ ir à tela de cadastro
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CadastroScreen()),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF007AFF),
                            ),
                            child: const Text(
                              'Não tem conta? Cadastre-se',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // widget reutilizável p/ montar cada campo do formulário
  // recebe: label, ícone, tipo de teclado, se oculta, widget no sufixo e validador
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
        // ícone à esquerda do campo
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(icon, color: const Color(0xFF007AFF), size: 20),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        // ícone à direita (ex: olho p/ ver senha)
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: suffix,
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        filled: true,
        fillColor: Colors.white, // fundo branco nos campos
        // borda padrão: arredondada s/ linha visível
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        // borda azul qdo o campo está em foco
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF007AFF), width: 1.5),
        ),
        // borda vermelha qdo há erro de validação
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF3B30)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}
