import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkie/widgets/talkie_orb.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  testWidgets('TalkieOrb renders in idle state', (tester) async {
    await tester.pumpWidget(wrap(const TalkieOrb(state: OrbState.idle)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TalkieOrb), findsOneWidget);
  });

  testWidgets('TalkieOrb renders in listening state', (tester) async {
    await tester.pumpWidget(wrap(const TalkieOrb(state: OrbState.listening)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TalkieOrb), findsOneWidget);
  });

  testWidgets('TalkieOrb renders in speaking state', (tester) async {
    await tester.pumpWidget(wrap(const TalkieOrb(state: OrbState.speaking)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TalkieOrb), findsOneWidget);
  });

  testWidgets('TalkieOrb renders in thinking state', (tester) async {
    await tester.pumpWidget(wrap(const TalkieOrb(state: OrbState.thinking)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TalkieOrb), findsOneWidget);
  });

  testWidgets('TalkieOrb calls onTap when tapped', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      wrap(TalkieOrb(state: OrbState.idle, onTap: () => tapped = true)),
    );
    await tester.tap(find.byType(TalkieOrb));
    expect(tapped, isTrue);
  });
}
