import 'dart:io';

Future<String> guardarPdf(String nombre, List<int> bytes) async {
  final perfil = Platform.environment['USERPROFILE'] ?? Directory.systemTemp.path;
  final carpeta = Directory('$perfil\\Downloads');
  final destino = carpeta.existsSync() ? carpeta : Directory.systemTemp;
  final archivo = File('${destino.path}${Platform.pathSeparator}$nombre');
  await archivo.writeAsBytes(bytes, flush: true);
  return archivo.path;
}
