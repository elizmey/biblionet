import 'package:biblionet/controllers/auth_controller.dart';
import 'package:biblionet/services/api_service.dart';
import 'package:biblionet/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('la pantalla de ingreso muestra el botón Ingresar', (tester) async {
    final api = ApiService();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(api),
        child: const MaterialApp(home: LoginView()),
      ),
    );
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Biblionet'), findsOneWidget);
  });
}
