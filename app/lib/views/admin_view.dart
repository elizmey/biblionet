import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/biblioteca_controller.dart';
import '../theme/app_theme.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final _dias = TextEditingController();
  final _maximo = TextEditingController();
  final _tarifa = TextEditingController();
  final _reserva = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BibliotecaController>().cargarAdmin();
      if (!mounted) return;
      _llenar();
    });
  }

  void _llenar() {
    final params = context.read<BibliotecaController>().parametros;
    String valor(String clave) {
      for (final item in params) {
        if (item['clave'] == clave) return item['valor']?.toString() ?? '';
      }
      return '';
    }

    _dias.text = valor('DIAS_PRESTAMO');
    _maximo.text = valor('MAX_PRESTAMOS');
    _tarifa.text = valor('MULTA_DIA');
    _reserva.text = valor('DIAS_RESERVA');
  }

  @override
  void dispose() {
    _dias.dispose();
    _maximo.dispose();
    _tarifa.dispose();
    _reserva.dispose();
    super.dispose();
  }

  Future<void> _usuario([Map<String, dynamic>? actual]) async {
    final nombres = TextEditingController(text: actual?['nombres']?.toString() ?? '');
    final apellidos = TextEditingController(text: actual?['apellidos']?.toString() ?? '');
    final usuario = TextEditingController(text: actual?['usuario']?.toString() ?? '');
    final clave = TextEditingController();
    final roles = context.read<BibliotecaController>().roles;
    var idRol = actual == null ? roles.first.id : (actual['id_rol'] is int ? actual['id_rol'] as int : int.parse('${actual['id_rol']}'));
    var activo = actual?['activo'] != false;
    var verClave = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (contexto) => StatefulBuilder(
        builder: (contexto, setLocal) => AlertDialog(
          title: Text(actual == null ? 'Nuevo usuario' : 'Editar usuario'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nombres, decoration: const InputDecoration(labelText: 'Nombres')),
                  TextField(controller: apellidos, decoration: const InputDecoration(labelText: 'Apellidos')),
                  TextField(controller: usuario, enabled: actual == null, decoration: const InputDecoration(labelText: 'Usuario')),
                  TextField(
                    controller: clave,
                    obscureText: !verClave,
                    decoration: InputDecoration(
                      labelText: actual == null ? 'Contraseña' : 'Nueva contraseña (opcional)',
                      suffixIcon: IconButton(
                        tooltip: verClave ? 'Ocultar contraseña' : 'Mostrar contraseña',
                        onPressed: () => setLocal(() => verClave = !verClave),
                        icon: Icon(verClave ? Icons.visibility_off : Icons.visibility),
                      ),
                    ),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: idRol,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: [for (final rol in roles) DropdownMenuItem(value: rol.id, child: Text(rol.nombre))],
                    onChanged: (valor) => setLocal(() => idRol = valor ?? idRol),
                  ),
                  SwitchListTile(value: activo, title: const Text('Activo'), onChanged: (valor) => setLocal(() => activo = valor)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (ok == true && mounted) {
      final cuerpo = {
        'nombres': nombres.text.trim(),
        'apellidos': apellidos.text.trim(),
        'usuario': usuario.text.trim(),
        'clave': clave.text,
        'id_rol': idRol,
        'activo': activo,
      };
      final id = actual == null ? null : (actual['id_usuario'] is int ? actual['id_usuario'] as int : int.parse('${actual['id_usuario']}'));
      final guardo = await context.read<BibliotecaController>().guardarUsuario(cuerpo, id: id);
      if (!mounted) return;
      final error = context.read<BibliotecaController>().error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(guardo ? 'Usuario guardado' : (error ?? 'No se pudo guardar'))));
      if (guardo) await context.read<BibliotecaController>().cargarAdmin();
    }
    nombres.dispose();
    apellidos.dispose();
    usuario.dispose();
    clave.dispose();
  }

  InputDecoration _campo(String etiqueta) {
    return InputDecoration(
      labelText: etiqueta,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D0E8))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D0E8))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final datos = context.watch<BibliotecaController>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      children: [
        if (datos.error != null) ...[
          Text(datos.error!, style: const TextStyle(color: BiblioColors.rojo)),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            const Expanded(
              child: Text('Usuarios y roles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2A2438))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: const StadiumBorder(),
              ),
              onPressed: datos.roles.isEmpty ? null : () => _usuario(),
              child: const Text('Nuevo usuario'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final usuario in datos.usuarios) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${usuario['nombres']} ${usuario['apellidos']} · ${usuario['usuario']}', style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        '${usuario['rol']} · ${usuario['activo'] == true ? 'Activo' : 'Inactivo'}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B6280), letterSpacing: 0.3),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => _usuario(usuario),
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF5C5670)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE4DDF0)),
        ],
        const SizedBox(height: 28),
        const Text('Parámetros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2A2438))),
        const SizedBox(height: 14),
        TextField(controller: _dias, keyboardType: TextInputType.number, decoration: _campo('Días de préstamo')),
        const SizedBox(height: 14),
        TextField(controller: _maximo, keyboardType: TextInputType.number, decoration: _campo('Máximo de ejemplares')),
        const SizedBox(height: 14),
        TextField(controller: _tarifa, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _campo('Multa por día (USD)')),
        const SizedBox(height: 14),
        TextField(controller: _reserva, keyboardType: TextInputType.number, decoration: _campo('Días de vigencia de la reserva')),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: const StadiumBorder(),
            ),
            onPressed: () async {
              final ok = await context.read<BibliotecaController>().guardarParametros({
                'DIAS_PRESTAMO': _dias.text.trim(),
                'MAX_PRESTAMOS': _maximo.text.trim(),
                'MULTA_DIA': _tarifa.text.trim(),
                'DIAS_RESERVA': _reserva.text.trim(),
              });
              if (!context.mounted) return;
              final error = context.read<BibliotecaController>().error;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Parámetros guardados' : (error ?? 'No se pudo guardar'))));
            },
            child: const Text('Guardar parámetros'),
          ),
        ),
      ],
    );
  }
}
