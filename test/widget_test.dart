// Tests para la aplicación Domain Status Monitor
//
// Para realizar interacciones con widgets en el test, usa WidgetTester
// del paquete flutter_test. Por ejemplo, puedes enviar tap y scroll
// gestures. También puedes usar WidgetTester para encontrar widgets hijos
// en el árbol de widgets, leer texto, y verificar valores de propiedades.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:domain_status/main.dart';

void main() {
  testWidgets('Domain Status App initial state test', (
    WidgetTester tester,
  ) async {
    // Construir nuestra app y activar un frame.
    await tester.pumpWidget(const DomainStatusApp());

    // Verificar que el título de la app esté presente.
    expect(find.text('Monitor de Dominios'), findsOneWidget);

    // Verificar que se muestre el mensaje de estado vacío.
    expect(find.text('No hay dominios agregados'), findsOneWidget);
    expect(
      find.text('Toca el botón + para agregar tu primer dominio'),
      findsOneWidget,
    );

    // Verificar que el botón flotante esté presente.
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verificar que el botón de refresh esté presente.
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    // Verificar que los botones de exportar/importar estén presentes.
    expect(find.byIcon(Icons.upload_file), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);
  });

  testWidgets('Add domain dialog opens when FAB is tapped', (
    WidgetTester tester,
  ) async {
    // Construir nuestra app.
    await tester.pumpWidget(const DomainStatusApp());

    // Tocar el botón flotante.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verificar que el diálogo se abre.
    expect(find.text('Agregar Dominio'), findsOneWidget);
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('URL'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Agregar'), findsOneWidget);
  });
}
