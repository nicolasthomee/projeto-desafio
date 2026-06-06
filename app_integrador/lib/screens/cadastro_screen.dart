// tela de cadastro — dark industrial, visual idêntico ao login
// lógica de auth: idêntica à versão anterior
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey      = GlobalKey<FormState>(); // valida td os campos juntos
  final _emailCtrl    = TextEditingController();
  final _senhaCtrl    = TextEditingController();
  final _confirmaCtrl = TextEditingController(); // confirmação de senha
  bool _verSenha      = false; // alterna visibilidade dos campos de senha

  @override
  void dispose() {
    // libera os 3 controllers da memória
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  // envia o cadastro; se logado, navega p/ o dashboard removendo o back stack
  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.limparErro();
    await auth.cadastrar(_emailCtrl.text.trim(), _senhaCtrl.text);
    if (!mounted) return;
    if (auth.logado) {
      // pushAndRemoveUntil = remove td da pilha; usuário n consegue voltar p/ o cadastro
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(
          children: [

            // ── appbar manual ─────────────────────────────────────────────────
            // usa Row em vez de AppBar p/ controle total do visual dark
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // botão voltar em accent — área mínima 48dp p/ uso c/ luvas
                  IconButton(
                    icon:      const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color:     C.accent,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text('Criar Conta', style: T.appBar),
                ],
              ),
            ),

            // ── formulário ────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Container(
                    // card dark c/ borda — mesmo padrão do login
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color:        C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border:       Border.all(color: C.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── título da seção ───────────────────────────────────
                        Text('NOVO USUÁRIO', style: T.heading),
                        const SizedBox(height: 6),
                        Text('Preencha os dados p/ criar sua conta',
                            style: T.bodySec),
                        const SizedBox(height: 28),

                        // ── campo e-mail ──────────────────────────────────────
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

                        // ── campo senha ───────────────────────────────────────
                        Text('SENHA', style: T.sectionLabel),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller:  _senhaCtrl,
                          obscureText: !_verSenha,
                          style:       T.body,
                          decoration: InputDecoration(
                            hintText:   '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
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
                        const SizedBox(height: 16),

                        // ── campo confirmar senha ─────────────────────────────
                        Text('CONFIRMAR SENHA', style: T.sectionLabel),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller:  _confirmaCtrl,
                          obscureText: !_verSenha, // segue o mesmo toggle da senha
                          style:       T.body,
                          decoration: const InputDecoration(
                            hintText:   '••••••••',
                            prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                          ),
                          // valida se os dois campos de senha são iguais
                          validator: (v) =>
                              v != _senhaCtrl.text ? 'As senhas não coincidem' : null,
                        ),

                        // ── banner de erro da api ─────────────────────────────
                        if (auth.erro != null) ...[
                          const SizedBox(height: 14),
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

                        // ── botão cadastrar ────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.carregando ? null : _cadastrar,
                            child: auth.carregando
                                ? const SizedBox(
                                    height: 20,
                                    width:  20,
                                    child:  CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:       C.bg,
                                    ),
                                  )
                                : const Text('CADASTRAR'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
