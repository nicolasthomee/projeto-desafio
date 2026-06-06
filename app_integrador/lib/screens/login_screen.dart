// tela de login — dark industrial
// fundo sólido escuro s/ gradiente, card c/ borda, campos dark
// lógica de auth: idêntica à versão anterior
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'cadastro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>(); // chave p/ validar td os campos
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _verSenha   = false; // alterna visibilidade da senha

  @override
  void dispose() {
    // libera controllers da memória ao sair da tela
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  // envia o login p/ a api; se logado, navega p/ o dashboard
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.limparErro(); // remove erro anterior antes de tentar de novo
    await auth.login(_emailCtrl.text.trim(), _senhaCtrl.text);
    if (!mounted) return; // garante q o widget ainda existe antes de navegar
    if (auth.logado) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // context.watch reconstrói a tela qdo o estado do auth muda
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      // fundo sólido dark — s/ gradiente (industrial, n decorativo)
      backgroundColor: C.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // permite scroll se o teclado empurrar o conteúdo p/ cima
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Container(
                // card central: surface dark c/ borda — s/ blur (dark sólido n precisa)
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color:        C.surface,
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: C.border),
                ),
                child: Column(
                  mainAxisSize:       MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── logo ─────────────────────────────────────────────────
                    // ícone outline c/ glow ciano sutil — remete a instrumento
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:        C.accentA08,
                          borderRadius: BorderRadius.circular(10),
                          border:       Border.all(color: C.accentA20),
                          // glow ciano sutil — indica "sistema ativo"
                          boxShadow: const [
                            BoxShadow(
                              color:       C.accentA08,
                              blurRadius:  24,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.precision_manufacturing_outlined,
                          size:  32,
                          color: C.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── títulos ───────────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          // linha 1: texto branco
                          Text('MONITORAMENTO', style: T.heading),
                          // linha 2: accent — única variação de cor na tela
                          Text('INDUSTRIAL',
                              style: T.heading.copyWith(color: C.accent)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(child: Text('Entre para continuar', style: T.bodySec)),
                    const SizedBox(height: 28),

                    // ── campo e-mail ──────────────────────────────────────────
                    Text('E-MAIL', style: T.sectionLabel),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller:   _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style:        T.body,
                      decoration: const InputDecoration(
                        hintText:   'seu@email.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
                    ),
                    const SizedBox(height: 16),

                    // ── campo senha ───────────────────────────────────────────
                    Text('SENHA', style: T.sectionLabel),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller:  _senhaCtrl,
                      obscureText: !_verSenha, // oculta qdo _verSenha=false
                      style:       T.body,
                      decoration: InputDecoration(
                        hintText:   '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                        // botão de toggle: mostra/oculta a senha
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _verSenha = !_verSenha),
                          child: Icon(
                            _verSenha
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size:  18,
                            color: C.mid,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),

                    // ── banner de erro ────────────────────────────────────────
                    // só aparece se o auth retornou erro (credenciais erradas, etc.)
                    if (auth.erro != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color:        C.accentA08,
                          borderRadius: BorderRadius.circular(6),
                          border:       Border.all(color: C.accentA20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: C.accent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.erro!,
                                style: T.small.copyWith(color: C.accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── botão entrar ──────────────────────────────────────────
                    // desabilitado qdo carregando (evita duplo tap)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.carregando ? null : _login,
                        // spinner qdo aguardando resp da api
                        child: auth.carregando
                            ? const SizedBox(
                                height: 20,
                                width:  20,
                                child:  CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:       C.bg,
                                ),
                              )
                            : const Text('ENTRAR'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── link p/ cadastro ──────────────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CadastroScreen()),
                        ),
                        child: const Text('Não tem conta? Cadastre-se'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
