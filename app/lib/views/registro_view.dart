import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _cedula = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  final _confirmar = TextEditingController();
  String _tipo = 'ESTUDIANTE';
  String? _aviso;

  @override
  void dispose() {
    _nombres.dispose();
    _apellidos.dispose();
    _cedula.dispose();
    _correo.dispose();
    _telefono.dispose();
    _usuario.dispose();
    _clave.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final aviso = _validar();
    if (aviso != null) {
      setState(() => _aviso = aviso);
      return;
    }
    setState(() => _aviso = null);
    final auth = context.read<AuthController>();
    final ok = await auth.registrar({
      'nombres': _nombres.text.trim(),
      'apellidos': _apellidos.text.trim(),
      'cedula': _cedula.text.trim(),
      'correo': _correo.text.trim(),
      'telefono': _telefono.text.trim(),
      'tipo_socio': _tipo,
      'usuario': _usuario.text.trim(),
      'clave': _clave.text,
    });
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    }
  }

  String? _validar() {
    if (_nombres.text.trim().length < 2 || _apellidos.text.trim().length < 2) {
      return 'Ingresa nombres y apellidos';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(_cedula.text.trim())) {
      return 'La cédula debe tener 10 dígitos';
    }
    final correo = _correo.text.trim();
    if (correo.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      return 'El correo no es válido';
    }
    if (!RegExp(r'^[a-zA-Z0-9._]{4,40}$').hasMatch(_usuario.text.trim())) {
      return 'El usuario debe tener de 4 a 40 caracteres, sin espacios';
    }
    if (_clave.text.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (_clave.text != _confirmar.text) return 'Las contraseñas no coinciden';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final mensaje = _aviso ?? auth.error;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: BiblioColors.fondo,
        foregroundColor: BiblioColors.morado,
        elevation: 0,
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Registro de lector',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: BiblioColors.morado,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Crea tu cuenta para consultar el catálogo y reservar desde el teléfono.',
                        style: TextStyle(
                          color: Color(0xFF6B6280),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nombres,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Nombres'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _apellidos,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cedula,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(labelText: 'Cédula'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _correo,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _telefono,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _tipo,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de socio',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'ESTUDIANTE',
                            child: Text('Estudiante'),
                          ),
                          DropdownMenuItem(
                            value: 'DOCENTE',
                            child: Text('Docente'),
                          ),
                        ],
                        onChanged: (valor) =>
                            setState(() => _tipo = valor ?? 'ESTUDIANTE'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _usuario,
                        decoration: const InputDecoration(labelText: 'Usuario'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _clave,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmar,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña',
                        ),
                        onSubmitted: (_) => _crear(),
                      ),
                      if (mensaje != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          mensaje,
                          style: const TextStyle(color: BiblioColors.rojo),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: auth.cargando ? null : _crear,
                        child: Text(
                          auth.cargando ? 'Creando cuenta...' : 'Crear cuenta',
                        ),
                      ),
                      TextButton(
                        onPressed: auth.cargando
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Ya tengo cuenta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
