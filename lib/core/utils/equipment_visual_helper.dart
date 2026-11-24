import 'package:flutter/material.dart';

enum EquipmentVisualType {
  catTourniquet,
  traumaBandage,
  ivFluidBag,
  epipenInjector,
  medicationBlister,
  syringeNeedle,
  ointmentTube,
  antisepticBottle,
  diagnosticDevice,
  traumaShears,
  gauzePlaster,
  militaryMedKit,
}

class EquipmentVisualHelper {
  /// Resolves the specific visual archetype for any IDF standard equipment item by name.
  static EquipmentVisualType resolveType(String rawName, {String? itemType}) {
    final name = rawName.toLowerCase();

    if (name.contains('חוסמי עורקים') ||
        name.contains('חסם עורקים') ||
        name.contains('cat') ||
        name.contains('חוסם ורידים')) {
      return EquipmentVisualType.catTourniquet;
    }
    if (name.contains('אפיפן') || name.contains('epipen')) {
      return EquipmentVisualType.epipenInjector;
    }
    if (name.contains('נוזלים') ||
        name.contains('הרטמן') ||
        name.contains('סליין') ||
        name.contains('לשטיפת פצעים')) {
      return EquipmentVisualType.ivFluidBag;
    }
    if (name.contains('תחבושת') ||
        name.contains('תחבושות') ||
        name.contains('משולשי בד')) {
      return EquipmentVisualType.traumaBandage;
    }
    if (name.contains('אקמול') ||
        name.contains('אופטלגין') ||
        name.contains('אימודיום') ||
        name.contains('צרבת') ||
        name.contains('כדורי')) {
      return EquipmentVisualType.medicationBlister;
    }
    if (name.contains('וונפלון') ||
        name.contains('מזרק') ||
        name.contains('מחט') ||
        name.contains('aw') ||
        name.contains('נקז אוויר')) {
      return EquipmentVisualType.syringeNeedle;
    }
    if (name.contains('משחה') ||
        name.contains('משחת') ||
        name.contains('פיוסידם') ||
        name.contains('זובירקס') ||
        name.contains('שפשפות') ||
        name.contains('פטריות')) {
      return EquipmentVisualType.ointmentTube;
    }
    if (name.contains('פולידין') ||
        name.contains('סביעור') ||
        name.contains('כלורקסידין') ||
        name.contains('אלכוהול') ||
        name.contains('ספריי') ||
        name.contains('יתושים')) {
      return EquipmentVisualType.antisepticBottle;
    }
    if (name.contains('סטורציה') ||
        name.contains('מדחום') ||
        name.contains('לחץ דם') ||
        name.contains('סטטוסקופ') ||
        name.contains('פנס')) {
      return EquipmentVisualType.diagnosticDevice;
    }
    if (name.contains('מספרי') || name.contains('מלע"כ') || name.contains('מלעכ')) {
      return EquipmentVisualType.traumaShears;
    }
    if (name.contains('פדים') ||
        name.contains('גזה') ||
        name.contains('פלסטר') ||
        name.contains('צמר גפן') ||
        name.contains('מקלוני') ||
        name.contains('כפפות')) {
      return EquipmentVisualType.gauzePlaster;
    }
    return EquipmentVisualType.militaryMedKit;
  }

  /// Renders a high-contrast, recognizable medical equipment illustration widget.
  static Widget buildIllustration({
    required String itemName,
    String? itemType,
    double size = 50,
  }) {
    final type = resolveType(itemName, itemType: itemType);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EquipmentIllustrationPainter(type: type, itemName: itemName),
      ),
    );
  }
}

class _EquipmentIllustrationPainter extends CustomPainter {
  final EquipmentVisualType type;
  final String itemName;

  const _EquipmentIllustrationPainter({
    required this.type,
    required this.itemName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (type) {
      case EquipmentVisualType.catTourniquet:
        _paintCatTourniquet(canvas, w, h);
        break;
      case EquipmentVisualType.traumaBandage:
        _paintTraumaBandage(canvas, w, h);
        break;
      case EquipmentVisualType.ivFluidBag:
        _paintIvFluidBag(canvas, w, h);
        break;
      case EquipmentVisualType.epipenInjector:
        _paintEpipen(canvas, w, h);
        break;
      case EquipmentVisualType.medicationBlister:
        _paintMedicationBlister(canvas, w, h);
        break;
      case EquipmentVisualType.syringeNeedle:
        _paintSyringeNeedle(canvas, w, h);
        break;
      case EquipmentVisualType.ointmentTube:
        _paintOintmentTube(canvas, w, h);
        break;
      case EquipmentVisualType.antisepticBottle:
        _paintAntisepticBottle(canvas, w, h);
        break;
      case EquipmentVisualType.diagnosticDevice:
        _paintDiagnosticDevice(canvas, w, h);
        break;
      case EquipmentVisualType.traumaShears:
        _paintTraumaShears(canvas, w, h);
        break;
      case EquipmentVisualType.gauzePlaster:
        _paintGauzePlaster(canvas, w, h);
        break;
      case EquipmentVisualType.militaryMedKit:
        _paintMilitaryMedKit(canvas, w, h);
        break;
    }
  }

  void _paintCatTourniquet(Canvas canvas, double w, double h) {
    // Subtle dark tactical backdrop
    final bg = Paint()..color = const Color(0xFF1E2621);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bg);

    // Main black nylon strap
    final strapPaint = Paint()..color = const Color(0xFF262A2C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.36, h * 0.1, w * 0.28, h * 0.8), const Radius.circular(4)),
      strapPaint,
    );
    final borderPaint = Paint()
      ..color = const Color(0xFF555E62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.36, h * 0.1, w * 0.28, h * 0.8), const Radius.circular(4)),
      borderPaint,
    );

    // Red Tip at top (CAT Gen 7 signature)
    final redTipPaint = Paint()..color = const Color(0xFFE53935);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.38, h * 0.08, w * 0.24, h * 0.14), const Radius.circular(3)),
      redTipPaint,
    );

    // Gray time-strap clip
    final clipPaint = Paint()..color = const Color(0xFFB0BEC5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, h * 0.34, w * 0.36, h * 0.09), const Radius.circular(2)),
      clipPaint,
    );

    // Horizontal windlass rod (מוט הידוק)
    final rodPaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.14, h * 0.48, w * 0.72, h * 0.12), const Radius.circular(4)),
      rodPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.14, h * 0.48, w * 0.72, h * 0.12), const Radius.circular(4)),
      borderPaint,
    );
  }

  void _paintTraumaBandage(Canvas canvas, double w, double h) {
    final bg = Paint()..color = const Color(0xFF1F2B21);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bg);

    // Olive green military bandage roll
    final olivePaint = Paint()..color = const Color(0xFF556B2F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.16, h * 0.24, w * 0.68, h * 0.52), const Radius.circular(8)),
      olivePaint,
    );

    // White sterile pad center band
    final padPaint = Paint()..color = const Color(0xFFECEFF1);
    canvas.drawRect(Rect.fromLTWH(w * 0.34, h * 0.24, w * 0.32, h * 0.52), padPaint);

    // Red medical cross on pad
    final crossPaint = Paint()..color = const Color(0xFFD32F2F);
    canvas.drawRect(Rect.fromLTWH(w * 0.47, h * 0.38, w * 0.06, h * 0.24), crossPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.41, h * 0.47, w * 0.18, h * 0.06), crossPaint);
  }

  void _paintIvFluidBag(Canvas canvas, double w, double h) {
    final bg = Paint()..color = const Color(0xFF162733);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bg);

    // IV bag clear body
    final bagRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.14, w * 0.52, h * 0.64),
      const Radius.circular(8),
    );
    canvas.drawRRect(bagRect, Paint()..color = const Color(0xFFE1F5FE).withValues(alpha: 0.9));

    // Fluid level inside bag
    final fluidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.26, h * 0.32, w * 0.48, h * 0.44),
      const Radius.circular(6),
    );
    canvas.drawRRect(fluidRect, Paint()..color = const Color(0xFF29B6F6).withValues(alpha: 0.55));

    // Measurement ticks
    final tickPaint = Paint()
      ..color = const Color(0xFF0277BD)
      ..strokeWidth = 1.4;
    for (int i = 0; i < 3; i++) {
      final y = h * (0.36 + i * 0.12);
      canvas.drawLine(Offset(w * 0.32, y), Offset(w * 0.46, y), tickPaint);
    }

    // Bottom infusion ports
    final portPaint = Paint()..color = const Color(0xFF0288D1);
    canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.78, w * 0.08, h * 0.12), portPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.54, h * 0.78, w * 0.08, h * 0.12), portPaint);
  }

  void _paintEpipen(Canvas canvas, double w, double h) {
    final bg = Paint()..color = const Color(0xFF2B2415);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bg);

    // Blue safety cap (top)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.38, h * 0.1, w * 0.24, h * 0.16), const Radius.circular(3)),
      Paint()..color = const Color(0xFF1976D2),
    );

    // Yellow EpiPen body
    canvas.drawRect(
      Rect.fromLTWH(w * 0.38, h * 0.26, w * 0.24, h * 0.48),
      Paint()..color = const Color(0xFFFBC02D),
    );

    // White label band
    canvas.drawRect(
      Rect.fromLTWH(w * 0.38, h * 0.40, w * 0.24, h * 0.20),
      Paint()..color = Colors.white,
    );

    // Orange needle tip (bottom)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.38, h * 0.74, w * 0.24, h * 0.16), const Radius.circular(3)),
      Paint()..color = const Color(0xFFF57C00),
    );
  }

  void _paintMedicationBlister(Canvas canvas, double w, double h) {
    final bg = Paint()..color = const Color(0xFF1A2825);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bg);

    // Silver blister foil sheet
    final foilRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.16, w * 0.64, h * 0.68),
      const Radius.circular(6),
    );
    canvas.drawRRect(foilRect, Paint()..color = const Color(0xFFCFD8DC));

    // 4 pills inside blister
    final pillPaint = Paint()..color = Colors.white;
    final scorePaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 1.2;

    final centers = [
      Offset(w * 0.36, h * 0.35),
      Offset(w * 0.64, h * 0.35),
      Offset(w * 0.36, h * 0.65),
      Offset(w * 0.64, h * 0.65),
    ];
    for (final c in centers) {
      canvas.drawCircle(c, w * 0.095, pillPaint);
      canvas.drawLine(Offset(c.dx - w * 0.06, c.dy), Offset(c.dx + w * 0.06, c.dy), scorePaint);
    }
  }

  void _paintSyringeNeedle(Canvas canvas, double w, double h) {
    final bg = Paint()..color = const Color(0xFF17272B);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bg);

    // Plunger top
    final plungerPaint = Paint()..color = const Color(0xFF4FC3F7);
    canvas.drawRect(Rect.fromLTWH(w * 0.36, h * 0.12, w * 0.28, h * 0.06), plungerPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.46, h * 0.18, w * 0.08, h * 0.14), plungerPaint);

    // Clear graduated barrel
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.36, h * 0.32, w * 0.28, h * 0.40), const Radius.circular(3)),
      Paint()..color = const Color(0xFFECEFF1),
    );

    // Graduation ticks
    final tickPaint = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 4; i++) {
      final y = h * (0.38 + i * 0.08);
      canvas.drawLine(Offset(w * 0.38, y), Offset(w * 0.50, y), tickPaint);
    }

    // Green cannula/needle hub & needle tip
    canvas.drawRect(
      Rect.fromLTWH(w * 0.43, h * 0.72, w * 0.14, h * 0.08),
      Paint()..color = const Color(0xFF43A047),
    );
    canvas.drawLine(
      Offset(w * 0.50, h * 0.80),
      Offset(w * 0.50, h * 0.92),
      Paint()
        ..color = const Color(0xFFB0BEC5)
        ..strokeWidth = 1.6,
    );
  }

  void _paintOintmentTube(Canvas canvas, double w, double h) {
    final bg = Paint()..color = const Color(0xFF1E2923);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bg);

    // Cap at top
    canvas.drawRect(
      Rect.fromLTWH(w * 0.42, h * 0.12, w * 0.16, h * 0.12),
      Paint()..color = const Color(0xFF26A69A),
    );

    // Squeeze tube body (trapezoid)
    final path = Path()
      ..moveTo(w * 0.38, h * 0.24)
      ..lineTo(w * 0.62, h * 0.24)
      ..lineTo(w * 0.70, h * 0.82)
      ..lineTo(w * 0.30, h * 0.82)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);

    // Color band on tube
    canvas.drawRect(
      Rect.fromLTWH(w * 0.34, h * 0.46, w * 0.32, h * 0.14),
      Paint()..color = const Color(0xFF26A69A),
    );
    // Bottom crimp seal
    canvas.drawRect(
      Rect.fromLTWH(w * 0.29, h * 0.82, w * 0.42, h * 0.06),
      Paint()..color = const Color(0xFF90A4AE),
    );
  }

  void _paintAntisepticBottle(Canvas canvas, double w, double h) {
    final bg = Paint()..color = const Color(0xFF2A1D1B);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bg);

    // White dropper cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.42, h * 0.12, w * 0.16, h * 0.16), const Radius.circular(2)),
      Paint()..color = Colors.white,
    );

    // Amber/brown iodine antiseptic bottle
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.28, w * 0.44, h * 0.58), const Radius.circular(7)),
      Paint()..color = const Color(0xFF8D3B1A),
    );

    // White clinical label with red stripe
    canvas.drawRect(Rect.fromLTWH(w * 0.30, h * 0.44, w * 0.40, h * 0.26), Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.30, h * 0.52, w * 0.40, h * 0.08),
      Paint()..color = const Color(0xFFD32F2F),
    );
  }

  void _paintDiagnosticDevice(Canvas canvas, double w, double h) {
    final bg = Paint()..color = const Color(0xFF18242C);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bg);

    // Device casing
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, h * 0.16, w * 0.56, h * 0.68), const Radius.circular(10)),
      Paint()..color = const Color(0xFFECEFF1),
    );

    // Digital OLED screen
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.24, w * 0.44, h * 0.32), const Radius.circular(5)),
      Paint()..color = const Color(0xFF102027),
    );

    // Pulse waveform line on screen
    final wavePaint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final wave = Path()
      ..moveTo(w * 0.32, h * 0.42)
      ..lineTo(w * 0.42, h * 0.42)
      ..lineTo(w * 0.47, h * 0.30)
      ..lineTo(w * 0.52, h * 0.50)
      ..lineTo(w * 0.57, h * 0.38)
      ..lineTo(w * 0.68, h * 0.38);
    canvas.drawPath(wave, wavePaint);

    // Power button
    canvas.drawCircle(Offset(w * 0.50, h * 0.70), w * 0.07, Paint()..color = const Color(0xFF0288D1));
  }

  void _paintTraumaShears(Canvas canvas, double w, double h) {
    final bg = Paint()..color = const Color(0xFF1F2427);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bg);

    // Stainless steel angled blades
    final bladePaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.50, h * 0.48), Offset(w * 0.32, h * 0.16), bladePaint);
    canvas.drawLine(Offset(w * 0.50, h * 0.48), Offset(w * 0.68, h * 0.16), bladePaint);

    // Black tactical finger rings
    final handlePaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(Offset(w * 0.34, h * 0.72), w * 0.13, handlePaint);
    canvas.drawCircle(Offset(w * 0.66, h * 0.72), w * 0.13, handlePaint);

    // Pivot screw
    canvas.drawCircle(Offset(w * 0.50, h * 0.48), w * 0.045, Paint()..color = const Color(0xFF78909C));
  }

  void _paintGauzePlaster(Canvas canvas, double w, double h) {
    final bg = Paint()..color = const Color(0xFF1E2824);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bg);

    // White sterile gauze pad / tape roll
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, h * 0.18, w * 0.64, h * 0.64), const Radius.circular(8)),
      Paint()..color = Colors.white,
    );

    // Woven gauze grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..strokeWidth = 1.0;
    for (int i = 1; i <= 3; i++) {
      final pos = 0.18 + i * 0.16;
      canvas.drawLine(Offset(w * pos, h * 0.22), Offset(w * pos, h * 0.78), gridPaint);
      canvas.drawLine(Offset(w * 0.22, h * pos), Offset(w * 0.78, h * pos), gridPaint);
    }

    // Green sterile cross badge
    final crossPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawRect(Rect.fromLTWH(w * 0.47, h * 0.38, w * 0.06, h * 0.24), crossPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.47, w * 0.24, h * 0.06), crossPaint);
  }

  void _paintMilitaryMedKit(Canvas canvas, double w, double h) {
    final bg = Paint()..color = const Color(0xFF1B261E);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)), bg);

    // Olive military box body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.16, h * 0.26, w * 0.68, h * 0.56), const Radius.circular(7)),
      Paint()..color = const Color(0xFF3E5238),
    );

    // Handle on top
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.36, h * 0.16, w * 0.28, h * 0.10), const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF81967A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // White circle with Red Medical Cross
    canvas.drawCircle(Offset(w * 0.50, h * 0.54), w * 0.18, Paint()..color = Colors.white);
    final redPaint = Paint()..color = const Color(0xFFD32F2F);
    canvas.drawRect(Rect.fromLTWH(w * 0.47, h * 0.42, w * 0.06, h * 0.24), redPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.51, w * 0.24, h * 0.06), redPaint);
  }

  @override
  bool shouldRepaint(covariant _EquipmentIllustrationPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.itemName != itemName;
  }
}

