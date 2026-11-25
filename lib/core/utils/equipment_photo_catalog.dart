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

    // 3. Abdominal Bandage (תחבושת בטן / תחבושת גדולה מאוד לבטן)
    if (name.contains('תחבושת בטן') || name.contains('לבטן')) {
      return 'assets/images/eq_abdominal_bandage.png';
    }

    // 4. First Care Israeli Emergency Bandage (תחבושת אישית First Care)
    if (name.contains('תחבושת אישית') ||
        name.contains('תחבושות אישיות') ||
        name.contains('first care')) {
      return 'assets/images/eq_first_care_bandage.jpg';
    }

    // 5. Micropore Surgical Tape Roll (גליל פלסטר רפואי דביק / מיקרופור)
    if (name.contains('מיקרופור') ||
        name.contains('גליל פלסטר') ||
        name.contains('גלילי פלסטר')) {
      return 'assets/images/eq_micropore.png';
    }

    // 6. Triangular Bandage (משולש בד לחבישה וקיבוע)
    if (name.contains('משולש בד') || name.contains('משולשי בד')) {
      return 'assets/images/eq_triangular_bandage.png';
    }

    // 7. Sterile Gauze Pad (פד גזה / פדים סטריליים מבד גזה)
    if (name.contains('פד גזה') || name.contains('פדים סטריליים')) {
      return 'assets/images/eq_gauze_pad.png';
    }

    // 8. Adhesive Plasters Box (פלסטרים קטנים לפצעים)
    if (name.contains('פלסטרים קטנים') || name == 'פלסטר' || name == 'פלסטרים') {
      return 'assets/images/eq_plasters_box.png';
    }

    // 9. Thermal Rescue Blanket (שמיכת מילוט)
    if (name.contains('שמיכת מילוט') || name.contains('היפותרמיה')) {
      return 'assets/images/eq_thermal_blanket.png';
    }

    // 10. Elastic Bandage (תחבושת אלסטית)
    if (name.contains('תחבושת אלסטית')) {
      return 'assets/images/eq_elastic_bandage.png';
    }

    // 11. Gauze Bandage Roll (אגד גזה)
    if (name.contains('אגד גזה')) {
      return 'assets/images/eq_gauze_roll.png';
    }

    // 12. Disposable Nitrile Gloves (כפפות רפואיות חד פעמיות)
    if (name.contains('כפפות')) {
      return 'assets/images/eq_gloves.png';
    }

    // 13. Digital Thermometer (מדחום למדידת חום)
    if (name.contains('מדחום')) {
      return 'assets/images/eq_thermometer.png';
    }

    // 14. Manual Blood Pressure Cuff & Stethoscope (מד לחץ דם ידני / סטטוסקופ)
    if (name.contains('לחץ דם') || name.contains('סטטוסקופ')) {
      return 'assets/images/eq_bp_cuff_stethoscope.png';
    }

    // 15. Fingertip Pulse Oximeter (מד סטורציה / מכשיר לחמצן בדם)
    if (name.contains('סטורציה') || name.contains('חמצן בדם')) {
      return 'assets/images/eq_pulse_oximeter.png';
    }

    // 16. Cotton Swabs / Q-Tips (צמרוני אוזניים / מקלוני עץ ארוכים עם צמר גפן)
    if (name.contains('צמרוני') ||
        name.contains('מקלוני עץ') ||
        (name.contains('מקלוני') && name.contains('צמר גפן'))) {
      return 'assets/images/eq_cotton_swabs.png';
    }

    // 17. Cotton Wool Bag (צמר גפן לחיטוי וחבישה / שקיות צמר גפן גדולות)
    if (name.contains('צמר גפן')) {
      return 'assets/images/eq_cotton_wool.png';
    }

    // 18. Trauma Shears (מלע"כ / מספריים רפואיים / מספרי חובשים)
    if (name.contains('מלע"כ') ||
        name.contains('מלעכ') ||
        name.contains('מספריים') ||
        name.contains('מספרי חובשים')) {
      return 'assets/images/eq_trauma_shears.png';
    }

    // 19. Hartmann's IV Solution (תמיסת הרטמן / שקיות נוזלים לעירוי הרטמן)
    if (name.contains('הרטמן') || name.contains('שקיות נוזלים לעירוי')) {
      return 'assets/images/eq_hartmann_solution.png';
    }

    // 20. Orange Venflon 14G / Airway Needle (ונפלון כתום 14G / מחטים חלולות לנקז אוויר AW)
    if (name.contains('14g') ||
        name.contains('כתום') ||
        name.contains('נקז אוויר') ||
        name.contains('(aw)')) {
      return 'assets/images/eq_venflon_orange_14g.png';
    }

    // 21. Green Venflon 18G / Standard Venflon (ונפלון ירוק 18G / מחטי וונפלון)
    if (name.contains('18g') ||
        name.contains('ונפלון ירוק') ||
        (name.contains('ונפלון') && !name.contains('22g') && !name.contains('כחול'))) {
      return 'assets/images/eq_venflon_green_18g.png';
    }

    return null;
  }
}
