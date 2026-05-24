// tela de cadastro — cria uma nova conta
// visual idêntico ao login: mesmo gradiente + glassmorphism
import 'dart:ui'; // p/ o ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey      = GlobalKey<FormState>(); // chave p/ validar todos os campos juntos
  final _emailCtrl    = TextEditingController();
  final _senhaCtrl    = TextEditingController();
  final _confirmaCtrl = TextEditingController(); // campo "confirmar senha"
  bool _verSenha      = false; // alterna visibilidade da senha

  @override
  void dispose() {
    // libera os controllers da memória qdo sai da tela
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  // envia o cadastro p/ a api e, se der certo, já leva ao dashboard
  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return; // para se algum campo inválido
    final auth = context.read<AuthProvider>();
    auth.limparErro();
    await auth.cadastrar(_emailCtrl.text.trim(), _senhaCtrl.text);
    if (!mounted) return;
    if (auth.logado) {
      // pushAndRemoveUntil remove tudo da pilha de navegação
      // assim o usuário n consegue voltar p/ o cadastro c/ o botão "voltar"
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>(); // observa mudanças no estado

    return Scaffold(
      body: Container(
        // mesmo gradiente da tela de login p/ manter consistência visual
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFCDE4FF),
              Color(0xFFEBE3FF),
              Color(0xFFFFE8F0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // appbar manual: só uma linha c/ botão voltar + título
              // usa Row em vez de AppBar p/ ter controle total do visual
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      color: const Color(0xFF007AFF),
                      onPressed: () => Navigator.pop(context), // volta à tela anterior
                    ),
                    const Text(
                      'Criar Conta',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded faz o form preencher o espaço restante
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: ClipRRect(
                      // clip necessário p/ o blur n vazar p/ fora do card
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        // cria o efeito glassmorphism — desfoca o fundo atrás do card
                        filter:
                            ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: const Color(0xB8FFFFFF), // branco c/ 72% opac
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0x99FFFFFF),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14007AFF),
                                blurRadius: 40,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Novo usuário',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1C1C1E),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Preencha os dados para criar sua conta',
                                style: TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // campo e-mail
                              _buildField(
                                'E-mail',
                                _emailCtrl,
                                Icons.mail_outline_rounded,
                                tipo: TextInputType.emailAddress,
                                validator: (v) =>
                                    (v == null || !v.contains('@'))
                                        ? 'E-mail inválido'
                                        : null,
                              ),
                              const SizedBox(height: 14),

                              // campo senha c/ toggle de visibilidade
                              _buildField(
                                'Senha',
                                _senhaCtrl,
                                Icons.lock_outline_rounded,
                                obscuro: !_verSenha,
                                sufixo: GestureDetector(
                                  onTap: () => setState(
                                      () => _verSenha = !_verSenha),
                                  child: Icon(
                                    _verSenha
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF8E8E93),
                                    size: 20,
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.length < 6)
                                        ? 'Mínimo 6 caracteres'
                                        : null,
                              ),
                              const SizedBox(height: 14),

                              // campo confirmar senha — valida se os dois são iguais
                              _buildField(
                                'Confirmar Senha',
                                _confirmaCtrl,
                                Icons.lock_outline_rounded,
                                obscuro: !_verSenha,
                                validator: (v) =>
                                    v != _senhaCtrl.text
                                        ? 'As senhas não coincidem'
                                        : null,
                              ),

                              // banner de erro vindo da api
                              if (auth.erro != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0x14FF3B30),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: const Color(0x33FF3B30)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                          Icons.error_outline_rounded,
                                          color: Color(0xFFFF3B30),
                                          size: 16),
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

                              // botão principal — mostra spinner durante o request
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: auth.carregando
                                      ? null // desativa o botão enquanto aguarda a api
                                      : _cadastrar,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF007AFF),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0x66007AFF),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                  ),
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
                                          'Cadastrar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
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
            ],
          ),
        ),
      ),
    );
  }

  // campo de formulário reutilizável — mesmo padrão visual do login
  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icone, {
    TextInputType tipo = TextInputType.text,
    bool obscuro = false,   // se true, esconde os caracteres digitados
    Widget? sufixo,         // widget opcional no lado direito (ex: ícone de olho)
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: tipo,
      obscureText: obscuro,
      style: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(icone, color: const Color(0xFF007AFF), size: 20),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        suffixIcon: sufixo != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: sufixo,
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        filled: true,
        fillColor: const Color(0xFFF2F2F7), // cinza bem claro no campo
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF007AFF), width: 1.5),
        ),
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
