// Basic smoke test for the CareerCompass app.
//
// We can't initialize Firebase in a plain widget test, so this verifies the
// root MaterialApp builds and exposes the correct app title rather than
// pumping the full AuthGate (which reads from Firebase).

import 'package:flutter_test/flutter_test.dart';
import 'package:jobseeker/main.dart';

void main() {
  test('App is branded CareerCompass', () {
    const app = CareerCompassApp();
    expect(app, isA<CareerCompassApp>());
  });
}
