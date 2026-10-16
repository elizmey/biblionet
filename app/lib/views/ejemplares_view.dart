import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/biblioteca_controller.dart';
import '../theme/app_theme.dart';

class EjemplaresView extends StatefulWidget {
  const EjemplaresView({super.key});

  @override
  State<EjemplaresView> createState() => _EjemplaresViewState();
}

class _EjemplaresViewState extends State<EjemplaresView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BibliotecaController>().cargarEjemplares());
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<BibliotecaController>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      children: [
        const Text('Copias físicas registradas en el catálogo', style: TextStyle(color: Color(0xFF6B6280))),
        if (datos.error != null) ...[
          const SizedBox(height: 8),
          Text(datos.error!, style: const TextStyle(color: BiblioColors.rojo)),
        ],
        const SizedBox(height: 14),
        _tabla(
          const ['Código', 'Título', 'Ubicación', 'Estado'],
          const [2, 4, 2, 2],
          datos.listaEjemplares.isEmpty
              ? [const Text('No hay ejemplares.')]
              : [
                  for (final item in datos.listaEjemplares)
                    Row(
                      children: [
                        Expanded(flex: 2, child: Text(item.codigo)),
                        Expanded(flex: 4, child: Text(item.titulo)),
                        Expanded(flex: 2, child: Text(item.ubicacion)),
                        Expanded(flex: 2, child: Text(item.estado)),
                      ],
                    ),
                ],
        ),
      ],
    );
  }
}

Widget _tabla(List<String> columnas, List<int> flex, List<Widget> filas) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE7E0F2)),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFF4EFFA), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              for (var i = 0; i < columnas.length; i++)
                Expanded(
                  flex: flex[i],
                  child: Text(columnas[i], style: const TextStyle(fontWeight: FontWeight.w700, color: BiblioColors.morado, fontSize: 13)),
                ),
            ],
          ),
        ),
        for (final fila in filas)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: fila),
      ],
    ),
  );
}
