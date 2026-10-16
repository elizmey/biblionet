import 'dart:io';

Future<String> guardarCsv(String nombre, String contenido) async {
  final perfil = Platform.environment['USERPROFILE'] ?? Directory.systemTemp.path;
  final carpeta = Directory('$perfil\\Downloads');
  final destino = carpeta.existsSync() ? carpeta : Directory.systemTemp;
  final archivo = File('${destino.path}${Platform.pathSeparator}$nombre');
  await archivo.writeAsString(contenido);
  return archivo.path;
}
