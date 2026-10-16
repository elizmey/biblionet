import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/biblioteca_controller.dart';
import '../theme/app_theme.dart';

class AuditoriaView extends StatefulWidget {
  const AuditoriaView({super.key});

  @override
  State<AuditoriaView> createState() => _AuditoriaViewState();
}

class _AuditoriaViewState extends State<AuditoriaView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final biblioteca = context.read<BibliotecaController>();
      await biblioteca.cargarPrestamos(propios: false);
      if (!mounted) return;
      await biblioteca.cargarReservas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<BibliotecaController>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      children: [
        const Text('Movimientos recientes de préstamos y reservas', style: TextStyle(color: Color(0xFF6B6280))),
        if (datos.error != null) ...[
          const SizedBox(height: 8),
          Text(datos.error!, style: const TextStyle(color: BiblioColors.rojo)),
        ],
        const SizedBox(height: 16),
        const Text('Préstamos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: BiblioColors.morado)),
        const SizedBox(height: 8),
        if (datos.prestamos.isEmpty) const Text('No hay préstamos registrados.'),
        for (final prestamo in datos.prestamos.take(12))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${prestamo.socio} · ${prestamo.estado}'),
            subtitle: Text('Prestado ${fechaCorta(prestamo.fechaPrestamo)} · vence ${fechaCorta(prestamo.fechaVencimiento)} · ${prestamo.atendidoPor}'),
          ),
        const SizedBox(height: 12),
        const Text('Reservas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: BiblioColors.morado)),
        const SizedBox(height: 8),
        if (datos.reservas.isEmpty) const Text('No hay reservas registradas.'),
        for (final reserva in datos.reservas.take(12))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${reserva['titulo'] ?? ''}'),
            subtitle: Text('${reserva['socio'] ?? ''} · ${reserva['estado'] ?? ''} · ${fechaCorta(reserva['fecha_reserva'])}'),
          ),
      ],
    );
  }
}
