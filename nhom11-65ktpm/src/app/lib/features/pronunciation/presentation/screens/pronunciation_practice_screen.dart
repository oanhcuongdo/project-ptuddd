import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/contracts/models/pronunciation.dart';
import '../../../../core/contracts/pronunciation_scorer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';
import '../controllers/pronunciation_controller.dart';

/// Màn hình luyện phát âm và xem phản hồi chi tiết chuẩn Liquid Glass UI.
/// Chủ sở hữu: Khánh (#15)
class PronunciationPracticeScreen extends ConsumerStatefulWidget {
  final String targetHanzi;
  final String targetPinyin;
  final String meaning;
  final String? lessonId;
  final String? initialWord;

  const PronunciationPracticeScreen({
    super.key,
    this.targetHanzi = '你好',
    this.targetPinyin = 'nǐ hǎo',
    this.meaning = 'Xin chào',
    this.lessonId,
    this.initialWord,
  });

  @override
  ConsumerState<PronunciationPracticeScreen> createState() => _PronunciationPracticeScreenState();
}

class _PronunciationPracticeScreenState extends ConsumerState<PronunciationPracticeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pronunciationControllerProvider.notifier).init(
        targetHanzi: widget.targetHanzi,
        targetPinyin: widget.targetPinyin,
        meaning: widget.meaning,
        lessonId: widget.lessonId,
        initialWord: widget.initialWord,
      );
    });
  }

  void _showSupportExercises(PronunciationResult res) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final errorSyllables = res.syllables.where((s) => s.status != SyllableStatus.ok).toList();
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E232A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Bài Tập Bổ Trợ Phát Âm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Luyện tập các cặp âm tương phản để khắc phục lỗi ngữ âm thường gặp của người Việt:',
                style: TextStyle(color: AppColors.cloud, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (errorSyllables.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.jadeGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Phát âm của bạn đã rất chuẩn! Hãy tiếp tục luyện các từ tiếp theo để duy trì phong độ.',
                    style: TextStyle(color: AppColors.jadeGreen, fontSize: 13),
                  ),
                )
              else ...[
                for (final s in errorSyllables)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Text(s.hanzi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Luyện âm: ${s.expected.initial.isNotEmpty ? s.expected.initial : s.expected.finalPart} (Thanh ${s.expected.tone})',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                              ),
                              Text(
                                s.expected.tone == 3
                                    ? 'Cặp luyện: 你好 (ní hǎo) ↔ 我想 (wó xiǎng)'
                                    : s.expected.initial == 'zh' || s.expected.initial == 'z'
                                        ? 'Cặp đối chiếu: 这 (zhè) ↔ 早 (zǎo)'
                                        : 'Lặp lại 3 lần to và rõ ràng âm tiết "${s.hanzi}".',
                                style: const TextStyle(color: AppColors.cloud, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  icon: Icons.check,
                  label: 'Đã hiểu, quay lại luyện tập',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pronunciationControllerProvider);
    final controller = ref.read(pronunciationControllerProvider.notifier);
    final mode = ref.watch(scoringModeProvider);
    final tipsAsync = ref.watch(pronunciationTipsProvider);
    final tipsMap = tipsAsync.asData?.value ?? const {};

    // Lắng nghe thông báo lỗi và quyền micro
    ref.listen<PronunciationState>(pronunciationControllerProvider, (prev, next) {
      if (next.permissionDenied && next.errorMessage != null && prev?.permissionDenied != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Đã hiểu',
              textColor: Colors.white,
              onPressed: () => controller.dismissError(),
            ),
          ),
        );
      }
    });

    if (state.isInitializing) {
      return const GlassScaffold(
        appBar: GlassAppBar(
          title: Text('Luyện Phát Âm'),
        ),
        body: Center(
          child: GlassCard(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Đang chuẩn bị âm thanh & micro...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sẵn sàng phát âm và nhận diện không gián đoạn',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.cloud,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final curWord = state.currentWord;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Luyện Phát Âm'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () {
                  ref.read(scoringModeProvider.notifier).set(
                    mode == ScoringMode.preferOnline ? ScoringMode.offlineOnly : ScoringMode.preferOnline,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: ShapeDecoration(
                    color: (mode == ScoringMode.preferOnline ? AppColors.infoBlue : AppColors.warningOrange).withValues(alpha: 0.2),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    mode == ScoringMode.preferOnline ? 'Online (Azure)' : 'Offline',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 104, left: 20, right: 20, bottom: 32),
        child: Column(
          children: [
            if (mode == ScoringMode.offlineOnly)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.warningOrange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chế độ Offline: Kiểm tra đúng/sai chữ Hán. Chuyển sang Online (Azure) để chấm chi tiết thanh điệu & âm phổ.',
                        style: TextStyle(fontSize: 12, color: AppColors.cloud),
                      ),
                    ),
                  ],
                ),
              ),

            GlassCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: state.currentWordIndex > 0 ? () => controller.prevWord() : null,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        tooltip: 'Từ trước',
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: ShapeDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          'Từ ${state.currentWordIndex + 1} / ${state.words.length}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      IconButton(
                        onPressed: state.currentWordIndex < state.words.length - 1 ? () => controller.nextWord() : null,
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        tooltip: 'Từ sau',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    curWord.hanzi,
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    curWord.pinyin,
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    curWord.meaning,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.cloud,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      GlassButton(
                        onPressed: state.isPlayingTts ? null : () => controller.playTts(slow: false),
                        icon: state.isPlayingTts ? Icons.graphic_eq : Icons.volume_up_rounded,
                        label: 'Nghe mẫu',
                      ),
                      GlassButton(
                        onPressed: state.isPlayingTts ? null : () => controller.playTts(slow: true),
                        icon: Icons.slow_motion_video,
                        label: 'Chậm 0.7x',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sóng âm thanh động Visualizer
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(15, (index) {
                  final centerDist = (index - 7).abs();
                  final factor = (1.0 - (centerDist / 8.0)).clamp(0.2, 1.0);
                  final ampVal = state.isRecording ? (state.currentAmplitude * factor).clamp(0.08, 1.0) : 0.08;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 4,
                    height: 40 * ampVal + 4,
                    decoration: BoxDecoration(
                      color: state.isRecording
                          ? (index % 2 == 0 ? AppColors.primary : AppColors.secondary)
                          : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),

            // Lời thoại đang nhận diện từ SpeechToText
            if (state.isRecording || state.recognizedWords.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isRecording ? Icons.mic : Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        state.recognizedWords.isEmpty ? 'Đang lắng nghe giọng đọc...' : 'Đang nghe: "${state.recognizedWords}"',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Nút Micro chính
            GestureDetector(
              onTap: state.isAssessing
                  ? null
                  : () {
                      if (state.isRecording) {
                        controller.stopAndAssess();
                      } else {
                        controller.startRecording();
                      }
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isRecording ? AppColors.errorRed : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (state.isRecording ? AppColors.errorRed : AppColors.primary).withValues(alpha: state.isRecording ? 0.5 : 0.25),
                      blurRadius: state.isRecording ? 20 : 12,
                      spreadRadius: state.isRecording ? 6 : 2,
                    )
                  ],
                ),
                child: Icon(
                  state.isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.isRecording ? 'Đang lắng nghe... Chạm nút để gửi hoặc dừng nói 2.5s' : 'Chạm vào micro để bắt đầu nói',
              style: const TextStyle(color: AppColors.cloud, fontSize: 13),
            ),

            if (kDebugMode && !state.isRecording && !state.isAssessing) ...[
              const SizedBox(height: 14),
              const Text('Kiểm tra nhanh bắt lỗi dấu Pinyin (Debug):', style: TextStyle(color: AppColors.cloud, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.jadeGreen),
                    label: const Text('nǐ hǎo (Chuẩn 100đ)', style: TextStyle(fontSize: 12)),
                    onPressed: () => controller.testPinyinDirectly('nǐ hǎo'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.errorRed),
                    label: const Text('ni háo (Sai cả 2 thanh)', style: TextStyle(fontSize: 12)),
                    onPressed: () => controller.testPinyinDirectly('ni háo'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.errorRed),
                    label: const Text('nĩ hào (Sai thanh 4)', style: TextStyle(fontSize: 12)),
                    onPressed: () => controller.testPinyinDirectly('nĩ hào'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warningOrange),
                    label: const Text('nỉ hao (Sai thanh nhẹ)', style: TextStyle(fontSize: 12)),
                    onPressed: () => controller.testPinyinDirectly('nỉ hao'),
                  ),
                ],
              ),
            ],

            if (state.isAssessing) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Đang phân tích phát âm...'),
            ],

            if (state.result != null) ...[
              const SizedBox(height: 28),
              _buildFeedbackCard(state.result!, state, controller, tipsMap),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(
    PronunciationResult res,
    PronunciationState state,
    PronunciationController controller,
    Map<String, PronunciationTip> tipsMap,
  ) {
    Color scoreColor = AppColors.jadeGreen;
    if (res.overall < 60) {
      scoreColor = AppColors.errorRed;
    } else if (res.overall < 80) {
      scoreColor = AppColors.warningOrange;
    }

    return GlassCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kết Quả Đánh Giá Chi Tiết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      'Nguồn: ${res.source == ScoringSource.online ? "Azure Speech (Online)" : "Engine Offline (Kiểm tra đúng/sai chữ)"}',
                      style: const TextStyle(color: AppColors.cloud, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: ShapeDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '${res.overall.toInt()} đ',
                  style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (res.overall == 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic_off, color: AppColors.errorRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.recognizedWords.trim().isNotEmpty
                          ? 'Đã nhận diện âm "${state.recognizedWords.trim()}" nhưng chưa khớp chính xác từ cần luyện (${state.currentWord.hanzi}). Hãy thử đọc lại rõ ràng hơn!'
                          : 'Chưa nhận diện được phát âm tiếng Trung. Hãy thử nói to hơn gần micro máy tính hoặc kiểm tra cài đặt mic của máy ảo!',
                      style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (res.recognizedText.isNotEmpty && res.recognizedText != state.currentWord.hanzi)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Âm nhận diện được: "${res.recognizedText}"',
                        style: const TextStyle(fontSize: 13, color: AppColors.slate, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            _buildCoachAdviceBox(res),
            const Text(
              '4 Tiêu Chí Đánh Giá Chuẩn Quốc Tế:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildCriteriaProgress('1. Độ chính xác âm tiết (Accuracy)', res.accuracy, res.accuracy >= 80 ? 'Chuẩn xác' : 'Cần chú ý'),
            _buildCriteriaProgress('2. Thanh điệu ngữ âm (Tone)', res.tone, res.tone >= 80 ? 'Đúng cao độ' : 'Lệch thanh'),
            _buildCriteriaProgress('3. Độ trôi chảy (Fluency)', res.fluency, res.fluency >= 80 ? 'Tự nhiên' : 'Ngắt quãng'),
            _buildCriteriaProgress('4. Độ trọn vẹn từ (Completeness)', res.completeness, res.completeness >= 90 ? 'Đủ âm' : 'Thiếu từ'),
            const SizedBox(height: 16),
            const Text(
              'Phân Tích Giải Phẫu Từng Âm Tiết:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            for (final s in res.syllables) _buildSyllableDetailCard(s, tipsMap),
          ],

          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  icon: Icons.fitness_center_rounded,
                  label: 'Bài tập bổ trợ',
                  onPressed: () => _showSupportExercises(res),
                ),
              ),
              if (state.currentWordIndex < state.words.length - 1) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    icon: Icons.navigate_next,
                    label: 'Từ tiếp: ${state.words[state.currentWordIndex + 1].hanzi}',
                    onPressed: () => controller.nextWord(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoachAdviceBox(PronunciationResult res) {
    String advice;
    IconData icon;
    Color boxColor;

    if (res.overall >= 90) {
      advice = 'Xuất sắc! Phát âm rất chuẩn xác, khẩu hình và thanh điệu tự nhiên như người bản xứ.';
      icon = Icons.stars;
      boxColor = AppColors.jadeGreen;
    } else if (res.overall >= 75) {
      advice = 'Khá tốt! Bạn phát âm từ rõ ràng và người bản xứ hiểu được. Hãy chú ý giữ đúng trường độ thanh điệu để nói tự nhiên hơn.';
      icon = Icons.thumb_up_alt_outlined;
      boxColor = AppColors.primary;
    } else if (res.overall >= 50) {
      advice = 'Cần luyện thêm: Một số âm tiết bị lệch thanh mẫu hoặc thanh điệu. Hãy xem chi tiết phân tích từng phần bên dưới để điều chỉnh khẩu hình.';
      icon = Icons.lightbulb_outline;
      boxColor = AppColors.warningOrange;
    } else {
      advice = 'Hãy nghe mẫu đọc chậm, chú ý mở rộng khẩu hình miệng và đọc dứt khoát từng âm tiết để máy nhận diện rõ ràng hơn.';
      icon = Icons.info_outline;
      boxColor = AppColors.errorRed;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: boxColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: boxColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: boxColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhận Xét Từ Trợ Lý AI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: boxColor),
                ),
                const SizedBox(height: 4),
                Text(
                  advice,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaProgress(String label, double score, String desc) {
    Color barColor = AppColors.jadeGreen;
    if (score < 60) {
      barColor = AppColors.errorRed;
    } else if (score < 80) {
      barColor = AppColors.warningOrange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate)),
              Text(
                '${score.toInt()} đ ($desc)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: barColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.cloud.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyllableDetailCard(SyllableScore s, Map<String, PronunciationTip> tipsMap) {
    Color cardBorder = AppColors.jadeGreen;
    String statusText = 'Chuẩn xác';
    if (s.status == SyllableStatus.error) {
      cardBorder = AppColors.errorRed;
      statusText = 'Sai âm';
    } else if (s.status == SyllableStatus.warn) {
      cardBorder = AppColors.warningOrange;
      statusText = 'Cần sửa';
    }

    final hasInitialError = s.errors.contains(PronunciationError.initial);
    final hasFinalError = s.errors.contains(PronunciationError.finalPart);
    final hasToneError = s.errors.contains(PronunciationError.tone);
    final isMissing = s.errors.contains(PronunciationError.missing);

    // Tra cứu mẹo từ pronunciationTipsProvider (#15)
    String tip = '';
    final initialTip = tipsMap[s.expected.initial];
    final finalTip = tipsMap[s.expected.finalPart];
    final toneTip = tipsMap['tone${s.expected.tone}'];

    if (isMissing) {
      tip = 'Âm tiết bị bỏ sót khi đọc, hãy đọc to và trọn vẹn từ.';
    } else if (hasInitialError && initialTip != null) {
      tip = '${initialTip.title}: ${initialTip.mouthVi} ${initialTip.tongueVi} ${initialTip.compareVi}';
      if (initialTip.examples.isNotEmpty) {
        tip += ' (Ví dụ: ${initialTip.examples.join(', ')})';
      }
    } else if (hasToneError && toneTip != null) {
      tip = '${toneTip.title}: ${toneTip.mouthVi} ${toneTip.tongueVi} ${toneTip.compareVi}';
      if (toneTip.examples.isNotEmpty) {
        tip += ' (Ví dụ: ${toneTip.examples.join(', ')})';
      }
    } else if (hasFinalError && finalTip != null) {
      tip = '${finalTip.title}: ${finalTip.mouthVi} ${finalTip.tongueVi} ${finalTip.compareVi}';
    } else if (hasInitialError && hasToneError) {
      tip = 'Sai phụ âm đầu "${s.expected.initial}" và lệch thanh điệu thanh ${s.expected.tone}.';
    } else if (hasInitialError) {
      tip = 'Chú ý phụ âm đầu "${s.expected.initial}": chú ý khẩu hình và bật hơi đúng.';
    } else if (hasToneError) {
      tip = 'Chú ý thanh điệu: đây là thanh ${s.expected.tone}, kiểm tra cao độ chuẩn.';
    } else if (hasFinalError) {
      tip = 'Chú ý nguyên âm/vần "${s.expected.finalPart}": mở rộng khẩu hình miệng.';
    } else {
      tip = 'Phát âm chuẩn cả thanh mẫu, vận mẫu và thanh điệu!';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBorder.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    s.hanzi,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${s.expected.initial}${s.expected.finalPart}${s.expected.tone}',
                    style: const TextStyle(fontSize: 16, color: AppColors.cloud, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: ShapeDecoration(
                  color: cardBorder.withValues(alpha: 0.15),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '$statusText • ${s.score.toInt()}đ',
                  style: TextStyle(color: cardBorder, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04)),
                children: const [
                  Padding(padding: EdgeInsets.all(6), child: Text('Thành phần', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('Mẫu chuẩn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('Bạn đọc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  Padding(padding: EdgeInsets.all(6), child: Text('Đánh giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('Thanh mẫu', style: TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(s.expected.initial.isNotEmpty ? s.expected.initial : 'Ø', style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(s.actual?.initial.isNotEmpty == true ? s.actual!.initial : 'Ø', style: const TextStyle(fontSize: 12))),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      hasInitialError ? 'Sai âm' : 'Đúng',
                      style: TextStyle(fontSize: 12, color: hasInitialError ? AppColors.errorRed : AppColors.jadeGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('Vận mẫu', style: TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(s.expected.finalPart, style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(s.actual?.finalPart ?? '-', style: const TextStyle(fontSize: 12))),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      hasFinalError ? 'Sai vần' : 'Đúng',
                      style: TextStyle(fontSize: 12, color: hasFinalError ? AppColors.errorRed : AppColors.jadeGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(6), child: Text('Thanh điệu', style: TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text('Thanh ${s.expected.tone}', style: const TextStyle(fontSize: 12))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(s.actual != null ? 'Thanh ${s.actual!.tone}' : '-', style: const TextStyle(fontSize: 12))),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      hasToneError ? 'Lệch thanh' : 'Đúng',
                      style: TextStyle(fontSize: 12, color: hasToneError ? AppColors.errorRed : AppColors.jadeGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.tips_and_updates_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(fontSize: 12, color: AppColors.cloud, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
