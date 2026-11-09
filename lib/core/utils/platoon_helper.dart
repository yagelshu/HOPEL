class PlatoonHelper {
  /// Known non-numbered company platoons / units
  static const Set<String> _specialPlatoons = {
    'מפלג',
    'חפ"ק',
    'חפק',
    'רתק',
    'מרגמות',
    'צילף',
    'את"ק',
    'אתק',
    'מפקדה',
    'פלוגה',
  };

  /// Normalizes any platoon string into a canonical representation:
  /// - '1' -> 'מחלקה 1'
  /// - 'מחלקה 1' -> 'מחלקה 1'
  /// - 'מחלקה1' -> 'מחלקה 1'
  /// - 'מחלקה מחלקה 1' -> 'מחלקה 1'
  /// - 'מפלג' -> 'מפלג'
  /// - 'מחלקה מפלג' -> 'מפלג'
  static String normalize(String? raw) {
    if (raw == null) return '';
    var s = raw.trim();
    if (s.isEmpty) return '';

    // Strip multiple redundant 'מחלקה' prefixes (e.g. 'מחלקה מחלקה 1' -> '1')
    while (s.startsWith('מחלקה מחלקה')) {
      s = s.replaceFirst('מחלקה', '').trim();
    }

    // Check if it's 'מחלקה מפלג' -> 'מפלג'
    for (final sp in _specialPlatoons) {
      if (s.startsWith('מחלקה $sp') || s == 'מחלקה $sp') {
        return sp;
      }
    }

    // Check if it is a pure digit: '1', '2', '3', '4'...
    final numOnly = RegExp(r'^(\d+)$').firstMatch(s);
    if (numOnly != null) {
      return 'מחלקה ${numOnly.group(1)}';
    }

    // Check if it is 'מחלקה1' -> 'מחלקה 1'
    final noSpaceNum = RegExp(r'^מחלקה\s*(\d+)$').firstMatch(s);
    if (noSpaceNum != null) {
      return 'מחלקה ${noSpaceNum.group(1)}';
    }

    // Check if it already starts with 'מחלקה '
    if (s.startsWith('מחלקה ')) {
      return s;
    }

    // If it's one of the known special units
    if (_specialPlatoons.contains(s)) {
      return s;
    }

    return s;
  }

  /// Formats the platoon for UI display.
  /// Guaranteed to NEVER output 'מחלקה מחלקה 1' or 'מחלקה מפלג'.
  static String formatDisplay(String? raw) {
    final n = normalize(raw);
    return n;
  }

  /// Extracts a deduplicated and sorted list of platoons from a collection of items.
  /// Canonicalizes variants like '3' and 'מחלקה 3' into a single 'מחלקה 3'.
  static List<String> extractPlatoons<T>(
    Iterable<T> items,
    String? Function(T item) platoonGetter, {
    bool includeAll = true,
  }) {
    final platoonsSet = <String>{};

    for (final item in items) {
      final raw = platoonGetter(item);
      final norm = normalize(raw);
      if (norm.isNotEmpty) {
        platoonsSet.add(norm);
      }
    }

    final sorted = platoonsSet.toList()
      ..sort((a, b) {
        // Special platoons first (like מפלג) or numbered
        final aIsSpecial = _specialPlatoons.contains(a);
        final bIsSpecial = _specialPlatoons.contains(b);
        if (aIsSpecial && !bIsSpecial) return -1;
        if (!aIsSpecial && bIsSpecial) return 1;
        return a.compareTo(b);
      });

    return [
      if (includeAll) 'הכל',
      ...sorted,
    ];
  }

  /// Compares two platoon strings under canonical normalization.
  static bool matches(String? a, String? b) {
    if (a == null || b == null) return false;
    final normA = normalize(a);
    final normB = normalize(b);
    if (normA.isEmpty || normB.isEmpty) return false;
    return normA == normB;
  }
}

