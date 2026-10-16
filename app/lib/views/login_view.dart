import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import 'registro_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  bool _verClave = false;

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    await context.read<AuthController>().ingresar(_usuario.text, _clave.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final ancho = MediaQuery.sizeOf(context).width;
    final amplio = ancho >= 860;
    final formulario = _formulario(auth);

    return Scaffold(
      backgroundColor: amplio ? BiblioColors.morado : BiblioColors.fondo,
      body: SafeArea(
        child: amplio
            ? Row(
                children: [
                  Expanded(child: _marca(compacta: false)),
                  Expanded(
                    child: ColoredBox(
                      color: BiblioColors.fondo,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: formulario),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  children: [
                    _marca(compacta: true),
                    const SizedBox(height: 22),
                    formulario,
                  ],
                ),
              ),
      ),
    );
  }

  Widget _marca({required bool compacta}) {
    final contenido = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: compacta ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: BiblioColors.amarillo, borderRadius: BorderRadius.circular(14)),
          child: const Text('B', style: TextStyle(color: BiblioColors.morado, fontWeight: FontWeight.w800, fontSize: 28)),
        ),
        const SizedBox(height: 16),
        Text(
          'Biblionet',
          textAlign: compacta ? TextAlign.center : TextAlign.start,
          style: TextStyle(color: compacta ? BiblioColors.morado : Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Sistema de gestión de biblioteca institucional',
          textAlign: compacta ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: compacta ? const Color(0xFF6B6280) : const Color(0xFFF6F3FB),
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Instituto Superior Universitario Japón',
          textAlign: compacta ? TextAlign.center : TextAlign.start,
          style: TextStyle(color: compacta ? const Color(0xFF6B6280) : const Color(0xFFD8CCEE), fontSize: 13),
        ),
      ],
    );

    if (compacta) return contenido;
    return Padding(padding: const EdgeInsets.all(48), child: contenido);
  }

  Widget _formulario(AuthController auth) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7E0F2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ingreso', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: BiblioColors.morado)),
            const SizedBox(height: 4),
            const Text('Use su usuario y contraseña', style: TextStyle(color: Color(0xFF6B6280))),
            const SizedBox(height: 20),
            TextField(
              controller: _usuario,
              decoration: const InputDecoration(labelText: 'Usuario'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _clave,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  tooltip: _verClave ? 'Ocultar contraseña' : 'Mostrar contraseña',
                  onPressed: () => setState(() => _verClave = !_verClave),
                  icon: Icon(_verClave ? Icons.visibility_off : Icons.visibility),
                ),
              ),
              obscureText: !_verClave,
              onSubmitted: (_) => _ingresar(),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(auth.error!, style: const TextStyle(color: BiblioColors.rojo)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: auth.cargando ? null : _ingresar,
              child: Text(auth.cargando ? 'Ingresando...' : 'Ingresar'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: auth.cargando
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegistroView())),
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
