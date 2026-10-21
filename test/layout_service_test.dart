import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/data/layout_service.dart';

/// The request the app sends to the web backend's layout services is built
/// from the wall detector's stored `DetectionJSON`; these tests pin that
/// contract against the web client (`livingRoomLayout.ts` / `ViewLayouts.tsx`).
void main() {
  group('RoomKind.fromName', () {
    test('matches the web roomKind rules', () {
      expect(RoomKind.fromName('Living Room'), RoomKind.living);
      expect(RoomKind.fromName('Living / Dining'), RoomKind.living);
      expect(RoomKind.fromName('Bedroom 1 Bath'), RoomKind.bathroom);
      expect(RoomKind.fromName('Master Bedroom'), RoomKind.masterBedroom);
      expect(RoomKind.fromName('Bedroom 2'), RoomKind.bedroom);
      expect(RoomKind.fromName('Kitchen / Dining'), RoomKind.kitchen);
      expect(RoomKind.fromName('Dining'), RoomKind.dining);
      expect(RoomKind.fromName('Garage'), isNull);
    });

    test('only the living room and bedroom are wired so far', () {
      expect(RoomKind.living.isSupported, isTrue);
      expect(RoomKind.bedroom.isSupported, isTrue);
      expect(RoomKind.masterBedroom.isSupported, isFalse);
    });
  });

  group('DetectionDocument.requestFor', () {
    final bbox = {'x1': 549.1, 'y1': 392.6, 'x2': 778.7, 'y2': 676.5};
    final detection = {
      'scaleMmPerPx': 20.0,
      'detections': [
        {'id': 'door-1', 'class': 'Door', 'bbox': bbox, 'confidence': 0.9},
        {'id': 'wall-1', 'class': 'Wall', 'bbox': bbox},
        {'id': 'win-1', 'class': 'Window', 'bbox': bbox},
      ],
      'rooms': [
        {
          'id': 'room-1',
          'name': 'Living Room',
          'bbox': bbox,
          'widthM': 5.0,
          'heightM': 4.0,
          'labelWidthM': 5.0,
          'labelHeightM': 4.0,
          'shapeSource': 'walls',
          'polygon': [
            [0, 0],
            [1, 0],
            [1, 1],
          ],
        },
        {'id': 'room-2', 'name': 'Kitchen', 'bbox': bbox, 'widthM': 3.0},
      ],
    };

    test(
      'sends the room, only doors and windows, every room and the scale',
      () {
        final req = DetectionDocument.from(detection)!.requestFor('room-1')!;
        expect((req['room'] as Map)['id'], 'room-1');
        expect((req['room'] as Map)['width_m'], 5.0);
        expect((req['room'] as Map)['length_m'], 4.0);
        expect((req['room'] as Map)['polygon'], isNotNull);
        expect((req['detections'] as List).map((d) => (d as Map)['class']), [
          'Door',
          'Window',
        ]);
        expect(req['rooms'], hasLength(2));
        expect(req['scale_m_per_px'], closeTo(0.02, 1e-9));
      },
    );

    test('omits printed size and outline when the plan has none', () {
      final req = DetectionDocument.from(detection)!.requestFor('room-2')!;
      final room = req['room'] as Map;
      expect(room.containsKey('width_m'), isFalse);
      expect(room.containsKey('polygon'), isFalse);
    });

    test('null for an unknown room or a malformed document', () {
      expect(DetectionDocument.from(detection)!.requestFor('nope'), isNull);
      expect(DetectionDocument.from(null), isNull);
      expect(DetectionDocument.from({'rooms': 'x'})!.requestFor('a'), isNull);
    });
  });

  test('BedroomOptions leaves occupants out to let the engine infer them', () {
    expect(const BedroomOptions().toJson(), isEmpty);
    expect(const BedroomOptions(occupants: 2).toJson(), {'occupants': 2});
  });

  test('each wired room has its own service address', () {
    expect(
      LayoutServiceEnv.urlFor(RoomKind.living),
      isNot(LayoutServiceEnv.urlFor(RoomKind.bedroom)),
    );
    expect(LayoutServiceEnv.urlFor(RoomKind.bedroom), endsWith(':8200'));
  });

  test('LivingRoomOptions leaves activities out to let the engine decide', () {
    expect(const LivingRoomOptions().toJson(), {'accessible': false});
    expect(
      const LivingRoomOptions(
        activities: [LivingActivity.conversation, LivingActivity.tv],
        accessible: true,
      ).toJson(),
      {
        'activities': ['conversation', 'tv'],
        'accessible': true,
      },
    );
  });
}
