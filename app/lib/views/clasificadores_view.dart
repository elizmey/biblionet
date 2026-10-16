import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/biblioteca_controller.dart';
import '../theme/app_theme.dart';

class ClasificadoresView extends StatefulWidget {
  const ClasificadoresView({super.key});

  @override
  State<ClasificadoresView> createState() => _ClasificadoresViewState();
}

class _ClasificadoresViewState extends State<ClasificadoresView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BibliotecaController>().cargarClasificadores());
  }

  Future<void> _agregar(String tipo) async {
    final a = TextEditingController();
    final b = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text('Nueva ${tipo.toLowerCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: a, decoration: InputDecoration(labelText: tipo == 'Autor' ? 'Nombres' : 'Nombre')),
            if (tipo != 'Categoría')
              TextField(controller: b, decoration: InputDecoration(labelText: tipo == 'Autor' ? 'Apellidos' : 'País')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true || !mounted) {
      a.dispose();
      b.dispose();
      return;
    }
    final biblioteca = context.read<BibliotecaController>();
    final guardo = switch (tipo) {
      'Categoría' => await biblioteca.crearCategoria(a.text.trim()),
      'Autor' => await biblioteca.crearAutor(a.text.trim(), b.text.trim()),
      _ => await biblioteca.crearEditorial(a.text.trim(), b.text.trim()),
    };
    a.dispose();
    b.dispose();
    if (!mounted) return;
    if (guardo) await biblioteca.cargarClasificadores();
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<BibliotecaController>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      children: [
        const Text('Categorías, autores y editoriales del catálogo', style: TextStyle(color: Color(0xFF6B6280))),
        if (datos.error != null) ...[
          const SizedBox(height: 8),
          Text(datos.error!, style: const TextStyle(color: BiblioColors.rojo)),
        ],
        const SizedBox(height: 16),
        _bloque('Categorías', datos.categorias.map((e) => e.nombre).toList(), () => _agregar('Categoría')),
        const SizedBox(height: 14),
        _bloque('Autores', datos.autoresOpciones.map((e) => e.nombre).toList(), () => _agregar('Autor')),
        const SizedBox(height: 14),
        _bloque('Editoriales', datos.editoriales.map((e) => e.nombre).toList(), () => _agregar('Editorial')),
      ],
    );
  }

  Widget _bloque(String titulo, List<String> items, VoidCallback agregar) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E0F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, color: BiblioColors.morado))),
              TextButton(onPressed: agregar, child: const Text('Agregar')),
            ],
          ),
          if (items.isEmpty) const Text('Sin registros.'),
          for (final item in items) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(item)),
        ],
      ),
    );
  }
}
