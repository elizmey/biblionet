import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import 'admin_view.dart';
import 'auditoria_view.dart';
import 'catalogo_view.dart';
import 'clasificadores_view.dart';
import 'ejemplares_view.dart';
import 'multas_view.dart';
import 'panel_view.dart';
import 'prestamos_view.dart';
import 'reportes_view.dart';
import 'reservas_view.dart';
import 'socios_view.dart';
import 'sql_docs_view.dart';

class _Destino {
  const _Destino(this.id, this.titulo, this.icono, this.iconoActivo, {this.corto, this.secundario = false});
  final String id;
  final String titulo;
  final IconData icono;
  final IconData iconoActivo;
  final String? corto;
  final bool secundario;

  /// Etiqueta compacta para la barra inferior del celular.
  String get etiqueta => corto ?? titulo;
}

/// Máximo de botones visibles en la barra inferior antes de agrupar en "Más".
const _maxBotonesMovil = 5;

class ShellView extends StatefulWidget {
  const ShellView({super.key});

  @override
  State<ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<ShellView> {
  int indice = 0;
  bool _masAbierto = true;

  List<_Destino> _destinos(AuthController auth) {
    final todos = <_Destino>[
      if (auth.sesion!.esStaff) const _Destino('panel', 'Panel', Icons.grid_view_outlined, Icons.grid_view_rounded),
      const _Destino('catalogo', 'Catálogo', Icons.menu_book_outlined, Icons.menu_book),
      if (auth.sesion!.esStaff) const _Destino('socios', 'Socios', Icons.people_outline, Icons.people),
      _Destino('prestamos', auth.sesion!.esLector ? 'Mis préstamos' : 'Préstamos', Icons.sync, Icons.sync),
      if (auth.sesion!.esStaff) const _Destino('multas', 'Multas', Icons.credit_card_outlined, Icons.credit_card),
      if (auth.sesion!.esStaff) const _Destino('reportes', 'Reportes', Icons.bar_chart_outlined, Icons.bar_chart),
      if (auth.sesion!.esAdmin) const _Destino('admin', 'Administración', Icons.settings_outlined, Icons.settings, corto: 'Admin'),
      if (auth.sesion!.esAdmin) ...[
        const _Destino('ejemplares', 'Ejemplares', Icons.inventory_2_outlined, Icons.inventory_2, secundario: true),
        const _Destino('reservas', 'Reservas', Icons.bookmark_border, Icons.bookmark, secundario: true),
        const _Destino('clasificadores', 'Clasificadores', Icons.folder_outlined, Icons.folder, secundario: true, corto: 'Clases'),
        const _Destino('auditoria', 'Auditoría', Icons.shield_outlined, Icons.shield, secundario: true),
        const _Destino('sql', 'SQL & Docs', Icons.code, Icons.code, secundario: true, corto: 'SQL'),
      ],
    ];
    return todos;
  }

  Widget _pagina(String id) {
    switch (id) {
      case 'panel':
        return const PanelView();
      case 'catalogo':
        return const CatalogoView();
      case 'socios':
        return const SociosView();
      case 'prestamos':
        return const PrestamosView();
      case 'multas':
        return const MultasView();
      case 'reportes':
        return const ReportesView();
      case 'admin':
        return const AdminView();
      case 'ejemplares':
        return const EjemplaresView();
      case 'reservas':
        return const ReservasView();
      case 'clasificadores':
        return const ClasificadoresView();
      case 'auditoria':
        return const AuditoriaView();
      case 'sql':
        return const SqlDocsView();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final destinos = _destinos(auth);
    if (indice >= destinos.length) indice = 0;
    if (!esAplicacionTelefono) return _escritorio(context, auth, destinos);
    return _telefono(context, auth, destinos);
  }

  Widget _escritorio(BuildContext context, AuthController auth, List<_Destino> destinos) {
    final ancho = MediaQuery.sizeOf(context).width;
    final id = destinos[indice].id;
    final conTituloPropio = id == 'catalogo' || id == 'panel';
    return Scaffold(
      backgroundColor: BiblioColors.fondo,
      body: Row(
        children: [
          _barraLateral(auth, destinos, compacta: ancho < 860),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!conTituloPropio)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                    child: Text(
                      destinos[indice].titulo,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: BiblioColors.morado),
                    ),
                  ),
                Expanded(child: _pagina(id)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barraLateral(AuthController auth, List<_Destino> destinos, {required bool compacta}) {
    final sesion = auth.sesion!;
    return Container(
      width: compacta ? 84 : 248,
      color: BiblioColors.morado,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(compacta ? 16 : 20, 22, 16, 18),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: BiblioColors.amarillo, borderRadius: BorderRadius.circular(10)),
                  child: const Text('B', style: TextStyle(color: BiblioColors.morado, fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                if (!compacta) ...[
                  const SizedBox(width: 10),
                  const Text('Biblionet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (var i = 0; i < destinos.length; i++)
                  if (!destinos[i].secundario) _filaMenu(i, destinos[i], compacta),
                if (destinos.any((d) => d.secundario)) ...[
                  if (!compacta)
                    InkWell(
                      onTap: () => setState(() => _masAbierto = !_masAbierto),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _masAbierto ? 'MENOS OPCIONES' : 'MÁS OPCIONES',
                                style: const TextStyle(color: Color(0xFFD8CCEE), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                              ),
                            ),
                            Icon(_masAbierto ? Icons.expand_less : Icons.expand_more, color: const Color(0xFFD8CCEE), size: 18),
                          ],
                        ),
                      ),
                    ),
                  if (_masAbierto || compacta)
                    for (var i = 0; i < destinos.length; i++)
                      if (destinos[i].secundario) _filaMenu(i, destinos[i], compacta),
                ],
              ],
            ),
          ),
          if (!compacta)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0x55FFFFFF), height: 1),
                  const SizedBox(height: 14),
                  Text(sesion.nombreCompleto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(_rolLegible(sesion.rol), style: const TextStyle(color: Color(0xFFD8CCEE), fontSize: 13)),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: auth.salir,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: BiblioColors.morado,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Cerrar sesión', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )
          else
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: auth.salir,
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _filaMenu(int i, _Destino destino, bool compacta) {
    final activo = i == indice;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: activo ? BiblioColors.amarillo : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => indice = i),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compacta ? 0 : 12, vertical: 11),
            child: Row(
              mainAxisAlignment: compacta ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(activo ? destino.iconoActivo : destino.icono, size: 20, color: activo ? BiblioColors.morado : Colors.white),
                if (!compacta) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destino.titulo,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, color: activo ? BiblioColors.morado : Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _rolLegible(String rol) {
    switch (rol) {
      case 'ADMINISTRADOR':
        return 'Administrador';
      case 'BIBLIOTECARIO':
        return 'Bibliotecario';
      case 'LECTOR':
        return 'Lector';
      default:
        return rol;
    }
  }

  Widget _telefono(BuildContext context, AuthController auth, List<_Destino> destinos) {
    final cuerpo = _pagina(destinos[indice].id);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: BiblioColors.fondo,
        foregroundColor: BiblioColors.morado,
        elevation: 0,
        title: _marca(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: auth.salir,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEDE6F8),
                foregroundColor: BiblioColors.morado,
                minimumSize: const Size(64, 40),
              ),
              child: const Text('Salir', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              destinos[indice].titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: BiblioColors.morado),
            ),
          ),
          Expanded(child: cuerpo),
        ],
      ),
      bottomNavigationBar: _barraInferior(context, destinos),
    );
  }

  // ---------------------------------------------------------------------------
  // Navegación para celulares
  // ---------------------------------------------------------------------------

  Widget _barraInferior(BuildContext context, List<_Destino> destinos) {
    final agrupar = destinos.length > _maxBotonesMovil;
    final visibles = agrupar ? destinos.sublist(0, _maxBotonesMovil - 1) : destinos;
    final extras = agrupar ? destinos.sublist(_maxBotonesMovil - 1) : const <_Destino>[];
    final enExtras = agrupar && indice >= visibles.length;
    final seleccionado = enExtras ? visibles.length : indice;

    if (esAplicacionTelefono && !agrupar) {
      return Container(
        decoration: BoxDecoration(
          color: BiblioColors.moradoOscuro,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                for (var i = 0; i < destinos.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Material(
                        color: i == indice ? BiblioColors.amarillo : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => indice = i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                            child: Text(
                              destinos[i].etiqueta,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: i == indice ? BiblioColors.moradoOscuro : const Color(0xFFD8CCEE),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: esAplicacionTelefono ? BiblioColors.moradoOscuro : BiblioColors.morado,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 68,
          indicatorColor: BiblioColors.amarillo,
          indicatorShape: const StadiumBorder(),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((estados) {
            final activo = estados.contains(WidgetState.selected);
            return IconThemeData(color: activo ? BiblioColors.morado : Colors.white70, size: 24);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((estados) {
            final activo = estados.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11.5,
              letterSpacing: 0.1,
              fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
              color: activo ? BiblioColors.amarillo : Colors.white70,
              overflow: TextOverflow.ellipsis,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: seleccionado,
          animationDuration: const Duration(milliseconds: 350),
          onDestinationSelected: (valor) {
            if (agrupar && valor == visibles.length) {
              _abrirMas(context, extras, visibles.length);
            } else {
              setState(() => indice = valor);
            }
          },
          destinations: [
            for (final destino in visibles)
              NavigationDestination(
                icon: Icon(destino.icono),
                selectedIcon: Icon(destino.iconoActivo),
                label: destino.etiqueta,
                tooltip: destino.titulo,
              ),
            if (agrupar)
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: enExtras,
                  backgroundColor: BiblioColors.amarillo,
                  smallSize: 8,
                  child: const Icon(Icons.grid_view_outlined),
                ),
                selectedIcon: const Icon(Icons.grid_view_rounded),
                label: enExtras ? destinos[indice].etiqueta : 'Más',
                tooltip: 'Más opciones',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirMas(BuildContext context, List<_Destino> extras, int desplazamiento) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (hoja) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Más opciones',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: BiblioColors.morado),
                ),
              ),
              for (var i = 0; i < extras.length; i++)
                _opcionMas(hoja, extras[i], desplazamiento + i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opcionMas(BuildContext hoja, _Destino destino, int posicion) {
    final activo = posicion == indice;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: activo ? BiblioColors.morado : BiblioColors.fondo,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(hoja).pop();
            setState(() => indice = posicion);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activo ? BiblioColors.amarillo : BiblioColors.morado.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    activo ? destino.iconoActivo : destino.icono,
                    color: BiblioColors.morado,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    destino.titulo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: activo ? Colors.white : BiblioColors.morado,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: activo ? BiblioColors.amarillo : Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _marca() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: BiblioColors.amarillo, borderRadius: BorderRadius.circular(8)),
          child: const Text('B', style: TextStyle(color: BiblioColors.moradoOscuro, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 8),
        const Text('Biblionet', style: TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }

}
