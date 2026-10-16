import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/biblioteca_controller.dart';
import '../theme/app_theme.dart';

class PanelView extends StatefulWidget {
  const PanelView({super.key});

  @override
  State<PanelView> createState() => _PanelViewState();
}

class _PanelViewState extends State<PanelView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BibliotecaController>().cargarPanel();
    });
  }

  String _hoy() {
    final ahora = DateTime.now();
    final mes = ahora.month.toString().padLeft(2, '0');
    final dia = ahora.day.toString().padLeft(2, '0');
    return '${ahora.year}-$mes-$dia';
  }

  Widget _caja({required Widget child, double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E0F2)),
      ),
      child: child,
    );
  }

  Widget _stat(String etiqueta, String valor, {Color? color}) {
    return _caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(color: Color(0xFF6B6280), fontSize: 13)),
          const SizedBox(height: 8),
          Text(valor, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color ?? BiblioColors.morado)),
        ],
      ),
    );
  }

  Widget _pastilla(String texto, Color fondo, Color tinta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(99)),
      child: Text(texto, style: TextStyle(color: tinta, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }

  (Color, Color) _colorStock(int disponibles) {
    if (disponibles <= 0) return (const Color(0xFFFBE1DF), BiblioColors.rojo);
    if (disponibles == 1) return (const Color(0xFFFFF0C2), BiblioColors.ambar);
    return (const Color(0xFFDDF3E6), BiblioColors.verde);
  }

  Widget _tabla(String titulo, List<Widget> filas) {
    return _caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, color: BiblioColors.morado)),
          const SizedBox(height: 12),
          ...filas,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<BibliotecaController>();
    if (esAplicacionTelefono) return _panelTelefono(datos);

    final ind = datos.indicadores;
    final ancho = MediaQuery.sizeOf(context).width;
    final multas = comoDecimal(ind['multas_pendientes']);
    final stats = [
      _stat('Títulos en catálogo', '${ind['titulos'] ?? '—'}'),
      _stat('Ejemplares disponibles', '${ind['disponibles'] ?? '—'} / ${ind['ejemplares'] ?? '—'}'),
      _stat('Socios activos', '${ind['socios_activos'] ?? '—'}'),
      _stat('Préstamos abiertos', '${ind['prestamos_abiertos'] ?? '—'}'),
      _stat('Préstamos vencidos', '${ind['prestamos_vencidos'] ?? '—'}', color: BiblioColors.rojo),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      children: [
        const Text('Panel de control', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: BiblioColors.morado)),
        const SizedBox(height: 4),
        Text('Resumen general de la biblioteca – ${_hoy()}', style: const TextStyle(color: Color(0xFF6B6280))),
        if (datos.error != null) ...[
          const SizedBox(height: 8),
          Text(datos.error!, style: const TextStyle(color: BiblioColors.rojo)),
        ],
        const SizedBox(height: 18),
        if (ancho >= 1180)
          Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: stats[i]),
              ],
            ],
          )
        else
          Wrap(spacing: 12, runSpacing: 12, children: [for (final item in stats) SizedBox(width: 210, child: item)]),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: _caja(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Multas pendientes', style: TextStyle(color: Color(0xFF6B6280), fontSize: 13)),
                const SizedBox(height: 6),
                Text('\$${multas.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: BiblioColors.rojo)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (ancho >= 1000)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _vencidos(datos)),
              const SizedBox(width: 14),
              Expanded(child: _stock(datos)),
            ],
          )
        else ...[
          _vencidos(datos),
          const SizedBox(height: 14),
          _stock(datos),
        ],
      ],
    );
  }

  Widget _encabezadoTabla(List<String> columnas, List<int> flex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
    );
  }

  Widget _vencidos(BibliotecaController datos) {
    return _tabla('Préstamos vencidos', [
      _encabezadoTabla(const ['Socio', 'Libro', 'Retraso'], const [3, 4, 2]),
      if (datos.vencidos.isEmpty)
        const Padding(padding: EdgeInsets.only(top: 12), child: Text('No hay préstamos vencidos'))
      else
        for (final item in datos.vencidos)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(item['socio']?.toString() ?? '')),
                Expanded(flex: 4, child: Text(item['titulo']?.toString() ?? '')),
                Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _pastilla('${item['dias_retraso']} días', const Color(0xFFFBE1DF), BiblioColors.rojo))),
              ],
            ),
          ),
    ]);
  }

  Widget _stock(BibliotecaController datos) {
    return _tabla('Stock bajo (≤ 1 disponible)', [
      _encabezadoTabla(const ['Título', 'Disp.'], const [5, 2]),
      if (datos.stockBajo.isEmpty)
        const Padding(padding: EdgeInsets.only(top: 12), child: Text('No hay títulos con stock bajo'))
      else
        for (final item in datos.stockBajo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Expanded(flex: 5, child: Text(item['titulo']?.toString() ?? '')),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Builder(builder: (_) {
                      final disponibles = comoEntero(item['disponibles']);
                      final total = comoEntero(item['total']);
                      final colores = _colorStock(disponibles);
                      return _pastilla('$disponibles de $total', colores.$1, colores.$2);
                    }),
                  ),
                ),
              ],
            ),
          ),
    ]);
  }

  Widget _panelTelefono(BibliotecaController datos) {
    final ind = datos.indicadores;
    final tarjetas = [
      ['Títulos', ind['titulos']],
      ['Disponibles', '${ind['disponibles'] ?? '—'} / ${ind['ejemplares'] ?? '—'}'],
      ['Socios activos', ind['socios_activos']],
      ['Préstamos abiertos', ind['prestamos_abiertos']],
      ['Préstamos vencidos', ind['prestamos_vencidos']],
      ['Multas pendientes', 'USD ${comoDecimal(ind['multas_pendientes']).toStringAsFixed(2)}'],
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (datos.error != null) Text(datos.error!, style: const TextStyle(color: BiblioColors.rojo)),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tarjeta in tarjetas)
              SizedBox(
                width: 180,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tarjeta[0].toString(), style: const TextStyle(color: BiblioColors.morado)),
                        const SizedBox(height: 8),
                        Text('${tarjeta[1] ?? '—'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Préstamos vencidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (datos.vencidos.isEmpty) const Text('No hay préstamos vencidos'),
        for (final item in datos.vencidos)
          ListTile(
            leading: const Icon(Icons.warning_amber, color: BiblioColors.rojo),
            title: Text(item['socio']?.toString() ?? ''),
            subtitle: Text(item['titulo']?.toString() ?? ''),
            trailing: Text('${item['dias_retraso']} días'),
          ),
        const SizedBox(height: 8),
        const Text('Stock bajo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (datos.stockBajo.isEmpty) const Text('No hay títulos con stock bajo'),
        for (final item in datos.stockBajo)
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined, color: BiblioColors.ambar),
            title: Text(item['titulo']?.toString() ?? ''),
            trailing: Text('${item['disponibles']} de ${item['total']}'),
          ),
      ],
    );
  }
}
