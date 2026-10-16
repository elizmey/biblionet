import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SqlDocsView extends StatelessWidget {
  const SqlDocsView({super.key});

  @override
  Widget build(BuildContext context) {
    const tablas = [
      ['sert_rol', 'Administrador, bibliotecario y lector'],
      ['sert_usuario', 'Cuentas de acceso y su rol'],
      ['sert_socio', 'Estudiantes, docentes y administrativos'],
      ['sert_categoria', 'Clasificación de los títulos'],
      ['sert_autor', 'Autores del catálogo'],
      ['sert_editorial', 'Editoriales'],
      ['sert_libro', 'Títulos del catálogo'],
      ['sert_ejemplar', 'Copias físicas y su estado'],
      ['sert_reserva', 'Reservas cuando no hay ejemplares'],
      ['sert_prestamo', 'Préstamos abiertos o cerrados'],
      ['sert_detalle_prestamo', 'Ejemplar prestado y su devolución'],
      ['sert_multa', 'Multa por retraso'],
      ['sert_parametro', 'Días de préstamo, tope, tarifa y vigencia de reserva'],
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      children: [
        const Text(
          'El script de la base está en database/sert_biblioteca.sql. La API no ejecuta SQL escrito a mano: cada pantalla usa sus rutas REST.',
          style: TextStyle(color: Color(0xFF6B6280), height: 1.4),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7E0F2)),
          ),
          child: Column(
            children: [
              for (final tabla in tablas)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 190,
                        child: Text(tabla[0], style: const TextStyle(fontWeight: FontWeight.w800, color: BiblioColors.morado)),
                      ),
                      Expanded(child: Text(tabla[1])),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
