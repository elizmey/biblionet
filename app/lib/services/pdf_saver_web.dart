import 'dart:convert';

import 'package:web/web.dart' as web;

Future<String> guardarPdf(String nombre, List<int> bytes) async {
  final enlace = 'data:application/pdf;base64,${base64Encode(bytes)}';
  final ancla = web.HTMLAnchorElement()
    ..href = enlace
    ..download = nombre;
  ancla.click();
  return nombre;
}
