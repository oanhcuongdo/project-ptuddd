import 'package:flutter/material.dart';

/// Thanh chọn mục tiêu hằng ngày (phút). Giữ giá trị tạm khi đang kéo và chỉ gọi
/// [onCommit] một lần khi thả tay, để không ghi CSDL và đặt lại lịch nhắc mỗi
/// lần thanh nhích.
class GoalSlider extends StatefulWidget {
  final int minutes;
  final ValueChanged<int> onCommit;
  const GoalSlider({super.key, required this.minutes, required this.onCommit});

  @override
  State<GoalSlider> createState() => _GoalSliderState();
}

class _GoalSliderState extends State<GoalSlider> {
  late double _value = widget.minutes.toDouble();

  @override
  void didUpdateWidget(GoalSlider old) {
    super.didUpdateWidget(old);
    if (old.minutes != widget.minutes) _value = widget.minutes.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ListTile(
        title: const Text('Mục tiêu hằng ngày'),
        subtitle: Text('${_value.round()} phút'),
      ),
      Slider(
        value: _value,
        min: 5,
        max: 60,
        divisions: 11,
        label: '${_value.round()} phút',
        onChanged: (v) => setState(() => _value = v),
        onChangeEnd: (v) => widget.onCommit(v.round()),
      ),
    ]);
  }
}
