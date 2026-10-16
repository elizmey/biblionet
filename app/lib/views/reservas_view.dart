import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/biblioteca_controller.dart';
import '../theme/app_theme.dart';

class ReservasView extends StatefulWidget {
  const ReservasView({super.key});

  @override
  State<ReservasView> createState() => _ReservasViewState();
}

class _ReservasViewState extends State<ReservasView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BibliotecaController>().cargarReservas());
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<BibliotecaController>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      children: [
        const Text('Reservas de títulos sin ejemplares disponibles', style: TextStyle(color: Color(0xFF6B6280))),
        if (datos.error != null) ...[
          const SizedBox(height: 8),
          Text(datos.error!, style: const TextStyle(color: BiblioColors.rojo)),
        ],
        const SizedBox(height: 14),
        if (datos.reservas.isEmpty)
          const Text('No hay reservas.')
        else
          for (final reserva in datos.reservas)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7E0F2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${reserva['titulo'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('${reserva['socio'] ?? ''} · ${reserva['estado'] ?? ''} · hasta ${fechaCorta(reserva['fecha_limite'])}'),
                      ],
                    ),
                  ),
                  if (reserva['estado'] == 'ACTIVA')
                    TextButton(
                      onPressed: () async {
                        final id = comoEntero(reserva['id_reserva']);
                        final ok = await context.read<BibliotecaController>().cancelarReserva(id);
                        if (!context.mounted) return;
                        if (ok) await context.read<BibliotecaController>().cargarReservas();
                      },
                      child: const Text('Cancelar'),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}
