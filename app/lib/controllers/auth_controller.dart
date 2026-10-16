import 'package:flutter/foundation.dart';

import '../models/modelos.dart';
import '../services/api_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.api);

  final ApiService api;
  Sesion? sesion;
  bool cargando = false;
  String? error;

  Future<bool> ingresar(String usuario, String clave) async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final data = await api.enviar('POST', '/api/v1/auth/login', cuerpo: {
        'usuario': usuario.trim(),
        'clave': clave,
      });
      final mapa = Map<String, dynamic>.from(data as Map);
      api.token = mapa['token']?.toString();
      sesion = Sesion.fromJson(Map<String, dynamic>.from(mapa['usuario'] as Map));
      return true;
    } on ApiException catch (errorApi) {
      error = errorApi.message;
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<bool> registrar(Map<String, dynamic> datos) async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final data = await api.enviar('POST', '/api/v1/auth/registro', cuerpo: datos);
      final mapa = Map<String, dynamic>.from(data as Map);
      api.token = mapa['token']?.toString();
      sesion = Sesion.fromJson(Map<String, dynamic>.from(mapa['usuario'] as Map));
      return true;
    } on ApiException catch (errorApi) {
      error = errorApi.message;
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void salir() {
    api.cerrarSesion();
    sesion = null;
    notifyListeners();
  }
}
