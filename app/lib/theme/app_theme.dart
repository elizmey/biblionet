import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Android e iOS usan el diseño de teléfono. Web y Windows conservan el diseño de escritorio.
bool get esAplicacionTelefono {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
}

class BiblioColors {
  static const morado = Color(0xFF4B2A7B);
  static const moradoOscuro = Color(0xFF2F1A4F);
  static const amarillo = Color(0xFFFFC72C);
  static const fondo = Color(0xFFF6F3FB);
  static const verde = Color(0xFF1E8E4E);
  static const ambar = Color(0xFF8A6100);
  static const rojo = Color(0xFFB3261E);
}

ThemeData appTheme() {
  final base = ColorScheme.fromSeed(seedColor: BiblioColors.morado);
  return ThemeData(
    useMaterial3: true,
    colorScheme: base.copyWith(
      primary: BiblioColors.morado,
      secondary: BiblioColors.amarillo,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: BiblioColors.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: BiblioColors.morado,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BiblioColors.morado,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}

String fechaCorta(dynamic valor) {
  if (valor == null) return '—';
  final texto = valor.toString();
  return texto.length >= 10 ? texto.substring(0, 10) : texto;
}

int comoEntero(dynamic valor) {
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  return int.tryParse(valor.toString()) ?? 0;
}

double comoDecimal(dynamic valor) {
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor.toString()) ?? 0;
}
