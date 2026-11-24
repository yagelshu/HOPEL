/// Maps standard IDF medical equipment names (including legacy & updated variations)
/// to their built-in real product photos under `assets/images/`.
class EquipmentPhotoCatalog {
  static String? resolveBuiltInPhoto(String rawName) {
    final name = rawName.trim().toLowerCase();
    if (name.isEmpty) return null;

    // 1. QuikClot Combat Gauze (קומבאט גז / תחבושת מיוחדת שעוצרת דימומים)
    if (name.contains('קומבאט') ||
        name.contains('combat') ||
        name.contains('שעוצרת דימומים')) {
      return 'assets/images/eq_combat_gauze.jpg';
    }

    // 2. H&H Compressed Gauze (גזה דחוסה לספיגה ועצירת דימומים)
    if (name.contains('גזה דחוסה') || name.contains('compressed')) {
      return 'assets/images/eq_compressed_gauze.jpg';
    }

    // 3. First Care Israeli Emergency Bandage (תחבושת אישית First Care)
    if (name.contains('תחבושת אישית') ||
        name.contains('תחבושות אישיות') ||
        name.contains('first care')) {
      return 'assets/images/eq_first_care_bandage.jpg';
    }

    // 4. Micropore Surgical Tape Roll (גליל פלסטר רפואי דביק / מיקרופור)
    if (name.contains('מיקרופור') ||
        name.contains('גליל פלסטר') ||
        name.contains('גלילי פלסטר')) {
      return 'assets/images/eq_micropore.png';
    }

    // 5. Triangular Bandage (משולש בד לחבישה וקיבוע)
    if (name.contains('משולש בד') || name.contains('משולשי בד')) {
      return 'assets/images/eq_triangular_bandage.png';
    }

    // 6. Sterile Gauze Pad (פד גזה / פדים סטריליים מבד גזה)
    if (name.contains('פד גזה') || name.contains('פדים סטריליים')) {
      return 'assets/images/eq_gauze_pad.png';
    }

    // 7. Adhesive Plasters Box (פלסטרים קטנים לפצעים)
    if (name.contains('פלסטרים קטנים') || name == 'פלסטר' || name == 'פלסטרים') {
      return 'assets/images/eq_plasters_box.png';
    }

    // 8. Thermal Rescue Blanket (שמיכת מילוט)
    if (name.contains('שמיכת מילוט') || name.contains('היפותרמיה')) {
      return 'assets/images/eq_thermal_blanket.png';
    }

    // 9. Elastic Bandage (תחבושת אלסטית)
    if (name.contains('תחבושת אלסטית')) {
      return 'assets/images/eq_elastic_bandage.png';
    }

    // 10. Gauze Bandage Roll (אגד גזה)
    if (name.contains('אגד גזה')) {
      return 'assets/images/eq_gauze_roll.png';
    }

    // 11. Disposable Nitrile Gloves (כפפות רפואיות חד פעמיות)
    if (name.contains('כפפות')) {
      return 'assets/images/eq_gloves.png';
    }

    // 12. Digital Thermometer (מדחום למדידת חום)
    if (name.contains('מדחום')) {
      return 'assets/images/eq_thermometer.png';
    }

    // 13. Manual Blood Pressure Cuff & Stethoscope (מד לחץ דם ידני / סטטוסקופ)
    if (name.contains('לחץ דם') || name.contains('סטטוסקופ')) {
      return 'assets/images/eq_bp_cuff_stethoscope.png';
    }

    // 14. Fingertip Pulse Oximeter (מד סטורציה / מכשיר לחמצן בדם)
    if (name.contains('סטורציה') || name.contains('חמצן בדם')) {
      return 'assets/images/eq_pulse_oximeter.png';
    }

    // 15. Cotton Swabs / Q-Tips (צמרוני אוזניים / מקלוני עץ ארוכים עם צמר גפן)
    if (name.contains('צמרוני') ||
        name.contains('מקלוני עץ') ||
        (name.contains('מקלוני') && name.contains('צמר גפן'))) {
      return 'assets/images/eq_cotton_swabs.png';
    }

    return null;
  }
}

