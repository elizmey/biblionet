import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/biblioteca_controller.dart';
import '../models/modelos.dart';
import '../theme/app_theme.dart';

class ReportesView extends StatefulWidget {
  const ReportesView({super.key});

  @override
  State<ReportesView> createState() => _ReportesViewState();
}

class _ReportesViewState extends State<ReportesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BibliotecaController>().cargarReportes());
  }

  String _hoy() {
    final ahora = DateTime.now();
    final mes = ahora.month.toString().padLeft(2, '0');
    final dia = ahora.day.toString().padLeft(2, '0');
    return '${ahora.year}-$mes-$dia';
  }

  int _veces(Map<String, dynamic> item) {
    return item['veces'] is int ? item['veces'] as int : int.tryParse('${item['veces']}') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<BibliotecaController>();
    final ind = datos.indicadores;
    final telefono = esAplicacionTelefono;
    final abiertos = datos.prestamos.where((p) => p.estado == 'ABIERTO').toList();
    final ejemplaresPrestados = abiertos.fold<int>(0, (suma, p) {
      return suma + p.detalles.where((d) => d.fechaDevolucion == null).length;
    });
    final maximo = datos.ranking.fold<int>(1, (prev, item) {
      final veces = _veces(item);
      return veces > prev ? veces : prev;
    });

    return ListView(
      padding: EdgeInsets.fromLTRB(telefono ? 16 : 28, 8, telefono ? 16 : 28, 28),
      children: [
        Text(
          'Informe de la biblioteca al $_hoy(). Resume los libros prestados, los que siguen fuera, los vencidos y las multas.',
          style: const TextStyle(color: Color(0xFF6B6280), height: 1.4),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () async {
              final resultado = await context.read<BibliotecaController>().exportarPdf();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultado ?? 'No se pudo exportar')));
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar informe PDF'),
          ),
        ),
        if (datos.error != null) ...[
          const SizedBox(height: 12),
          Text(datos.error!, style: const TextStyle(color: BiblioColors.rojo)),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _dato('Préstamos abiertos', '${ind['prestamos_abiertos'] ?? abiertos.length}'),
            _dato('Ejemplares fuera hoy', '$ejemplaresPrestados'),
            _dato('Préstamos vencidos', '${ind['prestamos_vencidos'] ?? datos.vencidos.length}', color: BiblioColors.rojo),
            _dato('Títulos en catálogo', '${ind['titulos'] ?? '—'}'),
            _dato('Ejemplares disponibles', '${ind['disponibles'] ?? '—'} / ${ind['ejemplares'] ?? '—'}'),
            _dato('Multas pendientes', 'USD ${comoDecimal(ind['multas_pendientes']).toStringAsFixed(2)}', color: BiblioColors.rojo),
          ],
        ),
        const SizedBox(height: 22),
        _seccion(
          'Libros prestados al día',
          'Ejemplares que todavía no se han devuelto.',
          abiertos.isEmpty
              ? [const Text('No hay libros prestados en este momento.')]
              : [
                  for (final prestamo in abiertos)
                    for (final detalle in prestamo.detalles.where((d) => d.fechaDevolucion == null))
                      _filaPrestamo(prestamo, detalle),
                ],
        ),
        _seccion(
          'Historial de préstamos',
          'Todos los préstamos registrados, abiertos y cerrados.',
          datos.prestamos.isEmpty
              ? [const Text('No hay préstamos registrados.')]
              : [
                  for (final prestamo in datos.prestamos)
                    for (final detalle in prestamo.detalles) _filaPrestamo(prestamo, detalle),
                ],
        ),
        _seccion(
          'Títulos más prestados',
          'Cuántas veces se prestó cada libro, de mayor a menor.',
          datos.ranking.isEmpty
              ? [const Text('Todavía no hay préstamos para armar este ranking.')]
              : [
                  for (final item in datos.ranking)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['titulo']} · ${_veces(item)} ${_veces(item) == 1 ? 'préstamo' : 'préstamos'}'),
                          const SizedBox(height: 4),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (_veces(item) / maximo).clamp(0.05, 1),
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(color: BiblioColors.morado, borderRadius: BorderRadius.circular(99)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
        ),
        _seccion(
          'Préstamos vencidos',
          'Libros que ya pasaron la fecha de devolución.',
          datos.vencidos.isEmpty
              ? [const Text('No hay préstamos vencidos.')]
              : [
                  for (final item in datos.vencidos)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${item['titulo'] ?? ''}'),
                      subtitle: Text('${item['socio'] ?? ''}'),
                      trailing: Text('${item['dias_retraso'] ?? 0} días', style: const TextStyle(color: BiblioColors.rojo, fontWeight: FontWeight.w700)),
                    ),
                ],
        ),
        _seccion(
          'Multas',
          'Tarifa vigente: USD ${datos.tarifa} por día de retraso.',
          datos.multas.isEmpty
              ? [const Text('No hay multas registradas.')]
              : [
                  for (final multa in datos.multas)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${multa.socio} · ${multa.titulo}'),
                      subtitle: Text('${multa.dias} días · ${multa.estado}'),
                      trailing: Text('USD ${multa.monto.toStringAsFixed(2)}'),
                    ),
                ],
        ),
      ],
    );
  }

  Widget _dato(String etiqueta, String valor, {Color? color}) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E0F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(color: Color(0xFF6B6280), fontSize: 13)),
          const SizedBox(height: 6),
          Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color ?? BiblioColors.morado)),
        ],
      ),
    );
  }

  Widget _seccion(String titulo, String ayuda, List<Widget> hijos) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7E0F2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: BiblioColors.morado)),
            const SizedBox(height: 4),
            Text(ayuda, style: const TextStyle(color: Color(0xFF6B6280), fontSize: 13)),
            const SizedBox(height: 12),
            ...hijos,
          ],
        ),
      ),
    );
  }

  Widget _filaPrestamo(Prestamo prestamo, DetallePrestamo detalle) {
    final devuelto = detalle.fechaDevolucion != null;
    final vencido = !devuelto && detalle.diasRetraso > 0;
    final estado = devuelto ? 'Devuelto ${fechaCorta(detalle.fechaDevolucion)}' : (vencido ? 'Vencido' : 'En préstamo');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(detalle.titulo),
      subtitle: Text('${prestamo.socio} · prestado ${fechaCorta(prestamo.fechaPrestamo)} · vence ${fechaCorta(prestamo.fechaVencimiento)}'),
      trailing: Text(
        estado,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: devuelto ? BiblioColors.verde : (vencido ? BiblioColors.rojo : BiblioColors.morado),
        ),
      ),
    );
  }
}
