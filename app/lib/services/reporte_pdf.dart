import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/modelos.dart';
import '../theme/app_theme.dart';

Future<List<int>> construirReportePdf({
  required Map<String, dynamic> indicadores,
  required List<Map<String, dynamic>> ranking,
  required List<Map<String, dynamic>> vencidos,
  required List<Multa> multas,
  required List<Prestamo> prestamos,
}) async {
  final documento = pw.Document();
  final ahora = DateTime.now();
  final mes = ahora.month.toString().padLeft(2, '0');
  final dia = ahora.day.toString().padLeft(2, '0');
  const morado = PdfColor.fromInt(0xFF4B2A7B);
  final abiertos = prestamos.where((p) => p.estado == 'ABIERTO').toList();

  pw.Widget tabla(String titulo, String ayuda, List<String> columnas, List<List<String>> filas) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(titulo, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: morado)),
        pw.SizedBox(height: 3),
        pw.Text(ayuda, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 8),
        if (filas.isEmpty)
          pw.Text('Sin registros.')
        else
          pw.TableHelper.fromTextArray(
            headers: columnas,
            data: filas,
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: morado),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {for (var i = 0; i < columnas.length; i++) i: pw.Alignment.centerLeft},
            oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF6F3FB)),
          ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  List<List<String>> filasPrestamo(List<Prestamo> lista, {bool soloAbiertos = false}) {
    final filas = <List<String>>[];
    for (final prestamo in lista) {
      for (final detalle in prestamo.detalles) {
        if (soloAbiertos && detalle.fechaDevolucion != null) continue;
        final devuelto = detalle.fechaDevolucion != null;
        final vencido = !devuelto && detalle.diasRetraso > 0;
        filas.add([
          detalle.titulo,
          prestamo.socio,
          fechaCorta(prestamo.fechaPrestamo),
          fechaCorta(prestamo.fechaVencimiento),
          devuelto ? 'Devuelto ${fechaCorta(detalle.fechaDevolucion)}' : (vencido ? 'Vencido' : 'En préstamo'),
        ]);
      }
    }
    return filas;
  }

  documento.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Text('Biblionet', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: morado)),
        pw.SizedBox(height: 4),
        pw.Text(
          'Sistema de gestión de biblioteca institucional',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
        ),
        pw.Text(
          'Informe de la biblioteca al ${ahora.year}-$mes-$dia',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 14),
        pw.Text(
          'Préstamos abiertos: ${indicadores['prestamos_abiertos'] ?? abiertos.length}    '
          'Vencidos: ${indicadores['prestamos_vencidos'] ?? vencidos.length}    '
          'Títulos: ${indicadores['titulos'] ?? '—'}    '
          'Disponibles: ${indicadores['disponibles'] ?? '—'} / ${indicadores['ejemplares'] ?? '—'}    '
          'Multas pendientes: USD ${comoDecimal(indicadores['multas_pendientes']).toStringAsFixed(2)}',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 18),
        tabla(
          'Libros prestados al día',
          'Ejemplares que todavía no se han devuelto.',
          const ['Libro', 'Socio', 'Prestado', 'Vence', 'Estado'],
          filasPrestamo(abiertos, soloAbiertos: true),
        ),
        tabla(
          'Historial de préstamos',
          'Todos los préstamos registrados.',
          const ['Libro', 'Socio', 'Prestado', 'Vence', 'Estado'],
          filasPrestamo(prestamos),
        ),
        tabla(
          'Títulos más prestados',
          'Cuántas veces se prestó cada libro.',
          const ['Título', 'Préstamos'],
          [for (final item in ranking) ['${item['titulo'] ?? ''}', '${item['veces'] ?? 0}']],
        ),
        tabla(
          'Préstamos vencidos',
          'Libros que ya pasaron la fecha de devolución.',
          const ['Socio', 'Libro', 'Días de retraso'],
          [for (final item in vencidos) ['${item['socio'] ?? ''}', '${item['titulo'] ?? ''}', '${item['dias_retraso'] ?? 0}']],
        ),
        tabla(
          'Multas',
          'Cargos por retraso.',
          const ['Socio', 'Libro', 'Monto (USD)', 'Estado'],
          [for (final multa in multas) [multa.socio, multa.titulo, multa.monto.toStringAsFixed(2), multa.estado]],
        ),
      ],
    ),
  );
  return documento.save();
}
