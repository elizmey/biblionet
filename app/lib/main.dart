import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/biblioteca_controller.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/shell_view.dart';

void main() {
  final api = ApiService();
  runApp(BiblionetApp(api: api));
}

class BiblionetApp extends StatelessWidget {
  const BiblionetApp({super.key, required this.api});

  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: api),
        ChangeNotifierProvider(create: (_) => AuthController(api)),
        ChangeNotifierProvider(create: (_) => BibliotecaController(api)),
      ],
      child: MaterialApp(
        title: 'Biblionet',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: const Puerta(),
      ),
    );
  }
}

class Puerta extends StatelessWidget {
  const Puerta({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<AuthController>().sesion;
    return sesion == null ? const LoginView() : const ShellView();
  }
}
