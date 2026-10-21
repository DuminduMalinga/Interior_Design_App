import 'package:flutter_test/flutter_test.dart';
import 'package:interior_design/data/models.dart';

/// What the 3D viewer draws a layout from: the pieces' facing, mounting and
/// corner footprints, the openings' heights and the room's cutouts.
void main() {
  test('AnalysisLayout reads what the 3D models need', () {
    final layout = AnalysisLayout.fromJson({
      'layout': {'type': 'u', 'title': 'U', 'score': 80},
      'room': {
        'width': 5000,
        'length': 4000,
        'height': 2700,
        'cutouts': [
          [3000, 2000, 5000, 4000],
        ],
      },
      'furniture': [
        {
          'id': 's',
          'type': 'l_sofa',
          'bbox': [0, 0, 2000, 1500],
          'facing': 'north',
          'shape': 'l',
          'parts': [
            [0, 0, 2000, 900],
            [0, 900, 900, 1500],
          ],
          'height': 850,
        },
        {
          'id': 't',
          'type': 'tv',
          'bbox': [1000, 3900, 2200, 4000],
          'mounted': 'wall',
          'mount_height': 1100,
        },
      ],
      'openings': {
        'doors': [
          {'wall': 'south', 'position': 500, 'width': 900},
        ],
        'windows': [
          {
            'wall': 'north',
            'position': 1000,
            'width': 1500,
            'height': 1300,
            'sill_height': 800,
            'inset': 200,
          },
        ],
      },
    });
    expect(layout.cutouts.single, [3000, 2000, 5000, 4000]);
    final sofa = layout.furniture.first;
    expect(sofa.facing, 'north');
    expect(sofa.shape, 'l');
    expect(sofa.parts, hasLength(2));
    final tv = layout.furniture.last;
    expect(tv.facing, 'south');
    expect(tv.mounted, 'wall');
    expect(tv.mountHeight, 1100);
    final window = layout.openings.firstWhere((o) => !o.isDoor);
    expect(window.height, 1300);
    expect(window.sillHeight, 800);
    expect(window.inset, 200);
    expect(layout.openings.firstWhere((o) => o.isDoor).inset, 0);
  });
}
