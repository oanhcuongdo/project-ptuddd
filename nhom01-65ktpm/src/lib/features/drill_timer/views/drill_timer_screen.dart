import 'package:flutter/material.dart';
import '../models/drill_item.dart';
import '../services/drill_timer_service.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_display.dart';

class DrillTimerScreen extends StatefulWidget {
  final DrillItem drill;

  const DrillTimerScreen({
    super.key,
    required this.drill,
  });

  @override
  State<DrillTimerScreen> createState() => _DrillTimerScreenState();
}

class _DrillTimerScreenState extends State<DrillTimerScreen> {
  late final DrillTimerService _timerService;

  @override
  void initState() {
    super.initState();
    _timerService = DrillTimerService();
    _timerService.selectDrill(widget.drill);
  }

  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }

  Future<bool> _confirmExit() async {
    if (_timerService.isIdle || _timerService.isCompleted) {
      return true;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Thoát phiên tập?',
          style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Đồng hồ đang chạy, thời gian tập hiện tại sẽ không được lưu nếu bạn thoát ngay.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Ở lại',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text(
              'Thoát',
              style: TextStyle(color: Color(0xFFFFFFFF)),
            ),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  Future<void> _confirmFinishEarly() async {
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Kết thúc sớm buổi tập?',
          style: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn đã tập được ${_timerService.actualMinutesTrained} phút. Bạn muốn kết thúc và ghi nhận kết quả này không?',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Tiếp tục tập',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text(
              'Kết thúc',
              style: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (shouldFinish == true) {
      _timerService.finishSessionEarly();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canLeave = await _confirmExit();
        if (canLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1117),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFFF8FAFC),
            ),
            onPressed: () async {
              final canLeave = await _confirmExit();
              if (canLeave && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            widget.drill.title,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ListenableBuilder(
              listenable: _timerService,
              builder: (context, _) {
                return Column(
                  children: [
                    _buildDrillInfoCard(),
                    const Spacer(),
                    TimerDisplay(
                      formattedTime: _timerService.formattedRemainingTime,
                      progress: _timerService.progress,
                      status: _timerService.status,
                      currentSet: _timerService.currentSet,
                      totalSets: _timerService.totalSets,
                    ),
                    const Spacer(),
                    TimerControls(
                      status: _timerService.status,
                      onStart: _timerService.start,
                      onPause: _timerService.pause,
                      onResume: _timerService.resume,
                      onReset: _timerService.reset,
                      onNextSet: _timerService.nextSetOrFinish,
                      onSkipRest: _timerService.skipRest,
                      onFinishEarly: _confirmFinishEarly,
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrillInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.drill.category,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${widget.drill.durationMinutes} phút • ${widget.drill.sets} hiệp',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (widget.drill.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.drill.description,
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
