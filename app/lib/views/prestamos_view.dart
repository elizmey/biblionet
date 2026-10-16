import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/biblioteca_controller.dart';
import '../theme/app_theme.dart';

class PrestamosView extends StatefulWidget {
  const PrestamosView({super.key});

  @override
  State<PrestamosView> createState() => _PrestamosViewState();
}

class _PrestamosViewState extends State<PrestamosView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final propios = context.read<AuthController>().sesion?.esLector ?? false;
    final biblioteca = context.read<BibliotecaController>();
    await biblioteca.cargarPrestamos(propios: propios);
    if (!propios || !mounted) return;
    await biblioteca.cargarReservas();
    if (!mounted) return;
    await biblioteca.cargarMultasPropias();
  }

  Future<void> _devolver(int idPrestamo, int idDetalle) async {
    final mensaje = await context.read<BibliotecaController>().devolver(idPrestamo, idDetalle);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje ?? 'Listo')));
    await _cargar();
  }

  Widget _fila(String etiqueta, Widget valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w800, color: BiblioColors.morado)),
          ),
          Expanded(child: Align(alignment: Alignment.centerRight, child: valor)),
        ],
      ),
    );
  }

  Widget _estado(dynamic detalle) {
    if (detalle.fechaDevolucion != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFFDDF3E6), borderRadius: BorderRadius.circular(99)),
        child: Text(
          'Devuelto ${fechaCorta(detalle.fechaDevolucion)}',
          style: const TextStyle(color: BiblioColors.verde, fontWeight: FontWeight.w800, fontSize: 12),
        ),
      );
    }
    final vencido = detalle.diasRetraso > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: vencido ? const Color(0xFFFBE1DF) : const Color(0xFFEDE6F8),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        vencido ? 'Vencido' : 'Vigente',
        style: TextStyle(
          color: vencido ? BiblioColors.rojo : BiblioColors.morado,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<BibliotecaController>();
    final esStaff = context.watch<AuthController>().sesion?.esStaff ?? false;
    final lectorMovil = esAplicacionTelefono && !esStaff;
    final reservasActivas = datos.reservas.where((reserva) => reserva['estado'] == 'ACTIVA').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (lectorMovil) ...[
          const Text(
            'Consulta tus préstamos vigentes, vencidos e históricos',
            style: TextStyle(color: Color(0xFF6B6280), fontSize: 13),
          ),
          const SizedBox(height: 12),
        ],
        if (lectorMovil && datos.deudaPendiente > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4CC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0D98A)),
            ),
            child: Text(
              'Tiene multas pendientes por USD ${datos.deudaPendiente.toStringAsFixed(2).replaceAll('.', ',')}. Puede pagarlas en ventanilla.',
              style: const TextStyle(color: Color(0xFF6A5200), height: 1.4),
            ),
          ),
        if (datos.error != null) Text(datos.error!, style: const TextStyle(color: BiblioColors.rojo)),
        if (datos.prestamos.isEmpty) const Text('No hay préstamos para mostrar'),
        for (final prestamo in datos.prestamos)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: lectorMovil
                  ? Column(
                      children: [
                        for (final detalle in prestamo.detalles) ...[
                          _fila('#', Text('${prestamo.id}')),
                          _fila('Libro', Text(detalle.titulo, textAlign: TextAlign.right)),
                          _fila('Vence', Text(fechaCorta(prestamo.fechaVencimiento))),
                          _fila('Estado', _estado(detalle)),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${prestamo.socio} · ${prestamo.estado}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Prestado ${fechaCorta(prestamo.fechaPrestamo)} · vence ${fechaCorta(prestamo.fechaVencimiento)} · atendió ${prestamo.atendidoPor}'),
                        for (final detalle in prestamo.detalles)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(detalle.titulo),
                            subtitle: Text(detalle.codigo),
                            trailing: detalle.fechaDevolucion != null
                                ? Text('Devuelto ${fechaCorta(detalle.fechaDevolucion)}')
                                : esStaff
                                    ? FilledButton(
                                        onPressed: () => _devolver(prestamo.id, detalle.idDetalle),
                                        child: Text(detalle.diasRetraso > 0 ? 'Devolver (${detalle.diasRetraso} días)' : 'Devolver'),
                                      )
                                    : _estado(detalle),
                          ),
                      ],
                    ),
            ),
          ),
        if (lectorMovil) ...[
          const SizedBox(height: 8),
          const Text('Mis reservas activas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: BiblioColors.morado)),
          const SizedBox(height: 10),
          if (reservasActivas.isEmpty) const Text('No tienes reservas activas.'),
          for (final reserva in reservasActivas)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _fila('Libro', Text('${reserva['titulo'] ?? ''}', textAlign: TextAlign.right)),
                    _fila('Hasta', Text(fechaCorta(reserva['fecha_limite']))),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
