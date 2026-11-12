import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:she_shield/main.dart';
import 'package:she_shield/services/database_service.dart';
import 'package:she_shield/services/travel_journey_service.dart';
import 'package:she_shield/services/voice_engine_service.dart';

void main() {
  testWidgets('SHE SHIELD app renders onboarding smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => DatabaseService(),
        child: const SheShieldApp(),
      ),
    );
    await tester.pump();
    expect(find.text('SHE SHIELD'), findsOneWidget);
  });

  testWidgets('Unauthenticated manual navigation to protected routes redirects to Login', (WidgetTester tester) async {
    final db = DatabaseService();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: db,
        child: const SheShieldApp(),
      ),
    );
    await tester.pump();

    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
    navigatorState.pushNamed('/admin_dashboard');
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Authentication required to access /admin_dashboard.'), findsOneWidget);
    expect(find.text('Users & RBAC'), findsNothing);
  });

  test('VoiceEngineService exposes exact 8 states & rejects unauthorized Women-only Voice SOS', () async {
    final db = DatabaseService();
    final engine = VoiceEngineService();
    engine.resetToIdle();

    expect(VoiceSosState.values.map((e) => e.name).toList(), [
      'IDLE',
      'LISTENING',
      'SOS_TRIGGERED',
      'RECORDING',
      'STOPPING',
      'SAVING_TO_VAULT',
      'SAVED',
      'FAILED',
    ]);

    expect(VoiceEngineService.languageToBcp47('Hindi'), 'hi-IN');
    expect(VoiceEngineService.languageToBcp47('Gujarati'), 'gu-IN');
    expect(VoiceEngineService.languageToBcp47('Marathi'), 'mr-IN');
    expect(VoiceEngineService.languageToBcp47('English'), 'en-US');

    final enabledOk = await engine.enableVoiceSos(db);
    expect(enabledOk, isFalse);
    expect(engine.state, VoiceSosState.FAILED);

    final trigOk = await engine.triggerVoiceSosAndRecord(db, detectedPhrase: 'help');
    expect(trigOk, isFalse);
    expect(engine.state, VoiceSosState.FAILED);
    engine.resetToIdle();
  });

  test('TravelJourneyService computes accurate Haversine distance, deviation & rejects empty destination', () async {
    final p1 = const LatLng(23.0225, 72.5714);
    final p2 = const LatLng(23.0325, 72.5714);
    final dist = TravelJourneyService.haversineMeters(p1, p2);
    expect(dist, inInclusiveRange(1080.0, 1140.0));

    final route = [const LatLng(23.0225, 72.5714), const LatLng(23.0225, 72.5914)];
    final onRouteDist = TravelJourneyService.distanceToPolylineMeters(const LatLng(23.0225, 72.5814), route);
    expect(onRouteDist, lessThan(2.0));

    final offRouteDist = TravelJourneyService.distanceToPolylineMeters(const LatLng(23.0275, 72.5814), route);
    expect(offRouteDist, inInclusiveRange(520.0, 590.0));

    expect(TravelJourneyService.formatDistance(420), '420 m');
    expect(TravelJourneyService.formatDistance(2450), '2.45 km');
    expect(TravelJourneyService.formatCountdown(const Duration(minutes: 12, seconds: 5)), '00:12:05');
    expect(TravelJourneyService.formatCountdown(const Duration(minutes: -2, seconds: -10)), '+00:02:10 OVERDUE');

    final svc = TravelJourneyService();
    final db = DatabaseService();
    final startRes = await svc.startJourney(durationMinutes: 20, recordingMode: 'None', db: db);
    expect(startRes.ok, isFalse);
    expect(startRes.error, contains('destination'));
    svc.dispose();
  });

  testWidgets('Public /track/<token> route opens Guardian Tracking Screen without login redirect', (WidgetTester tester) async {
    final db = DatabaseService();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: db,
        child: const SheShieldApp(),
      ),
    );
    await tester.pump();

    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
    navigatorState.pushNamed('/track/test_unguessable_token_123456');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('SHE SHIELD — Guardian Live Track'), findsOneWidget);
    expect(find.text('Welcome Back'), findsNothing);
  });

  testWidgets('Registration screen allows selecting User or Guardian & pre-selects Guardian on share link', (WidgetTester tester) async {
    final db = DatabaseService();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: db,
        child: const SheShieldApp(),
      ),
    );
    await tester.pump();

    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
    navigatorState.pushNamed('/register_user');
    await tester.pumpAndSettle();

    expect(find.text('User Registration'), findsOneWidget);
    expect(find.text('Safety User'), findsOneWidget);
    expect(find.text('Guardian'), findsOneWidget);

    await tester.tap(find.text('Guardian'));
    await tester.pumpAndSettle();
    expect(find.text('Guardian Registration'), findsOneWidget);

    navigatorState.pushNamed('/register_user?share=abc_share_tok');
    await tester.pumpAndSettle();
    expect(find.text('Guardian Registration'), findsOneWidget);
    expect(
      find.text('Complete Guardian registration to view this shared live journey inside your Guardian Dashboard.'),
      findsOneWidget,
    );
  });
}
