// Stylized map of southern Sweden drawn with CustomPainter (no tile library).
// The coastline is a simplified lat/lon outline; places are drawn as colored
// markers. Tap a marker to select it.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../demo/demo_data.dart';
import '../theme.dart';

// Map area (lat/lon) to show
class MapBounds {
  final double south, west, north, east;
  const MapBounds(this.south, this.west, this.north, this.east);

  static const MapBounds southernSweden = MapBounds(55.15, 10.9, 60.35, 19.4);
  static const MapBounds goteborg = MapBounds(57.62, 11.80, 57.78, 12.10);
}

Color placeColor(PlaceType t) {
  switch (t) {
    case PlaceType.roaster: return BrewColors.caramel;
    case PlaceType.cafe: return BrewColors.sage;
    case PlaceType.shop: return BrewColors.series[2];
  }
}

// Simplified mainland outline, clockwise from the Norwegian border on the west coast.
// The northern edge runs off-map, so it is closed above the visible area.
const List<(double, double)> _mainland = <(double, double)>[
  (59.10, 11.15), (58.90, 11.20), (58.65, 11.25), (58.35, 11.40), (58.10, 11.55), (57.85, 11.65),
  (57.70, 11.85), (57.55, 11.92), (57.30, 12.05), (57.10, 12.22), (56.90, 12.38), (56.65, 12.70),
  (56.45, 12.85), (56.25, 12.55), (56.05, 12.65), (55.85, 12.85), (55.60, 12.95), (55.40, 12.90),
  (55.33, 13.30), (55.38, 13.80), (55.42, 14.20), (55.65, 14.30), (55.95, 14.25), (56.05, 14.65),
  (56.15, 15.20), (56.15, 15.75), (56.25, 16.00), (56.55, 16.30), (56.90, 16.45), (57.20, 16.50),
  (57.55, 16.65), (57.85, 16.70), (58.20, 16.80), (58.50, 16.85), (58.65, 17.10), (58.85, 17.60),
  (59.05, 18.00), (59.30, 18.40), (59.50, 18.70), (59.80, 18.90), (60.10, 18.80), (60.40, 18.40),
  (60.65, 17.60), (61.20, 17.30), (61.20, 12.40), (60.60, 12.50), (60.20, 12.50), (59.80, 12.05),
  (59.40, 11.75),
];

const List<(double, double)> _oland = <(double, double)>[
  (56.20, 16.40), (56.60, 16.55), (57.00, 16.80), (57.35, 17.08), (57.30, 17.15), (56.90, 16.95),
  (56.50, 16.70), (56.22, 16.50),
];

const List<(double, double)> _gotland = <(double, double)>[
  (56.92, 18.15), (57.20, 18.10), (57.55, 18.30), (57.90, 18.75), (57.95, 19.15), (57.75, 19.00),
  (57.45, 18.85), (57.15, 18.60), (56.95, 18.35),
];

const List<(double, double)> _vanern = <(double, double)>[
  (59.38, 13.40), (59.25, 13.95), (58.95, 13.80), (58.70, 13.65), (58.55, 13.20), (58.45, 12.65),
  (58.70, 12.35), (58.95, 12.40), (59.20, 12.85),
];

const List<(double, double)> _vattern = <(double, double)>[
  (58.85, 14.55), (58.70, 14.75), (58.30, 14.60), (57.95, 14.35), (57.78, 14.15), (57.85, 14.05),
  (58.20, 14.30), (58.60, 14.45),
];

const List<(String, double, double)> _cities = <(String, double, double)>[
  ('Göteborg', 57.7089, 11.9746),
  ('Stockholm', 59.3293, 18.0686),
  ('Malmö', 55.6050, 13.0038),
  ('Linköping', 58.4108, 15.6214),
];

// Equirectangular projection fitted into the canvas, longitude scaled by cos(lat)
class _Projection {
  final MapBounds b;
  final Size size;
  late final double _scale;
  late final Offset _origin;
  late final double _k;

  _Projection(this.b, this.size) {
    _k = math.cos((b.south + b.north) / 2 * math.pi / 180);
    final double w = (b.east - b.west) * _k;
    final double h = b.north - b.south;
    _scale = math.min(size.width / w, size.height / h); // contain: the whole area is visible
    _origin = Offset((size.width - w * _scale) / 2, (size.height - h * _scale) / 2);
  }

  Offset call(double lat, double lon) =>
      _origin + Offset((lon - b.west) * _k * _scale, (b.north - lat) * _scale);
}

class SwedenMap extends StatelessWidget {
  final List<Place> places;
  final String? selectedId;
  final ValueChanged<Place> onSelect;
  final MapBounds bounds;
  final double height;

  const SwedenMap({
    super.key,
    required this.places,
    required this.selectedId,
    required this.onSelect,
    this.bounds = MapBounds.southernSweden,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final Size size = Size(c.maxWidth, height);
          return GestureDetector(
            onTapUp: (TapUpDetails d) {
              final _Projection proj = _Projection(bounds, size);
              Place? nearest;
              double best = 22; // px hit radius
              for (final Place p in places) {
                final double dist = (proj(p.lat, p.lon) - d.localPosition).distance;
                if (dist < best) {
                  best = dist;
                  nearest = p;
                }
              }
              if (nearest != null) onSelect(nearest);
            },
            child: CustomPaint(
              size: size,
              painter: _MapPainter(places: places, selectedId: selectedId, bounds: bounds),
            ),
          );
        },
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<Place> places;
  final String? selectedId;
  final MapBounds bounds;

  _MapPainter({required this.places, required this.selectedId, required this.bounds});

  static const Color _sea = Color(0xFF172027);
  static const Color _land = Color(0xFF2B2119);

  Path _poly(_Projection proj, List<(double, double)> pts) {
    final Path path = Path();
    for (int i = 0; i < pts.length; i++) {
      final Offset o = proj(pts[i].$1, pts[i].$2);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    return path..close();
  }

  void _label(Canvas canvas, String text, Offset at, TextStyle style, {bool above = false}) {
    final TextPainter tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(at.dx - tp.width / 2, above ? at.dy - tp.height - 12 : at.dy + 6));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final _Projection proj = _Projection(bounds, size);
    canvas.clipRect(Offset.zero & size);

    // Sea with a soft gradient
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1A242C), _sea],
        ).createShader(Offset.zero & size),
    );

    // Faint graticule
    final Paint grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double lat = 55; lat <= 61; lat += 1) {
      final double y = proj(lat, bounds.west).dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (double lon = 10; lon <= 20; lon += 2) {
      final double x = proj(bounds.south, lon).dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    // Land and coast
    final Paint land = Paint()..color = _land;
    final Paint coast = Paint()
      ..color = BrewColors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    for (final List<(double, double)> shape in <List<(double, double)>>[_mainland, _oland, _gotland]) {
      final Path p = _poly(proj, shape);
      canvas.drawPath(p, land);
      canvas.drawPath(p, coast);
    }
    // Lakes
    for (final List<(double, double)> lake in <List<(double, double)>>[_vanern, _vattern]) {
      final Path p = _poly(proj, lake);
      canvas.drawPath(p, Paint()..color = _sea);
      canvas.drawPath(p, coast..strokeWidth = 1);
    }

    // City names
    const TextStyle cityStyle = TextStyle(color: Color(0x80F3E9DD), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4);
    for (final (String name, double lat, double lon) in _cities) {
      final Offset o = proj(lat, lon);
      if (!(Offset.zero & size).contains(o)) continue;
      // Near the bottom edge (Malmö) the label goes above the dot, clear of the legend
      final bool nearBottom = o.dy > size.height - 48;
      _label(canvas, name.toUpperCase(), nearBottom ? o : o.translate(0, 8), cityStyle, above: nearBottom);
    }

    // "You are here" (demo location)
    final Offset me = proj(kUserLat, kUserLon);
    canvas.drawCircle(me, 14, Paint()..color = const Color(0xFF7FA7D9).withValues(alpha: 0.18));
    canvas.drawCircle(me, 5, Paint()..color = const Color(0xFF7FA7D9));
    canvas.drawCircle(me, 5, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Markers — selected one drawn last, enlarged and labelled
    Place? selected;
    for (final Place p in places) {
      if (p.id == selectedId) {
        selected = p;
        continue;
      }
      final Offset o = proj(p.lat, p.lon);
      final Color c = placeColor(p.type);
      canvas.drawCircle(o, 6.5, Paint()..color = c);
      canvas.drawCircle(o, 6.5, Paint()
        ..color = _land
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
    if (selected != null) {
      final Offset o = proj(selected.lat, selected.lon);
      final Color c = placeColor(selected.type);
      canvas.drawCircle(o, 16, Paint()..color = c.withValues(alpha: 0.25));
      canvas.drawCircle(o, 9.5, Paint()..color = c);
      canvas.drawCircle(o, 9.5, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
      _label(
        canvas,
        selected.name,
        o,
        const TextStyle(color: BrewColors.text, fontSize: 12, fontWeight: FontWeight.w700, shadows: <Shadow>[
          Shadow(color: Colors.black, blurRadius: 4),
        ]),
        above: true,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.selectedId != selectedId || old.places != places || old.bounds != bounds;
}
