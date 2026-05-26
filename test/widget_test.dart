import 'package:flutter_test/flutter_test.dart';

import 'package:jobseeker/main.dart';

void main() {
  testWidgets('Home screen renders greeting and a job card', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Hello,'), findsOneWidget);
    expect(find.text('Find your dream job'), findsOneWidget);
    expect(find.text('Featured jobs'), findsOneWidget);
    expect(find.text('Senior Flutter Developer'), findsOneWidget);
  });
}
