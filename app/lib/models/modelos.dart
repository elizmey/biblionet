import '../theme/app_theme.dart';

class Sesion {
  Sesion({
    required this.idUsuario,
    required this.nombres,
    required this.apellidos,
    required this.usuario,
    required this.rol,
    this.idSocio,
  });

  final int idUsuario;
  final String nombres;
  final String apellidos;
  final String usuario;
  final String rol;
  final int? idSocio;

  String get nombreCompleto => '$nombres $apellidos';
  bool get esAdmin => rol == 'ADMINISTRADOR';
  bool get esStaff => rol == 'ADMINISTRADOR' || rol == 'BIBLIOTECARIO';
  bool get esLector => rol == 'LECTOR';

  factory Sesion.fromJson(Map<String, dynamic> json) {
    return Sesion(
      idUsuario: comoEntero(json['id_usuario']),
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      usuario: json['usuario']?.toString() ?? '',
      rol: json['rol']?.toString() ?? '',
      idSocio: json['id_socio'] == null ? null : comoEntero(json['id_socio']),
    );
  }
}

class Libro {
  Libro({
    required this.id,
    required this.isbn,
    required this.titulo,
    required this.anio,
    required this.categoria,
    required this.editorial,
    required this.autores,
    required this.total,
    required this.disponibles,
    required this.idCategoria,
    required this.idEditorial,
    required this.idAutores,
  });

  final int id;
  final String isbn;
  final String titulo;
  final int anio;
  final String categoria;
  final String editorial;
  final String autores;
  final int total;
  final int disponibles;
  final int idCategoria;
  final int idEditorial;
  final List<int> idAutores;

  factory Libro.fromJson(Map<String, dynamic> json) {
    return Libro(
      id: comoEntero(json['id_libro']),
      isbn: json['isbn']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      anio: comoEntero(json['anio_publicacion']),
      categoria: json['categoria']?.toString() ?? '',
      editorial: json['editorial']?.toString() ?? '',
      autores: json['autores']?.toString() ?? '',
      total: comoEntero(json['total']),
      disponibles: comoEntero(json['disponibles']),
      idCategoria: comoEntero(json['id_categoria']),
      idEditorial: comoEntero(json['id_editorial']),
      idAutores: json['id_autores'] is List
          ? (json['id_autores'] as List).map(comoEntero).toList()
          : <int>[],
    );
  }
}

class Ejemplar {
  Ejemplar({
    required this.id,
    required this.idLibro,
    required this.codigo,
    required this.ubicacion,
    required this.estado,
    required this.titulo,
  });

  final int id;
  final int idLibro;
  final String codigo;
  final String ubicacion;
  final String estado;
  final String titulo;

  factory Ejemplar.fromJson(Map<String, dynamic> json) {
    return Ejemplar(
      id: comoEntero(json['id_ejemplar']),
      idLibro: comoEntero(json['id_libro']),
      codigo: json['codigo_barras']?.toString() ?? '',
      ubicacion: json['ubicacion']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
    );
  }
}

class Socio {
  Socio({
    required this.id,
    required this.codigo,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.telefono,
    required this.tipo,
    required this.estado,
  });

  final int id;
  final String codigo;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String correo;
  final String telefono;
  final String tipo;
  final String estado;

  String get nombreCompleto => '$nombres $apellidos';

  factory Socio.fromJson(Map<String, dynamic> json) {
    return Socio(
      id: comoEntero(json['id_socio']),
      codigo: json['codigo']?.toString() ?? '',
      cedula: json['cedula']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      tipo: json['tipo_socio']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'cedula': cedula,
        'nombres': nombres,
        'apellidos': apellidos,
        'correo': correo,
        'telefono': telefono,
        'tipo_socio': tipo,
        'estado': estado,
      };
}

class DetallePrestamo {
  DetallePrestamo({
    required this.idDetalle,
    required this.idEjemplar,
    required this.codigo,
    required this.titulo,
    required this.fechaDevolucion,
    required this.diasRetraso,
  });

  final int idDetalle;
  final int idEjemplar;
  final String codigo;
  final String titulo;
  final String? fechaDevolucion;
  final int diasRetraso;

  factory DetallePrestamo.fromJson(Map<String, dynamic> json) {
    return DetallePrestamo(
      idDetalle: comoEntero(json['id_detalle']),
      idEjemplar: comoEntero(json['id_ejemplar']),
      codigo: json['codigo_barras']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      fechaDevolucion: json['fecha_devolucion']?.toString(),
      diasRetraso: comoEntero(json['dias_retraso']),
    );
  }
}

class Prestamo {
  Prestamo({
    required this.id,
    required this.idSocio,
    required this.socio,
    required this.atendidoPor,
    required this.fechaPrestamo,
    required this.fechaVencimiento,
    required this.estado,
    required this.detalles,
  });

  final int id;
  final int idSocio;
  final String socio;
  final String atendidoPor;
  final String fechaPrestamo;
  final String fechaVencimiento;
  final String estado;
  final List<DetallePrestamo> detalles;

  factory Prestamo.fromJson(Map<String, dynamic> json) {
    final lista = (json['detalles'] as List? ?? []);
    return Prestamo(
      id: comoEntero(json['id_prestamo']),
      idSocio: comoEntero(json['id_socio']),
      socio: json['socio']?.toString() ?? '',
      atendidoPor: json['atendido_por']?.toString() ?? '',
      fechaPrestamo: json['fecha_prestamo']?.toString() ?? '',
      fechaVencimiento: json['fecha_vencimiento']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      detalles: lista.map((e) => DetallePrestamo.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}

class Multa {
  Multa({
    required this.id,
    required this.dias,
    required this.monto,
    required this.estado,
    required this.socio,
    required this.titulo,
    required this.codigo,
  });

  final int id;
  final int dias;
  final double monto;
  final String estado;
  final String socio;
  final String titulo;
  final String codigo;

  factory Multa.fromJson(Map<String, dynamic> json) {
    return Multa(
      id: comoEntero(json['id_multa']),
      dias: comoEntero(json['dias_retraso']),
      monto: comoDecimal(json['monto']),
      estado: json['estado']?.toString() ?? '',
      socio: json['socio']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      codigo: json['codigo_barras']?.toString() ?? '',
    );
  }
}

class Opcion {
  Opcion({required this.id, required this.nombre});
  final int id;
  final String nombre;
}
