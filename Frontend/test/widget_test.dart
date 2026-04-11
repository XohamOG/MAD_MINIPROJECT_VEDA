import 'package:flutter_test/flutter_test.dart';

import 'package:veda_app/src/app.dart';

void main() {
  testWidgets('renders initialized app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const VedaApp());

    expect(find.text('Veda App'), findsOneWidget);
    expect(find.text('Flutter frontend is initialized'), findsOneWidget);
  });
}
