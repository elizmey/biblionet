import 'package:flutter/foundation.dart';

import '../models/modelos.dart';
import '../services/api_service.dart';
import '../services/pdf_saver.dart';
import '../services/reporte_pdf.dart';
import '../theme/app_theme.dart';

class BibliotecaController extends ChangeNotifier {
  BibliotecaController(this.api);

  final ApiService api;
  bool cargando = false;
  String? error;

  Map<String, dynamic> indicadores = {};
  List<Map<String, dynamic>> vencidos = [];
  List<Map<String, dynamic>> stockBajo = [];
  List<Libro> libros = [];
  List<Opcion> categorias = [];
  List<Opcion> autoresOpciones = [];
  List<Opcion> editoriales = [];
  List<Map<String, dynamic>> reservas = [];
  List<Socio> socios = [];
  List<Prestamo> prestamos = [];
  List<Multa> multas = [];
  double deudaPendiente = 0;
  String tarifa = '0.25';
  List<Map<String, dynamic>> ranking = [];
  List<Ejemplar> listaEjemplares = [];
  List<Map<String, dynamic>> usuarios = [];
  List<Opcion> roles = [];
  List<Map<String, dynamic>> parametros = [];

  Future<T?> _ejecutar<T>(Future<T> Function() accion) async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final resultado = await accion();
      return resultado;
    } on ApiException catch (errorApi) {
      error = errorApi.message;
      return null;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarPanel() async {
    await _ejecutar(() async {
      final data = Map<String, dynamic>.from(await api.enviar('GET', '/api/v1/panel') as Map);
      indicadores = Map<String, dynamic>.from(data['indicadores'] as Map);
      vencidos = (data['vencidos'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      stockBajo = (data['stockBajo'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Future<void> cargarCatalogo({String q = '', String? categoria, bool soloDisponibles = false}) async {
    await _ejecutar(() async {
      final consulta = <String, String>{'q': q};
      if (categoria != null && categoria.isNotEmpty) consulta['categoria'] = categoria;
      if (soloDisponibles) consulta['disponibles'] = '1';
      final lista = await api.enviar('GET', '/api/v1/libros', consulta: consulta) as List;
      libros = lista.map((e) => Libro.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      final cats = await api.enviar('GET', '/api/v1/categorias') as List;
      categorias = cats
          .map((e) => Opcion(id: comoEntero((e as Map)['id_categoria']), nombre: e['nombre'].toString()))
          .toList();
    });
  }

  Future<void> cargarEjemplares() async {
    await _ejecutar(() async {
      final lista = await api.enviar('GET', '/api/v1/ejemplares') as List;
      listaEjemplares = lista.map((e) => Ejemplar.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    });
  }

  Future<List<Ejemplar>> ejemplaresDe(int idLibro) async {
    final lista = await api.enviar('GET', '/api/v1/ejemplares', consulta: {'id_libro': '$idLibro'}) as List;
    return lista.map((e) => Ejemplar.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<String?> prestar(int idSocio, List<int> ejemplares) async {
    String? mensaje;
    await _ejecutar(() async {
      await api.enviar('POST', '/api/v1/prestamos', cuerpo: {
        'id_socio': idSocio,
        'ejemplares': ejemplares,
      });
      mensaje = 'Préstamo registrado';
    });
    return error ?? mensaje;
  }

  Future<String?> reservar(int idLibro) async {
    String? limite;
    await _ejecutar(() async {
      final data = Map<String, dynamic>.from(
        await api.enviar('POST', '/api/v1/reservas', cuerpo: {'id_libro': idLibro}) as Map,
      );
      limite = fechaCorta(data['fecha_limite']);
    });
    return limite;
  }

  Future<void> cargarClasificadores() async {
    await _ejecutar(() async {
      final cats = await api.enviar('GET', '/api/v1/categorias') as List;
      categorias = cats
          .map((e) => Opcion(id: comoEntero((e as Map)['id_categoria']), nombre: e['nombre'].toString()))
          .toList();
      final auts = await api.enviar('GET', '/api/v1/autores') as List;
      autoresOpciones = auts
          .map((e) => Opcion(
                id: comoEntero((e as Map)['id_autor']),
                nombre: '${e['nombres']} ${e['apellidos']}',
              ))
          .toList();
      final edits = await api.enviar('GET', '/api/v1/editoriales') as List;
      editoriales = edits
          .map((e) => Opcion(id: comoEntero((e as Map)['id_editorial']), nombre: e['nombre'].toString()))
          .toList();
    });
  }

  Future<bool> guardarLibro(Map<String, dynamic> datos, {int? id}) async {
    final ok = await _ejecutar(() async {
      if (id == null) {
        await api.enviar('POST', '/api/v1/libros', cuerpo: datos);
      } else {
        await api.enviar('PUT', '/api/v1/libros/$id', cuerpo: datos);
      }
      return true;
    });
    return ok == true;
  }

  Future<bool> guardarEjemplar(Map<String, dynamic> datos, {int? id}) async {
    final ok = await _ejecutar(() async {
      if (id == null) {
        await api.enviar('POST', '/api/v1/ejemplares', cuerpo: datos);
      } else {
        await api.enviar('PUT', '/api/v1/ejemplares/$id', cuerpo: datos);
      }
      return true;
    });
    return ok == true;
  }

  Future<void> cargarReservas() async {
    await _ejecutar(() async {
      final lista = await api.enviar('GET', '/api/v1/reservas') as List;
      reservas = lista.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Future<bool> cancelarReserva(int id) async {
    final ok = await _ejecutar(() async {
      await api.enviar('PATCH', '/api/v1/reservas/$id', cuerpo: {'estado': 'CANCELADA'});
      return true;
    });
    return ok == true;
  }

  Future<void> cargarSocios([String q = '']) async {
    await _ejecutar(() async {
      final lista = await api.enviar('GET', '/api/v1/socios', consulta: {'q': q}) as List;
      socios = lista.map((e) => Socio.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    });
  }

  Future<bool> guardarSocio(Map<String, dynamic> datos, {int? id}) async {
    final ok = await _ejecutar(() async {
      if (id == null) {
        await api.enviar('POST', '/api/v1/socios', cuerpo: datos);
      } else {
        await api.enviar('PUT', '/api/v1/socios/$id', cuerpo: datos);
      }
      return true;
    });
    return ok == true;
  }

  Future<void> cargarPrestamos({required bool propios}) async {
    await _ejecutar(() async {
      final ruta = propios ? '/api/v1/prestamos/mios' : '/api/v1/prestamos';
      final lista = await api.enviar('GET', ruta) as List;
      prestamos = lista.map((e) => Prestamo.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    });
  }

  Future<String?> devolver(int idPrestamo, int idDetalle) async {
    String? mensaje;
    await _ejecutar(() async {
      final data = Map<String, dynamic>.from(
        await api.enviar('POST', '/api/v1/prestamos/$idPrestamo/detalles/$idDetalle/devolucion') as Map,
      );
      final monto = comoDecimal(data['monto']);
      mensaje = monto > 0 ? 'Devolución registrada. Multa de USD ${monto.toStringAsFixed(2)}' : 'Devolución registrada';
    });
    return error ?? mensaje;
  }

  Future<void> cargarMultasPropias() async {
    await _ejecutar(() async {
      final data = Map<String, dynamic>.from(await api.enviar('GET', '/api/v1/multas/mias') as Map);
      deudaPendiente = comoDecimal(data['total']);
      multas = (data['multas'] as List).map((e) => Multa.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    });
  }

  Future<void> cargarMultas() async {
    await _ejecutar(() async {
      final data = Map<String, dynamic>.from(await api.enviar('GET', '/api/v1/multas') as Map);
      tarifa = data['tarifa']?.toString() ?? '0.25';
      multas = (data['multas'] as List).map((e) => Multa.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    });
  }

  Future<bool> pagarMulta(int id) async {
    final ok = await _ejecutar(() async {
      await api.enviar('PATCH', '/api/v1/multas/$id', cuerpo: {'estado': 'PAGADA'});
      return true;
    });
    return ok == true;
  }

  Future<void> cargarReportes() async {
    await _ejecutar(() async {
      final lista = await api.enviar('GET', '/api/v1/reportes/mas-prestados') as List;
      ranking = lista.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final panelData = Map<String, dynamic>.from(await api.enviar('GET', '/api/v1/panel') as Map);
      indicadores = Map<String, dynamic>.from(panelData['indicadores'] as Map);
      vencidos = (panelData['vencidos'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final multasData = Map<String, dynamic>.from(await api.enviar('GET', '/api/v1/multas') as Map);
      tarifa = multasData['tarifa']?.toString() ?? tarifa;
      multas = (multasData['multas'] as List).map((e) => Multa.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      final prestamosData = await api.enviar('GET', '/api/v1/prestamos') as List;
      prestamos = prestamosData.map((e) => Prestamo.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    });
  }

  Future<String?> exportarPdf() async {
    String? ruta;
    await _ejecutar(() async {
      final bytes = await construirReportePdf(
        indicadores: indicadores,
        ranking: ranking,
        vencidos: vencidos,
        multas: multas,
        prestamos: prestamos,
      );
      ruta = await guardarPdf('reportes_biblioteca.pdf', bytes);
    });
    return error ?? (ruta == null ? null : 'PDF descargado: $ruta');
  }

  Future<void> cargarAdmin() async {
    await _ejecutar(() async {
      final data = Map<String, dynamic>.from(await api.enviar('GET', '/api/v1/usuarios') as Map);
      usuarios = (data['usuarios'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      roles = (data['roles'] as List)
          .map((e) => Opcion(id: comoEntero((e as Map)['id_rol']), nombre: e['nombre'].toString()))
          .toList();
      final params = await api.enviar('GET', '/api/v1/parametros') as List;
      parametros = params.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Future<bool> guardarUsuario(Map<String, dynamic> datos, {int? id}) async {
    final ok = await _ejecutar(() async {
      if (id == null) {
        await api.enviar('POST', '/api/v1/usuarios', cuerpo: datos);
      } else {
        await api.enviar('PUT', '/api/v1/usuarios/$id', cuerpo: datos);
      }
      return true;
    });
    return ok == true;
  }

  Future<bool> crearCategoria(String nombre) async {
    final ok = await _ejecutar(() async {
      await api.enviar('POST', '/api/v1/categorias', cuerpo: {'nombre': nombre});
      return true;
    });
    return ok == true;
  }

  Future<bool> crearAutor(String nombres, String apellidos) async {
    final ok = await _ejecutar(() async {
      await api.enviar('POST', '/api/v1/autores', cuerpo: {'nombres': nombres, 'apellidos': apellidos});
      return true;
    });
    return ok == true;
  }

  Future<bool> crearEditorial(String nombre, String pais) async {
    final ok = await _ejecutar(() async {
      await api.enviar('POST', '/api/v1/editoriales', cuerpo: {'nombre': nombre, 'pais': pais});
      return true;
    });
    return ok == true;
  }

  Future<bool> guardarParametros(Map<String, String> valores) async {
    final ok = await _ejecutar(() async {
      final lista = await api.enviar('PUT', '/api/v1/parametros', cuerpo: valores) as List;
      parametros = lista.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return true;
    });
    return ok == true;
  }
}
