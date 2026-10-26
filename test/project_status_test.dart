import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/data/models.dart';
import 'package:interior_design/data/project_status.dart';

/// How far each floor plan has got, and the totals on Home: the same rules
/// as the web dashboard (`useUserDesigns.ts`, `DesignCard.tsx`).
void main() {
  FloorPlanRecord plan({
    String id = 'fp-1',
    String uploaded = '2026-10-20T10:00:00Z',
  }) => FloorPlanRecord.fromJson({
    'FloorPlanID': id,
    'UserID': 'u',
    'ImagePath': 'u/1.png',
    'Status': 'Uploaded',
    'UploadDateTime': uploaded,
  });

  Map<String, dynamic> room(String id, String name) => {
    'id': id,
    'name': name,
    'confidence': 0.9,
    'labelDetected': true,
  };

  FloorPlanAnalysisRecord analysis({
    String id = 'fp-1',
    String status = 'Detected',
    List<Map<String, dynamic>>? rooms,
    String? selectedRoomId,
    Object? selectedLayout,
    String updated = '2026-10-21T10:00:00Z',
  }) => FloorPlanAnalysisRecord.fromJson({
    'FloorPlanID': id,
    'UserID': 'u',
    'Status': status,
    'DetectionJSON': {'rooms': rooms ?? []},
    'SelectedRoomID': selectedRoomId,
    'SelectedLayoutJSON': selectedLayout,
    'CreatedAt': '2026-10-20T10:00:00Z',
    'UpdatedAt': updated,
  });

  group('ProjectStage', () {
    test('is read from the analysis status, in any case', () {
      expect(ProjectStage.fromStatus('Detected'), ProjectStage.detected);
      expect(ProjectStage.fromStatus('LayoutReady'), ProjectStage.layoutReady);
      expect(
        ProjectStage.fromStatus('LayoutSelected'),
        ProjectStage.layoutSelected,
      );
      expect(
        ProjectStage.fromStatus('layoutselected'),
        ProjectStage.layoutSelected,
      );
      expect(ProjectStage.fromStatus('  Detected '), ProjectStage.detected);
    });

    test('anything else counts as just uploaded', () {
      for (final status in [
        null,
        '',
        'Uploaded',
        'Processing',
        'Failed',
        'x',
      ]) {
        expect(
          ProjectStage.fromStatus(status),
          ProjectStage.uploaded,
          reason: '$status',
        );
      }
    });

    test('says where the plan is, as the web does', () {
      expect(ProjectStage.uploaded.label, 'Uploaded');
      expect(ProjectStage.detected.label, 'Rooms detected');
      expect(ProjectStage.layoutReady.label, 'Layouts ready');
      expect(ProjectStage.layoutSelected.label, 'Layout chosen');
    });

    test('says what to do next, as the web does', () {
      expect(ProjectStage.uploaded.nextStep, 'Upload again to analyse');
      expect(ProjectStage.detected.nextStep, 'Pick a room');
      expect(ProjectStage.layoutReady.nextStep, 'Compare layouts');
      expect(ProjectStage.layoutSelected.nextStep, 'Open layouts');
    });

    test('a plan is finished once it has layouts', () {
      expect(ProjectStage.uploaded.isFinished, isFalse);
      expect(ProjectStage.detected.isFinished, isFalse);
      expect(ProjectStage.layoutReady.isFinished, isTrue);
      expect(ProjectStage.layoutSelected.isFinished, isTrue);
    });
  });

  group('ProjectSummary.titleFor', () {
    test('prefers the room, then the room count, then a plain name', () {
      expect(
        ProjectSummary.titleFor(roomName: 'Kitchen', roomCount: 4),
        'Kitchen',
      );
      expect(ProjectSummary.titleFor(roomCount: 4), 'Floor plan with 4 rooms');
      expect(ProjectSummary.titleFor(roomCount: 1), 'Floor plan with 1 room');
      expect(ProjectSummary.titleFor(roomCount: 0), 'Floor plan');
    });

    test('a blank room name does not count', () {
      expect(
        ProjectSummary.titleFor(roomName: '  ', roomCount: 2),
        'Floor plan with 2 rooms',
      );
    });
  });

  group('ProjectSummary.of', () {
    test('a plan with no analysis is just uploaded', () {
      final s = ProjectSummary.of(plan(), null);
      expect(s.stage, ProjectStage.uploaded);
      expect(s.title, 'Floor plan');
      expect(s.roomCount, 0);
      expect(s.score, isNull);
      expect(s.updatedAt, DateTime.utc(2026, 10, 20, 10));
    });

    test('counts the rooms found and dates the plan by its analysis', () {
      final s = ProjectSummary.of(
        plan(),
        analysis(rooms: [room('r1', 'Bedroom'), room('r2', 'Kitchen')]),
      );
      expect(s.stage, ProjectStage.detected);
      expect(s.roomCount, 2);
      expect(s.title, 'Floor plan with 2 rooms');
      expect(s.updatedAt, DateTime.utc(2026, 10, 21, 10));
    });

    test('is named for the room the user took forward', () {
      final s = ProjectSummary.of(
        plan(),
        analysis(
          status: 'LayoutSelected',
          rooms: [room('r1', 'Bedroom'), room('r2', 'Kitchen')],
          selectedRoomId: 'r2',
        ),
      );
      expect(s.selectedRoomName, 'Kitchen');
      expect(s.title, 'Kitchen');
    });

    test('a chosen room that is no longer in the detection falls back', () {
      final s = ProjectSummary.of(
        plan(),
        analysis(rooms: [room('r1', 'Bedroom')], selectedRoomId: 'gone'),
      );
      expect(s.selectedRoomName, isNull);
      expect(s.title, 'Floor plan with 1 room');
    });

    test('reads the chosen layout\'s title and rounds its score', () {
      final s = ProjectSummary.of(
        plan(),
        analysis(
          status: 'LayoutSelected',
          selectedLayout: {
            'layout': {'title': 'Bed on the west wall', 'score': 86.5},
          },
        ),
      );
      expect(s.layoutTitle, 'Bed on the west wall');
      expect(s.score, 87);
    });

    test('an unreadable chosen layout leaves no score', () {
      for (final junk in [
        null,
        'x',
        <Object>[],
        {'layout': 'x'},
        {
          'layout': {'score': 'high'},
        },
        {'layout': <String, Object>{}},
      ]) {
        final s = ProjectSummary.of(plan(), analysis(selectedLayout: junk));
        expect(s.score, isNull, reason: '$junk');
        expect(s.layoutTitle, isNull);
      }
    });
  });

  group('ProjectStats.of', () {
    ProjectSummary project(
      String id,
      String status, {
      num? score,
      String updated = '2026-10-21T10:00:00Z',
    }) => ProjectSummary.of(
      plan(id: id),
      analysis(
        id: id,
        status: status,
        updated: updated,
        selectedLayout: score == null
            ? null
            : {
                'layout': {'score': score},
              },
      ),
    );

    test('has nothing to total when there are no plans', () {
      final stats = ProjectStats.of(const []);
      expect(stats.plans, 0);
      expect(stats.finished, 0);
      expect(stats.lastScore, isNull);
    });

    test('counts every plan, and those with layouts as finished', () {
      final stats = ProjectStats.of([
        ProjectSummary.of(plan(id: 'a'), null),
        project('b', 'Detected'),
        project('c', 'LayoutReady'),
        project('d', 'LayoutSelected', score: 80),
      ]);
      expect(stats.plans, 4);
      expect(stats.finished, 2);
    });

    test(
      'the last score is the most recently changed plan\'s, not the best',
      () {
        final stats = ProjectStats.of([
          project(
            'a',
            'LayoutSelected',
            score: 95,
            updated: '2026-10-20T10:00:00Z',
          ),
          project(
            'b',
            'LayoutSelected',
            score: 72,
            updated: '2026-10-25T10:00:00Z',
          ),
          project(
            'c',
            'LayoutSelected',
            score: 88,
            updated: '2026-10-22T10:00:00Z',
          ),
        ]);
        expect(stats.lastScore, 72);
      },
    );

    test('a newer plan with no score does not hide an older score', () {
      final stats = ProjectStats.of([
        project(
          'a',
          'LayoutSelected',
          score: 90,
          updated: '2026-10-20T10:00:00Z',
        ),
        project('b', 'Detected', updated: '2026-10-26T10:00:00Z'),
      ]);
      expect(stats.lastScore, 90);
    });

    test('no score anywhere is no last score', () {
      expect(ProjectStats.of([project('a', 'Detected')]).lastScore, isNull);
    });
  });
}
