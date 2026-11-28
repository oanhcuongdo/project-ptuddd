import 'package:flutter/foundation.dart';
import '../../domain/entities/finger_hand_state.dart';

/// Bộ điều khiển 2 bàn tay Finger Math (Tay Phải: 0..9, Tay Trái: 0..90)
class FingerMathController extends ChangeNotifier {
  FingerHandState _rightHand = const FingerHandState(handType: HandType.rightHand);
  FingerHandState _leftHand = const FingerHandState(handType: HandType.leftHand);
  final bool showLeftHand; // true: hiển thị 2 bàn tay (0..99), false: chỉ hiển thị tay phải (0..9)
  VoidCallback? onHandChanged;

  FingerMathController({
    this.showLeftHand = true,
    this.onHandChanged,
  });

  FingerHandState get rightHand => _rightHand;
  FingerHandState get leftHand => _leftHand;

  /// Tổng giá trị số của hệ thống Finger Math (0 đến 99)
  int get totalValue {
    if (!showLeftHand) {
      return _rightHand.digitValue;
    }
    return (_leftHand.digitValue * 10) + _rightHand.digitValue;
  }

  /// Mô tả trạng thái 2 bàn tay bằng lời nói tiếng Việt chuẩn cho trợ lý giọng nói
  String get speechDescription {
    final rightVal = _rightHand.digitValue;
    final leftVal = _leftHand.digitValue;

    if (!showLeftHand || leftVal == 0) {
      if (rightVal == 0) return 'Tay phải nắm tay, bằng 0';
      return '${_rightHand.fingerDescription}, bằng $rightVal';
    }

    return 'Tay trái $leftVal chục, tay phải $rightVal đơn vị. Tổng là $totalValue';
  }

  void reset() {
    _rightHand = const FingerHandState(handType: HandType.rightHand);
    _leftHand = const FingerHandState(handType: HandType.leftHand);
    notifyListeners();
    onHandChanged?.call();
  }

  void toggleThumb(HandType handType) {
    if (handType == HandType.rightHand) {
      _rightHand = _rightHand.copyWith(isThumbExtended: !_rightHand.isThumbExtended);
    } else {
      _leftHand = _leftHand.copyWith(isThumbExtended: !_leftHand.isThumbExtended);
    }
    notifyListeners();
    onHandChanged?.call();
  }

  void setExtendedFingers(HandType handType, int count) {
    final clamped = count.clamp(0, 4);
    if (handType == HandType.rightHand) {
      if (_rightHand.extendedFingersCount == clamped) {
        _rightHand = _rightHand.copyWith(extendedFingersCount: 0);
      } else {
        _rightHand = _rightHand.copyWith(extendedFingersCount: clamped);
      }
    } else {
      if (_leftHand.extendedFingersCount == clamped) {
        _leftHand = _leftHand.copyWith(extendedFingersCount: 0);
      } else {
        _leftHand = _leftHand.copyWith(extendedFingersCount: clamped);
      }
    }
    notifyListeners();
    onHandChanged?.call();
  }

  void setValue(int value) {
    final clamped = value.clamp(0, 99);
    final tens = clamped ~/ 10;
    final units = clamped % 10;
    _leftHand = FingerHandState.fromValue(tens, handType: HandType.leftHand);
    _rightHand = FingerHandState.fromValue(units, handType: HandType.rightHand);
    notifyListeners();
    onHandChanged?.call();
  }
}
