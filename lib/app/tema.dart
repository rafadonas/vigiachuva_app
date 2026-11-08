import 'package:flutter/material.dart';

import '../data/modelos/alerta.dart';

/// Espaçamentos padronizados (múltiplos de 4) usados em todo o app.
class Espaco {
  Espaco._();
  static const double xs = 4;
  static const double p = 8;
  static const double m = 16;
  static const double g = 24;
  static const double gg = 32;
}

/// Identidade visual "água e alerta": azul profundo + verde-água, com cores de alerta
/// escolhidas para contraste mínimo de 4,5:1 sobre o fundo (WCAG AA).
class TemaVigiaChuva {
  TemaVigiaChuva._();

  static const Color azulProfundo = Color(0xFF0B3954);
  static const Color verdeAgua = Color(0xFF087E8B);

  static ThemeData claro() =>
      _base(ColorScheme.fromSeed(seedColor: azulProfundo, primary: azulProfundo, secondary: verdeAgua, brightness: Brightness.light));

  static ThemeData escuro() => _base(
    ColorScheme.fromSeed(
      seedColor: azulProfundo,
      primary: const Color(0xFF9CCBFF),
      secondary: const Color(0xFF7FD6DE),
      brightness: Brightness.dark,
    ),
  );

  /// Alto contraste: preto, branco e amarelo, bordas grossas.
  static ThemeData altoContraste({required bool escuro}) {
    final esquema = escuro
        ? const ColorScheme.dark(
            primary: Color(0xFFFFE600),
            onPrimary: Colors.black,
            secondary: Color(0xFFFFE600),
            onSecondary: Colors.black,
            surface: Colors.black,
            onSurface: Colors.white,
            error: Color(0xFFFF8A80),
            onError: Colors.black,
          )
        : const ColorScheme.light(
            primary: Colors.black,
            onPrimary: Colors.white,
            secondary: Color(0xFF1A1A1A),
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
            error: Color(0xFF9B0000),
            onError: Colors.white,
          );
    final base = _base(esquema);
    return base.copyWith(
      cardTheme: base.cardTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: esquema.onSurface, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(color: esquema.onSurface, thickness: 1.5),
    );
  }

  static ThemeData _base(ColorScheme esquema) {
    final texto = Typography.material2021(
      platform: TargetPlatform.android,
    ).black.apply(bodyColor: esquema.onSurface, displayColor: esquema.onSurface);
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      textTheme: texto.copyWith(
        headlineSmall: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: texto.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: texto.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: esquema.brightness == Brightness.light ? esquema.primary : esquema.surface,
        foregroundColor: esquema.brightness == Brightness.light ? esquema.onPrimary : esquema.onSurface,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: Espaco.g),
        ),
      ),
      visualDensity: VisualDensity.standard,
    );
  }

  /// Cores dos níveis de alerta (texto branco sobre elas tem contraste ≥ 4,5:1).
  /// No tema de alto contraste, os componentes usam a cor primária do tema (ver SeloNivel e painéis).
  static Color corNivel(NivelAlerta nivel) {
    return switch (nivel) {
      NivelAlerta.atencao => const Color(0xFF8A5300),
      NivelAlerta.alerta => const Color(0xFFB23C00),
      NivelAlerta.critico => const Color(0xFFB3261E),
    };
  }

  static IconData iconeNivel(NivelAlerta nivel) => switch (nivel) {
    NivelAlerta.atencao => Icons.info_outline,
    NivelAlerta.alerta => Icons.warning_amber_rounded,
    NivelAlerta.critico => Icons.report_gmailerrorred,
  };
}
