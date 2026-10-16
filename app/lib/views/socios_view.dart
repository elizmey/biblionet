import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/biblioteca_controller.dart';
import '../models/modelos.dart';
import '../theme/app_theme.dart';

class SociosView extends StatefulWidget {
  const SociosView({super.key});

  @override
  State<SociosView> createState() => _SociosViewState();
}

class _SociosViewState extends State<SociosView> {
  final _busqueda = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BibliotecaController>().cargarSocios());
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _formulario([Socio? socio]) async {
    final codigo = TextEditingController(text: socio?.codigo ?? '');
    final cedula = TextEditingController(text: socio?.cedula ?? '');
    final nombres = TextEditingController(text: socio?.nombres ?? '');
    final apellidos = TextEditingController(text: socio?.apellidos ?? '');
    final correo = TextEditingController(text: socio?.correo ?? '');
    final telefono = TextEditingController(text: socio?.telefono ?? '');
    var tipo = socio?.tipo ?? 'ESTUDIANTE';
    var estado = socio?.estado ?? 'ACTIVO';
    final ok = await showDialog<bool>(
      context: context,
      builder: (contexto) {
        final vista = MediaQuery.sizeOf(contexto);
        return StatefulBuilder(builder: (contexto, setLocal) {
          Widget campo(Widget child) => Padding(padding: const EdgeInsets.only(bottom: 10), child: child);
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 440, maxHeight: vista.height - 40),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      socio == null ? 'Nuevo socio' : 'Editar socio',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: BiblioColors.morado),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            campo(TextField(controller: codigo, decoration: const InputDecoration(labelText: 'Código (vacío para generar)'))),
                            campo(TextField(controller: cedula, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cédula'))),
                            campo(TextField(controller: nombres, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nombres'))),
                            campo(TextField(controller: apellidos, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Apellidos'))),
                            campo(TextField(controller: correo, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo'))),
                            campo(TextField(controller: telefono, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono'))),
                            campo(DropdownButtonFormField<String>(
                              initialValue: tipo,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Tipo'),
                              items: const [
                                DropdownMenuItem(value: 'ESTUDIANTE', child: Text('Estudiante')),
                                DropdownMenuItem(value: 'DOCENTE', child: Text('Docente')),
                                DropdownMenuItem(value: 'ADMINISTRATIVO', child: Text('Administrativo')),
                              ],
                              onChanged: (valor) => setLocal(() => tipo = valor ?? tipo),
                            )),
                            campo(DropdownButtonFormField<String>(
                              initialValue: estado,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Estado'),
                              items: const [
                                DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
                                DropdownMenuItem(value: 'INACTIVO', child: Text('Inactivo')),
                                DropdownMenuItem(value: 'SANCIONADO', child: Text('Sancionado')),
                              ],
                              onChanged: (valor) => setLocal(() => estado = valor ?? estado),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
                        FilledButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Guardar')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
    if (ok == true && mounted) {
      final guardo = await context.read<BibliotecaController>().guardarSocio({
        'codigo': codigo.text.trim(),
        'cedula': cedula.text.trim(),
        'nombres': nombres.text.trim(),
        'apellidos': apellidos.text.trim(),
        'correo': correo.text.trim(),
        'telefono': telefono.text.trim(),
        'tipo_socio': tipo,
        'estado': estado,
      }, id: socio?.id);
      if (!mounted) return;
      final error = context.read<BibliotecaController>().error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(guardo ? 'Socio guardado' : (error ?? 'No se pudo guardar'))));
      if (guardo) await context.read<BibliotecaController>().cargarSocios(_busqueda.text);
    }
    codigo.dispose();
    cedula.dispose();
    nombres.dispose();
    apellidos.dispose();
    correo.dispose();
    telefono.dispose();
  }

  Future<void> _cambiarEstado(Socio socio) async {
    final copia = socio.toJson();
    copia['estado'] = socio.estado == 'ACTIVO' ? 'INACTIVO' : 'ACTIVO';
    final ok = await context.read<BibliotecaController>().guardarSocio(copia, id: socio.id);
    if (ok && mounted) {
      await context.read<BibliotecaController>().cargarSocios(_busqueda.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<BibliotecaController>();
    final movil = esAplicacionTelefono;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: movil
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _busqueda,
                      decoration: const InputDecoration(labelText: 'Buscar socio'),
                      onSubmitted: (valor) => datos.cargarSocios(valor),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(onPressed: () => _formulario(), icon: const Icon(Icons.person_add), label: const Text('Nuevo')),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _busqueda,
                        decoration: const InputDecoration(labelText: 'Buscar socio'),
                        onSubmitted: (valor) => datos.cargarSocios(valor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(onPressed: () => _formulario(), icon: const Icon(Icons.person_add), label: const Text('Nuevo')),
                  ],
                ),
        ),
        if (datos.error != null)
          Padding(padding: const EdgeInsets.all(12), child: Text(datos.error!, style: const TextStyle(color: BiblioColors.rojo))),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: datos.socios.length,
            itemBuilder: (context, i) {
              final socio = datos.socios[i];
              if (!movil) {
                return ListTile(
                  title: Text('${socio.nombreCompleto} · ${socio.codigo}'),
                  subtitle: Text('${socio.cedula} · ${socio.tipo} · ${socio.estado}'),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(tooltip: 'Editar', onPressed: () => _formulario(socio), icon: const Icon(Icons.edit)),
                      IconButton(
                        tooltip: socio.estado == 'ACTIVO' ? 'Inactivar' : 'Activar',
                        onPressed: () => _cambiarEstado(socio),
                        icon: Icon(socio.estado == 'ACTIVO' ? Icons.person_off : Icons.person),
                      ),
                    ],
                  ),
                );
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(socio.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${socio.codigo} · ${socio.cedula}'),
                      Text('${socio.tipo} · ${socio.estado}'),
                      Wrap(
                        children: [
                          TextButton.icon(onPressed: () => _formulario(socio), icon: const Icon(Icons.edit, size: 18), label: const Text('Editar')),
                          TextButton.icon(
                            onPressed: () => _cambiarEstado(socio),
                            icon: Icon(socio.estado == 'ACTIVO' ? Icons.person_off : Icons.person, size: 18),
                            label: Text(socio.estado == 'ACTIVO' ? 'Inactivar' : 'Activar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
