import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/biblioteca_controller.dart';
import '../theme/app_theme.dart';

class MultasView extends StatefulWidget {
  const MultasView({super.key});

  @override
  State<MultasView> createState() => _MultasViewState();
}

class _MultasViewState extends State<MultasView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BibliotecaController>().cargarMultas());
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<BibliotecaController>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tarifa vigente: USD ${datos.tarifa} por día', style: const TextStyle(fontWeight: FontWeight.bold)),
        if (datos.error != null) Text(datos.error!, style: const TextStyle(color: BiblioColors.rojo)),
        const SizedBox(height: 8),
        for (final multa in datos.multas)
          Card(
            child: ListTile(
              title: Text('${multa.socio} · USD ${multa.monto.toStringAsFixed(2)}'),
              subtitle: Text('${multa.titulo} · ${multa.dias} días · ${multa.estado}'),
              trailing: multa.estado == 'PENDIENTE'
                  ? FilledButton(
                      onPressed: () async {
                        final ok = await context.read<BibliotecaController>().pagarMulta(multa.id);
                        if (ok && context.mounted) {
                          await context.read<BibliotecaController>().cargarMultas();
                        }
                      },
                      child: const Text('Registrar pago'),
                    )
                  : const Icon(Icons.check_circle, color: BiblioColors.verde),
            ),
          ),
      ],
    );
  }
}
