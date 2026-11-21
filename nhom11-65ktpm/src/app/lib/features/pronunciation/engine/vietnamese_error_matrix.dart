class VietnameseErrorMatrix {
  // Cac cap phu am dau nguoi Viet Nam thuong xuyen nham lan
  static const Map<String, List<String>> _confusableInitials = {
    'zh': ['z', 'j'],
    'z': ['zh'],
    'ch': ['c', 'q'],
    'c': ['ch'],
    'sh': ['s', 'x'],
    's': ['sh'],
    'j': ['q', 'zh', 'z'],
    'q': ['ch', 'j', 'c'],
    'x': ['s', 'sh'],
    'l': ['n'],
    'n': ['l'],
    'h': ['k'],
  };

  // Cac cap van mau de nham
  static const Map<String, List<String>> _confusableFinals = {
    'u': ['ü', 'v', 'ou'],
    'ü': ['u', 'v'],
    'v': ['u', 'ü'],
    'an': ['ang'],
    'ang': ['an'],
    'en': ['eng'],
    'eng': ['en'],
    'in': ['ing'],
    'ing': ['in'],
    'ian': ['iang'],
    'iang': ['ian'],
  };

  // Phat diem thanh mau:
  // - Giong hoan toan: 0 phat
  // - Nham trong cap pho bien cua nguoi Viet: phat nhe 15 diem
  // - Sai hoan toan khong lien quan: phat nang 40 diem
  static double calculateInitialPenalty(String expected, String actual) {
    if (expected == actual) return 0.0;
    if (_confusableInitials[expected]?.contains(actual) == true ||
        _confusableInitials[actual]?.contains(expected) == true) {
      return 15.0;
    }
    return 40.0;
  }

  // Phat diem van mau:
  static double calculateFinalPenalty(String expected, String actual) {
    if (expected == actual) return 0.0;
    if (_confusableFinals[expected]?.contains(actual) == true ||
        _confusableFinals[actual]?.contains(expected) == true) {
      return 15.0;
    }
    return 40.0;
  }

  // Phat diem thanh dieu:
  // - Thanh 2 voi Thanh 3: nguoi Viet rat hay nham do tuong dong dau hoi / nga / sac: phat nhe 12 diem
  // - Thanh khac: phat 30 diem
  static double calculateTonePenalty(int expectedTone, int actualTone) {
    if (expectedTone == actualTone) return 0.0;
    if ((expectedTone == 2 && actualTone == 3) || (expectedTone == 3 && actualTone == 2)) {
      return 12.0;
    }
    return 30.0;
  }
}
