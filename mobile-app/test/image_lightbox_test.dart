import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/ui/reader/media_lightbox.dart';

void main() {
  testWidgets('Pinching updates image scale and fit resets the transform', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ZoomableLightboxImage(image: SizedBox(width: 300, height: 200)),
        ),
      ),
    );
    final viewer = find.byType(InteractiveViewer);
    final center = tester.getCenter(viewer);
    expect(find.text('100%'), findsOneWidget);

    final left = await tester.startGesture(center - const Offset(40, 0));
    final right = await tester.startGesture(
      center + const Offset(40, 0),
      pointer: 2,
    );
    await left.moveBy(const Offset(-60, 0));
    await right.moveBy(const Offset(60, 0));
    await tester.pump();
    final controller = tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!;
    final percent = (controller.value.getMaxScaleOnAxis() * 100).round();
    expect(percent, greaterThan(100));
    expect(find.text('$percent%'), findsOneWidget);
    await left.up();
    await right.up();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.fit_screen_outlined));
    await tester.pumpAndSettle();
    expect(controller.value.isIdentity(), isTrue);
    expect(find.text('100%'), findsOneWidget);
  });
}
