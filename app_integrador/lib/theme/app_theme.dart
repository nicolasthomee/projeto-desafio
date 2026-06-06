// sistema de design do app — dark industrial
// regra: exatamente 3 camadas de cor:
//   1. escuro  → fundos (bg, surface, borda)
//   2. claro   → texto (primário, secundário, hint)
//   3. ciano   → accent — única cor viva do app
// tipografia: JetBrains Mono p/ números, Space Grotesk p/ o resto

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── tokens de cor ─────────────────────────────────────────────────────────────
// abstract final = n instanciável e n herdável — funciona como namespace de constantes
abstract final class C {
  // fundos — escala do mais escuro ao mais claro
  static const bg        = Color(0xFF0D1117); // scaffold / tela principal
  static const surface   = Color(0xFF161B22); // cards e painéis
  static const surfaceHi = Color(0xFF1C2128); // pill nav e elementos elevados
  static const border    = Color(0xFF30363D); // bordas e divisores

  // texto
  static const hi  = Color(0xFFE6EDF3); // primário — quase branco
  static const mid = Color(0xFF8B949E); // secundário — cinza médio
  static const low = Color(0xFF484F58); // hint e desabilitado — cinza escuro

  // accent — ciano — única cor viva, aparece em td q é interativo ou em destaque
  static const accent    = Color(0xFF00D9FF); // 100% — ativo / interativo
  static const accentA50 = Color(0x8000D9FF); //  50% — standby
  static const accentA20 = Color(0x3300D9FF); //  20% — estado apagado / borda sutil
  static const accentA08 = Color(0x1400D9FF); //   8% — fundo sutil de destaque
}

// ── tipografia ─────────────────────────────────────────────────────────────────
// JetBrains Mono → números e dados (remete a terminais e instrumentação)
// Space Grotesk  → todo o resto (limpo, geométrico, alto contraste no dark)
abstract final class T {
  // helpers privados p/ não repetir parâmetros base
  static TextStyle _mono(double s, FontWeight w, Color c, {double ls = -0.5}) =>
      GoogleFonts.jetBrainsMono(
          fontSize: s, fontWeight: w, color: c, letterSpacing: ls, height: 1.2);

  static TextStyle _sans(double s, FontWeight w, Color c, {double ls = 0}) =>
      GoogleFonts.spaceGrotesk(
          fontSize: s, fontWeight: w, color: c, letterSpacing: ls, height: 1.3);

  // ── métricas — o dado mais importante da tela ─────────────────────────────
  // getter = calculado a cada acesso; google_fonts é rápido o suficiente
  static TextStyle get metricXL => _mono(40, FontWeight.w600, C.hi);      // dashboard grande
  static TextStyle get metricL  => _mono(28, FontWeight.w500, C.hi);      // cards normais
  static TextStyle get metricM  => _mono(20, FontWeight.w500, C.accent);  // valores de relatório

  // ── status da linha — mono maiúsculo p/ parecer painel de controle ────────
  static TextStyle get statusText =>
      _mono(13, FontWeight.w700, C.accent, ls: 1.5);

  // ── títulos de tela ───────────────────────────────────────────────────────
  static TextStyle get heading => _sans(20, FontWeight.w700, C.hi, ls: -0.3);
  static TextStyle get appBar  => _sans(15, FontWeight.w600, C.hi, ls: -0.2);

  // ── rótulos e seções ─────────────────────────────────────────────────────
  // letter spacing alto → simula efeito uppercase s/ precisar de transform
  static TextStyle get sectionLabel =>
      _sans(11, FontWeight.w600, C.mid, ls: 1.2);
  static TextStyle get label => _sans(11, FontWeight.w500, C.mid, ls: 0.5);

  // ── corpo ─────────────────────────────────────────────────────────────────
  static TextStyle get body    => _sans(14, FontWeight.w400, C.hi);
  static TextStyle get bodySec => _sans(13, FontWeight.w400, C.mid);
  static TextStyle get small   => _sans(12, FontWeight.w400, C.mid);
}

// ── status da linha de produção ────────────────────────────────────────────────
// mapeamento c/ apenas as 3 cores do app — sem cor extra
// o estado é comunicado pela intensidade do accent + ícone
class StatusStyle {
  final Color led;    // cor do ponto LED
  final Color text;   // cor do texto do status
  final Color borderL;// cor da borda esquerda do painel (indicador visual principal)
  final IconData icon;// ícone q complementa o estado

  const StatusStyle({
    required this.led,
    required this.text,
    required this.borderL,
    required this.icon,
  });

  // factory estática — switch expression do Dart 3
  static StatusStyle of(String status) => switch (status) {
    'RODANDO'   => const StatusStyle(
        led: C.accent,    text: C.accent, borderL: C.accent,
        icon: Icons.play_arrow_rounded),
    'PARADA'    => const StatusStyle(
        led: C.accentA20, text: C.mid,    borderL: C.border,
        icon: Icons.stop_rounded),
    'ALERTA'    => const StatusStyle(
        led: C.accent,    text: C.accent, borderL: C.accent,
        icon: Icons.warning_amber_rounded),
    'STANDBY'   => const StatusStyle(
        led: C.accentA50, text: C.mid,    borderL: C.accentA50,
        icon: Icons.pause_rounded),
    'ENCERRADO' => const StatusStyle(
        led: C.low,       text: C.low,    borderL: C.border,
        icon: Icons.power_settings_new_rounded),
    _           => const StatusStyle(
        led: C.low,       text: C.low,    borderL: C.border,
        icon: Icons.help_outline_rounded),
  };
}

// ── theme data ─────────────────────────────────────────────────────────────────
// função top-level p/ facilitar o import no main.dart
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // color scheme: primary = accent, surface = surface, fundo = bg
    colorScheme: const ColorScheme.dark(
      primary:            C.accent,
      onPrimary:          C.bg,       // texto escuro sobre botão ciano
      primaryContainer:   C.accentA20,
      onPrimaryContainer: C.accent,
      secondary:          C.accent,
      onSecondary:        C.bg,
      error:              C.accent,   // mantém 3 cores — usa accent p/ erros tbm
      onError:            C.bg,
      surface:            C.surface,
      onSurface:          C.hi,
      surfaceContainerHighest: C.surfaceHi,
      onSurfaceVariant:        C.mid,
      outline:            C.border,
      outlineVariant:     C.border,
    ),

    scaffoldBackgroundColor: C.bg,
    cardColor:               C.surface,
    dividerColor:            C.border,

    // appbar: fundo = bg, sem elevação, ícones em accent
    appBarTheme: AppBarTheme(
      backgroundColor:        C.bg,
      elevation:              0,
      scrolledUnderElevation: 0,
      surfaceTintColor:       Colors.transparent,
      foregroundColor:        C.hi,
      centerTitle:            false,
      titleTextStyle:         T.appBar,
      iconTheme: const IconThemeData(color: C.accent, size: 20),
    ),

    // campos de formulário: fundo surfaceHi, borda border, foco accent
    inputDecorationTheme: InputDecorationTheme(
      filled:         true,
      fillColor:      C.surfaceHi,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border:            _borda(C.border),
      enabledBorder:     _borda(C.border),
      focusedBorder:     _borda(C.accent, w: 1.5),
      errorBorder:       _borda(C.accent),
      focusedErrorBorder:_borda(C.accent, w: 1.5),
      labelStyle:  T.bodySec,
      hintStyle:   T.small,
      errorStyle:  GoogleFonts.spaceGrotesk(
          fontSize: 12, color: C.accent, height: 1.3),
      prefixIconColor: C.accent,
      suffixIconColor: C.mid,
    ),

    // botão principal: fundo accent, texto escuro — estilo CTA industrial
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: C.accent,
        foregroundColor: C.bg,
        elevation:       0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding:     const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 52),
        textStyle:   GoogleFonts.spaceGrotesk(
            fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    ),

    // botão texto: accent color
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C.accent,
        textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    // ícones genéricos: mid (cinza) — accent só p/ ícones interativos
    iconTheme: const IconThemeData(color: C.mid, size: 20),

    // progress indicator: accent
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: C.accent),

    // divisor: border color, espessura 1
    dividerTheme: const DividerThemeData(
        color: C.border, space: 1, thickness: 1),
  );
}

// helper p/ bordas de input — evita repetição do OutlineInputBorder
OutlineInputBorder _borda(Color c, {double w = 1.0}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide:   BorderSide(color: c, width: w),
    );
