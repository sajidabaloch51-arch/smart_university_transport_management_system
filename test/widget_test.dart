import 'package:flutter_test/flutter_test.dart';
import 'package:sutms/main.dart';

void main() {
  testWidgets('SUTMS app builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const SUTMSApp());
    await tester.pump();
    expect(find.byType(SUTMSApp), findsOneWidget);
  });
}
