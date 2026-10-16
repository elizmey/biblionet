import 'package:web/web.dart' as web;

Future<String> guardarCsv(String nombre, String contenido) async {
  final enlace = 'data:text/csv;charset=utf-8,${Uri.encodeComponent(contenido)}';
  final ancla = web.HTMLAnchorElement()
    ..href = enlace
    ..download = nombre;
  ancla.click();
  return nombre;
}
