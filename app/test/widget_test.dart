import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamia/main.dart';

void main() {
  testWidgets('shows Arabic home shell', (tester) async {
    await tester.pumpWidget(
      const JamiaApp(useAuthGate: false, enableTelemetry: false),
    );

    expect(find.text('\u062c\u0645\u0639\u064a\u0629'), findsOneWidget);
    expect(
      find.text(
        '\u062c\u0645\u0639\u064a\u0629 \u0627\u0644\u0628\u064a\u062a',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '\u0627\u0644\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u062d\u0627\u0644\u064a\u0629',
      ),
      findsWidgets,
    );
  });

  testWidgets('switches home shell to English LTR', (tester) async {
    await tester.pumpWidget(
      const JamiaApp(useAuthGate: false, enableTelemetry: false),
    );

    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    expect(find.text('Jamia'), findsOneWidget);
    expect(find.text('Home co-op'), findsOneWidget);
    expect(find.text('Current requests'), findsWidgets);
    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.ltr);
  });
}
