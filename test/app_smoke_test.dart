import 'package:family_remote/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Splash puis accueil, et un bouton sans TV affiche une erreur claire', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FamilyRemoteApp()));
    expect(find.text('Family Remote'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Aucun téléviseur'), findsOneWidget);

    // Aucun faux succès : sans connexion, on doit voir le message d'erreur.
    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pump();
    expect(find.text('Aucun téléviseur connecté.'), findsOneWidget);
  });

  testWidgets('L’écran télécommande s’affiche', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FamilyRemoteApp()));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Télécommande'));
    await tester.pumpAndSettle();
    expect(find.text('VOL'), findsOneWidget);
  });
}
