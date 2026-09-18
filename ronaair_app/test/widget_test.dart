// Test sederhana untuk RonaAir App.
// Test ini memastikan aplikasi bisa di-build tanpa error.

import 'package:flutter_test/flutter_test.dart';

import 'package:ronaair_app/main.dart';

void main() {
  testWidgets('RonaAir app bisa di-build tanpa error',
      (WidgetTester tester) async {
    // Build aplikasi RonaAir dan trigger frame pertama.
    await tester.pumpWidget(const RonaAirApp());

    // Verifikasi bahwa aplikasi berhasil dirender.
    // Cek apakah ada teks "RonaAir" di layar.
    expect(find.text('RonaAir'), findsAtLeastNWidgets(1));
  });
}