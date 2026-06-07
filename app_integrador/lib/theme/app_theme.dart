// sistema de design do app — dark industrial
// regra: exatamente 3 camadas de cor:
//   1. escuro  → fundos (bg, surface, borda)
//   2. claro   → texto (primário, secundário, hint)
//   3. ciano   → accent — única cor viva do app
// tipografia: JetBrains Mono p/ números, Space Grotesk p/ o resto

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── tokens de cor ─────────────────────────────────────────────────────────────
abstract final class C {
  // fundos — escala do mais escuro ao mais claro
  static const bg        = Color(0xFF0D1117);
  static const surface   = Color(0xFF161B22);
  static const surfaceHi = Color(0xFF1C2128);
  static const border    = Color(0xFF30363D);

  // texto
  static const hi  = Color(0xFFE6EDF3);
  static const mid = Color(0xFF8B949E);
  static const low = Color(0xFF484F58);

  // accent — ciano
  static const accent    = Color(0xFF00D9FF);
  static const accentA50 = Color(0x8000D9FF);
  static const accentA20 = Color(0x3300D9FF);
  static const accentA08 = Color(0x1400D9FF);

  // cores de estado — indicadores de status da linha
  static const green     = Color(0xFF3FB950); // rodando
  static const greenA20  = Color(0x333FB950); // fundo sutil verde
  static const red       = Color(0xFFF85149); // parada / alerta
  static const redA20    = Color(0x33F85149); // fundo sutil vermelho
  static const blue      = Color(0xFF58A6FF); // standby / encerrado
  static const blueA20   = Color(0x3358A6FF); // fundo sutil azul
}

// ── tipografia ─────────────────────────────────────────────────────────────────
abstract final class T {
  static TextStyle _mono(double s, FontWeight w, Color c, {double ls = -0.5}) =>
      GoogleFonts.jetBrainsMono(
          fontSize: s, fontWeight: w, color: c, letterSpacing: ls, height: 1.2);

  static TextStyle _sans(double s, FontWeight w, Color c, {double ls = 0}) =>
      GoogleFonts.spaceGrotesk(
          fontSize: s, fontWeight: w, color: c, letterSpacing: ls, height: 1.3);

  static TextStyle get metricXL => _mono(40, FontWeight.w600, C.hi);
  static TextStyle get metricL  => _mono(28, FontWeight.w500, C.hi);
  static TextStyle get metricM  => _mono(20, FontWeight.w500, C.accent);

  static TextStyle get statusText =>
      _mono(13, FontWeight.w700, C.accent, ls: 1.5);

  static TextStyle get heading => _sans(20, FontWeight.w700, C.hi, ls: -0.3);
  static TextStyle get appBar  => _sans(15, FontWeight.w600, C.hi, ls: -0.2);

  static TextStyle get sectionLabel =>
      _sans(11, FontWeight.w600, C.mid, ls: 1.2);
  static TextStyle get label => _sans(11, FontWeight.w500, C.mid, ls: 0.5);

  static TextStyle get body    => _sans(14, FontWeight.w400, C.hi);
  static TextStyle get bodySec => _sans(13, FontWeight.w400, C.mid);
  static TextStyle get small   => _sans(12, FontWeight.w400, C.mid);
}

// ── status da linha de produção ────────────────────────────────────────────────
class StatusStyle {
  final Color led;
  final Color text;
  final Color borderL;
  final Color bgSutil;
  final IconData icon;

  const StatusStyle({
    required this.led,
    required this.text,
    required this.borderL,
    required this.bgSutil,
    required this.icon,
  });

  static StatusStyle of(String status) => switch (status) {
    'RODANDO'   => const StatusStyle(
        led:     C.green,
        text:    C.green,
        borderL: C.green,
        bgSutil: C.greenA20,
        icon:    Icons.play_arrow_rounded),
    'PARADA'    => const StatusStyle(
        led:     C.red,
        text:    C.red,
        borderL: C.red,
        bgSutil: C.redA20,
        icon:    Icons.stop_rounded),
    'ALERTA'    => const StatusStyle(
        led:     C.red,
        text:    C.red,
        borderL: C.red,
        bgSutil: C.redA20,
        icon:    Icons.warning_amber_rounded),
    'STANDBY'   => const StatusStyle(
        led:     C.blue,
        text:    C.blue,
        borderL: C.blue,
        bgSutil: C.blueA20,
        icon:    Icons.pause_rounded),
    'ENCERRADO' => const StatusStyle(
        led:     C.blue,
        text:    C.blue,
        borderL: C.blue,
        bgSutil: C.blueA20,
        icon:    Icons.power_settings_new_rounded),
    _           => const StatusStyle(
        led:     C.low,
        text:    C.low,
        borderL: C.border,
        bgSutil: C.surface,
        icon:    Icons.help_outline_rounded),
  };
}

// ── theme data ─────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: const ColorScheme.dark(
      primary:            C.accent,
      onPrimary:          C.bg,
      primaryContainer:   C.accentA20,
      onPrimaryContainer: C.accent,
      secondary:          C.accent,
      onSecondary:        C.bg,
      error:              C.red,
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

    inputDecorationTheme: InputDecorationTheme(
      filled:         true,
      fillColor:      C.surfaceHi,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border:            _borda(C.border),
      enabledBorder:     _borda(C.border),
      focusedBorder:     _borda(C.accent, w: 1.5),
      errorBorder:       _borda(C.red),
      focusedErrorBorder:_borda(C.red, w: 1.5),
      labelStyle:  T.bodySec,
      hintStyle:   T.small,
      errorStyle:  GoogleFonts.spaceGrotesk(
          fontSize: 12, color: C.red, height: 1.3),
      prefixIconColor: C.accent,
      suffixIconColor: C.mid,
    ),

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

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C.accent,
        textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    iconTheme: const IconThemeData(color: C.mid, size: 20),

    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: C.accent),

    dividerTheme: const DividerThemeData(
        color: C.border, space: 1, thickness: 1),
  );
}

OutlineInputBorder _borda(Color c, {double w = 1.0}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide:   BorderSide(color: c, width: w),
    );