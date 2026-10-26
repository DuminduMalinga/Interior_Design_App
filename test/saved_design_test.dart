import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/data/models.dart';

/// `SavedDesign` rows as the web's `listSavedDesigns` reads them; the layout
/// is a real engine layout from `fixtures/living_room_layouts.json`.
void main() {
  final layoutJson =
      (jsonDecode(
                File(
                  'test/fixtures/living_room_layouts.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>)['layouts'][0]
          as Map<String, dynamic>;

  Map<String, dynamic> row({
    Object? score = 172.7,
    Object? layout,
    String? modelPath,
    String? previewPath,
    String? roomName = 'Living Room',
  }) => {
    'DesignID': 'd-1',
    'FloorPlanID': 'fp-1',
    'RoomID': 'room-1',
    'RoomName': roomName,
    'Title': 'Conversation layout',
    'Score': score,
    'LayoutJSON': layout ?? layoutJson,
    'ModelPath': modelPath,
    'PreviewPath': previewPath,
    'UpdatedAt': '2026-10-20T10:00:00Z',
  };

  test('reads a row and its engine layout', () {
    final design = SavedDesignRecord.fromJson(
      row(previewPath: 'u/fp-1/room-1-conversation.png'),
      previewUrl: 'https://signed',
    );
    expect(design.designId, 'd-1');
    expect(design.roomName, 'Living Room');
    expect(design.score, 173);
    expect(design.layout?.type, 'conversation');
    expect(design.layout?.furniture, isNotEmpty);
    expect(design.previewUrl, 'https://signed');
    expect(design.updatedAt, DateTime.utc(2026, 10, 20, 10));
  });

  test('a numeric score stored as text still reads, a missing one is null', () {
    expect(SavedDesignRecord.fromJson(row(score: '86.4')).score, 86);
    expect(SavedDesignRecord.fromJson(row(score: null)).score, isNull);
  });

  test('a missing room name and an unreadable layout do not break it', () {
    final design = SavedDesignRecord.fromJson(
      row(roomName: null, layout: 'junk'),
    );
    expect(design.roomName, 'Room');
    expect(design.layout, isNull);
  });

  test('deleting removes only the files the design has', () {
    expect(SavedDesignRecord.fromJson(row()).storagePaths, isEmpty);
    expect(
      SavedDesignRecord.fromJson(
        row(modelPath: 'u/a.glb', previewPath: 'u/a.png'),
      ).storagePaths,
      ['u/a.glb', 'u/a.png'],
    );
  });
}
