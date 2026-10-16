import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/biblioteca_controller.dart';
import '../models/modelos.dart';
import '../theme/app_theme.dart';

class CatalogoView extends StatefulWidget {
  const CatalogoView({super.key});

  @override
  State<CatalogoView> createState() => _CatalogoViewState();
}

class _CatalogoViewState extends State<CatalogoView> {
  final _busqueda = TextEditingController();
  String? _categoria;
  bool _soloDisponibles = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _inicio());
  }

  Future<void> _inicio() async {
    await _buscar();
    if (!mounted) return;
    if (context.read<AuthController>().sesion?.esLector ?? false) {
      await context.read<BibliotecaController>().cargarReservas();
    }
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _buscar() {
    return context.read<BibliotecaController>().cargarCatalogo(
          q: _busqueda.text,
          categoria: _categoria,
          soloDisponibles: _soloDisponibles,
        );
  }

  Future<void> _prestar(Libro libro) async {
    final biblioteca = context.read<BibliotecaController>();
    final ejemplares = (await biblioteca.ejemplaresDe(libro.id)).where((e) => e.estado == 'DISPONIBLE').toList();
    await biblioteca.cargarSocios();
    if (!mounted) return;
    final socios = biblioteca.socios.where((s) => s.estado == 'ACTIVO').toList();
    int? idSocio = socios.isEmpty ? null : socios.first.id;
    final elegidos = <int>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (contexto) {
        return StatefulBuilder(
          builder: (contexto, setLocal) {
            return AlertDialog(
              title: Text('Prestar: ${libro.titulo}'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: idSocio,
                      decoration: const InputDecoration(labelText: 'Socio'),
                      items: [
                        for (final socio in socios)
                          DropdownMenuItem(value: socio.id, child: Text(socio.nombreCompleto)),
                      ],
                      onChanged: (valor) => setLocal(() => idSocio = valor),
                    ),
                    const SizedBox(height: 12),
                    for (final ejemplar in ejemplares)
                      CheckboxListTile(
                        value: elegidos.contains(ejemplar.id),
                        title: Text('${ejemplar.codigo} · ${ejemplar.ubicacion}'),
                        onChanged: (valor) => setLocal(() {
                          if (valor == true) {
                            elegidos.add(ejemplar.id);
                          } else {
                            elegidos.remove(ejemplar.id);
                          }
                        }),
                      ),
                    if (ejemplares.isEmpty) const Text('No hay ejemplares disponibles'),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: idSocio == null || elegidos.isEmpty ? null : () => Navigator.pop(contexto, true),
                  child: const Text('Registrar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok == true && idSocio != null && mounted) {
      final mensaje = await biblioteca.prestar(idSocio!, elegidos.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje ?? 'Listo')));
      await _buscar();
    }
  }

  Future<void> _reservar(Libro libro) async {
    final biblioteca = context.read<BibliotecaController>();
    final limite = await biblioteca.reservar(libro.id);
    if (!mounted) return;
    final texto = limite == null
        ? (biblioteca.error ?? 'No se pudo registrar la reserva')
        : 'Reserva registrada: «${libro.titulo}» hasta $limite.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BiblioColors.moradoOscuro,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        content: Text(texto),
      ),
    );
    if (limite != null) {
      await biblioteca.cargarReservas();
      await _buscar();
    }
  }

  bool _reservado(BibliotecaController datos, int idLibro) {
    return datos.reservas.any((reserva) {
      return comoEntero(reserva['id_libro']) == idLibro && reserva['estado'] == 'ACTIVA';
    });
  }

  Widget _fila(String etiqueta, Widget valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w800, color: BiblioColors.morado)),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: valor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjeta(Libro libro, bool esStaff, bool reservado) {
    final hay = libro.disponibles > 0;
    final colorDisp = libro.disponibles == 0
        ? BiblioColors.rojo
        : libro.disponibles == 1
            ? BiblioColors.ambar
            : BiblioColors.verde;
    final fondoDisp = libro.disponibles == 0
        ? const Color(0xFFFBE1DF)
        : libro.disponibles == 1
            ? const Color(0xFFFFF0C2)
            : const Color(0xFFDDF3E6);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7E0F2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fila(
              reservado ? '● Título' : 'Título',
              Text(libro.titulo, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            _fila('ISBN', Text(libro.isbn, textAlign: TextAlign.right)),
            _fila('Autor(es)', Text(libro.autores, textAlign: TextAlign.right)),
            _fila('Categoría', Text(libro.categoria, textAlign: TextAlign.right)),
            _fila('Año', Text('${libro.anio}', textAlign: TextAlign.right)),
            _fila(
              'Disponibilidad',
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(color: fondoDisp, borderRadius: BorderRadius.circular(99)),
                child: Text(
                  '${libro.disponibles} de ${libro.total}',
                  style: TextStyle(color: colorDisp, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
              if (esStaff)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: hay ? () => _prestar(libro) : null,
                  child: const Text('Prestar'),
                ),
              )
            else if (hay)
              const Text(
                'Hay ejemplares: solicítelo en ventanilla',
                style: TextStyle(color: Color(0xFF6B6280), fontSize: 13),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton(
                    onPressed: reservado ? null : () => _reservar(libro),
                    child: const Text('Reservar'),
                  ),
                  Text(
                    reservado ? 'Reserva activa' : 'Sin ejemplares disponibles',
                    style: const TextStyle(color: Color(0xFF6B6280), fontSize: 13),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<BibliotecaController>();
    final esStaff = context.watch<AuthController>().sesion?.esStaff ?? false;
    final ancho = MediaQuery.sizeOf(context).width;
    final movil = esAplicacionTelefono;
    final columnas = ancho >= 1100 ? 3 : ancho >= 700 ? 2 : 1;

    final busqueda = TextField(
      controller: _busqueda,
      decoration: InputDecoration(
        hintText: 'Buscar...',
        prefixIcon: movil ? const Icon(Icons.search) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E0F2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E0F2))),
      ),
      onSubmitted: (_) => _buscar(),
    );
    final categoria = DropdownButtonFormField<String?>(
      initialValue: _categoria,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: movil ? 'Categoría' : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E0F2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE7E0F2))),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Todas las categorías')),
        for (final item in datos.categorias)
          DropdownMenuItem<String?>(value: '${item.id}', child: Text(item.nombre, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (valor) {
        setState(() => _categoria = valor);
        _buscar();
      },
    );
    final solo = movil
        ? FilterChip(
            label: const Text('Solo disponibles'),
            selected: _soloDisponibles,
            onSelected: (valor) {
              setState(() => _soloDisponibles = valor);
              _buscar();
            },
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _soloDisponibles,
                activeColor: BiblioColors.morado,
                onChanged: (valor) {
                  setState(() => _soloDisponibles = valor ?? false);
                  _buscar();
                },
              ),
              const Text('Solo disponibles'),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(movil ? 16 : 28, movil ? 8 : 24, movil ? 16 : 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!movil) ...[
                const Text('Catálogo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: BiblioColors.morado)),
                const SizedBox(height: 4),
              ],
              const Text(
                'Busca por título, autor o ISBN',
                style: TextStyle(color: Color(0xFF6B6280), fontSize: 13),
              ),
              const SizedBox(height: 14),
              if (movil) ...[
                busqueda,
                const SizedBox(height: 10),
                categoria,
                const SizedBox(height: 8),
                solo,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: busqueda),
                    const SizedBox(width: 12),
                    SizedBox(width: 240, child: categoria),
                    const SizedBox(width: 8),
                    solo,
                  ],
                ),
            ],
          ),
        ),
        if (datos.error != null)
          Padding(padding: const EdgeInsets.all(12), child: Text(datos.error!, style: const TextStyle(color: BiblioColors.rojo))),
        Expanded(
          child: movil
              ? ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: datos.libros.isEmpty ? 1 : datos.libros.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (datos.libros.isEmpty) return const Text('Sin resultados.');
                    final libro = datos.libros[i];
                    return _tarjeta(libro, esStaff, _reservado(datos, libro.id));
                  },
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnas,
                    mainAxisExtent: 292,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: datos.libros.length,
                  itemBuilder: (context, i) {
                    final libro = datos.libros[i];
                    return _tarjeta(libro, esStaff, _reservado(datos, libro.id));
                  },
                ),
        ),
      ],
    );
  }
}
