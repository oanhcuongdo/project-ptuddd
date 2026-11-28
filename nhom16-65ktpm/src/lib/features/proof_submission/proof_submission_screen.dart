import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../data/models/challenge_model.dart';
import '../../data/models/proof_model.dart';
import '../../data/repositories/challenge_repository.dart';
import '../../data/repositories/fund_repository.dart';
import '../../data/repositories/proof_repository.dart';
import 'data/mock_ocr_samples.dart';
import 'mlkit_ocr_service.dart';
import 'services/proof_image_storage_service.dart';
import 'services/proof_validation_helper.dart';
import 'widgets/ocr_result_analysis_card.dart';
import 'widgets/proof_image_preview_card.dart';
import 'widgets/submitted_proof_history_list.dart';

/// Màn hình Chụp, Xem trước & Nộp minh chứng thử thách (Sprint 2 - Sprint 3).
/// Tích hợp hoàn chỉnh luồng: Thành viên chụp ảnh ➔ AI OCR phân tích giờ & bài làm
/// ➔ Cảnh báo sơ bộ ➔ Gửi kèm gợi ý AI sang hàng đợi Admin duyệt.
class ProofSubmissionScreen extends StatefulWidget {
  const ProofSubmissionScreen({super.key});

  @override
  State<ProofSubmissionScreen> createState() => _ProofSubmissionScreenState();
}

class _ProofSubmissionScreenState extends State<ProofSubmissionScreen> {
  static const List<ChallengeModel> _fallbackChallenges = [
    ChallengeModel(
      id: 'ch_01',
      title: 'Dậy sớm trước 6:00 sáng',
      description:
          'Chụp ảnh bàn học, đồng hồ hoặc app báo thức chứng minh bạn đã dậy và học bài trước 6h00.',
      rewardAmount: 20000,
      category: 'Kỷ luật',
      icon: 'wb_sunny',
    ),
    ChallengeModel(
      id: 'ch_02',
      title: 'Gia sư dạy học cho trẻ em',
      description:
          'Dạy kèm 1 buổi học (toán, tiếng Việt, tiếng Anh) cho các em nhỏ có hoàn cảnh khó khăn.',
      rewardAmount: 50000,
      category: 'Gia sư',
      icon: 'school',
    ),
    ChallengeModel(
      id: 'ch_03',
      title: 'Giải 5 bài toán tư duy / code thuật toán',
      description:
          'Chụp ảnh bài giải hoặc commit code trên nền tảng LeetCode/HackerRank rèn luyện tư duy.',
      rewardAmount: 30000,
      category: 'Học tập',
      icon: 'psychology',
    ),
    ChallengeModel(
      id: 'ch_04',
      title: 'Chạy bộ 3km hoặc rèn luyện thể thao',
      description:
          'Chụp ảnh màn hình ứng dụng Strava / Smartwatch ghi nhận hoạt động chạy bộ nâng cao sức khỏe.',
      rewardAmount: 25000,
      category: 'Sức khỏe',
      icon: 'directions_run',
    ),
  ];

  final ImagePicker _imagePicker = ImagePicker();
  final MlKitOcrService _ocrService = MlKitOcrService();
  final ProofImageStorageService _storageService =
      const ProofImageStorageService();
  final ProofValidationHelper _validationHelper =
      const ProofValidationHelper();
  final IChallengeRepository _challengeRepository =
      FundRepository.instance.challengeRepo;
  final IProofRepository _proofRepository = FundRepository.instance.proofRepo;

  final TextEditingController _memberNameController = TextEditingController(
    text: 'Nguyễn Trung Kiên',
  );
  final TextEditingController _locationController = TextEditingController(
    text: 'Đại học Thủy Lợi - 175 Tây Sơn, Đống Đa, Hà Nội',
  );
  final TextEditingController _noteController = TextEditingController();

  List<ChallengeModel> _challenges = _fallbackChallenges;
  ChallengeModel _selectedChallenge = _fallbackChallenges.first;
  List<ProofModel> _submittedProofs = [];
  ProofStorageStats? _storageStats;

  StoredProofImage? _storedImage;
  MockOcrSample _selectedSample = mockOcrSamples.first;
  OcrScanResult? _ocrResult;
  bool _isProcessing = false;
  DateTime? _capturedAt;

  @override
  void initState() {
    super.initState();
    _syncCurrentUserName();
    AuthService.instance.addListener(_syncCurrentUserName);
    _runSampleOcr(_selectedSample);
    _loadInitialData();
  }

  void _syncCurrentUserName() {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser != null && currentUser.name.isNotEmpty) {
      _memberNameController.text = currentUser.name;
    }
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_syncCurrentUserName);
    _memberNameController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final stats = await _storageService.getStorageStats();
    if (mounted) {
      setState(() => _storageStats = stats);
    }

    try {
      final dbChallenges = await _challengeRepository.getChallenges();
      final dbProofs = await _proofRepository.getProofs();
      if (!mounted) return;
      setState(() {
        if (dbChallenges.isNotEmpty) {
          _challenges = dbChallenges;
          _selectedChallenge = dbChallenges.first;
        }
        _submittedProofs = dbProofs;
      });
    } catch (_) {
      // Nếu chạy trên nền tảng chưa khởi tạo SQLite (Web/Desktop), dùng danh sách bộ nhớ tạm.
    }
  }

  Future<void> _refreshSubmittedProofs() async {
    final stats = await _storageService.getStorageStats();
    try {
      final dbProofs = await _proofRepository.getProofs();
      if (!mounted) return;
      setState(() {
        _submittedProofs = dbProofs;
        _storageStats = stats;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đồng bộ trạng thái minh chứng mới nhất từ hệ thống.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _storageStats = stats);
    }
  }

  Future<void> _pickAndSaveImage(ImageSource source) async {
    setState(() => _isProcessing = true);
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (pickedFile == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      if (_storedImage != null) {
        await _storageService.deleteStoredImage(_storedImage!.savedPath);
      }

      final stored = await _storageService.saveImageToLocalStorage(
        pickedFile.path,
        challengeId: _selectedChallenge.id,
      );
      final stats = await _storageService.getStorageStats();

      OcrScanResult result;
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        result = await _ocrService.recognizeFromImagePath(
          stored.savedPath,
          targetChallengeId: _selectedChallenge.id,
        );
      } else {
        result = _ocrService.analyzeText(
          _selectedSample.sampleText,
          targetChallengeId: _selectedChallenge.id,
        );
      }

      if (!mounted) return;
      setState(() {
        _storedImage = stored;
        _storageStats = stats;
        _capturedAt = stored.savedAt;
        _ocrResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chụp hoặc lưu ảnh minh chứng: $e')),
      );
    }
  }

  Future<void> _removeSelectedImage() async {
    final current = _storedImage;
    if (current != null) {
      await _storageService.deleteStoredImage(current.savedPath);
    }
    final stats = await _storageService.getStorageStats();
    if (!mounted) return;
    setState(() {
      _storedImage = null;
      _storageStats = stats;
    });
  }

  void _runSampleOcr(MockOcrSample sample) {
    final result = _ocrService.analyzeText(
      sample.sampleText,
      targetChallengeId: _selectedChallenge.id,
    );
    setState(() {
      _selectedSample = sample;
      _capturedAt = DateTime.now();
      _ocrResult = result;
    });
  }

  void _reAnalyzeCurrentTextForChallenge(ChallengeModel challenge) {
    final currentText = _ocrResult?.rawText ?? _selectedSample.sampleText;
    final updatedResult = _ocrService.analyzeText(
      currentText,
      targetChallengeId: challenge.id,
    );
    setState(() {
      _selectedChallenge = challenge;
      _ocrResult = updatedResult;
    });
  }

  ChallengeModel? _findChallengeById(String? challengeId) {
    if (challengeId == null) return null;
    for (final ch in _challenges) {
      if (ch.id == challengeId) return ch;
    }
    return null;
  }

  void _applySuggestedChallenge() {
    final suggestedId = _ocrResult?.analysisDetail?.suggestedChallengeId;
    final target = _findChallengeById(suggestedId);
    if (target == null) return;
    _reAnalyzeCurrentTextForChallenge(target);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chuyển sang thử thách "${target.title}".'),
      ),
    );
  }

  void _autoFillNoteFromOcr() {
    final result = _ocrResult;
    if (result == null || !result.hasText) return;

    final detail = result.analysisDetail;
    final parts = <String>[
      if (result.extractedTime != null) 'Check-in lúc ${result.extractedTime}',
      if (result.extractedDate != null) 'ngày ${result.extractedDate}',
      if (detail != null && detail.homeworkMetrics.isNotEmpty)
        '(${detail.homeworkMetrics.values.join(', ')})',
      if (result.detectedKeywords.isNotEmpty)
        'Nội dung: ${result.detectedKeywords.take(3).join(', ')}',
    ];

    final generatedNote = parts.isNotEmpty
        ? parts.join(' ')
        : result.rawText.split('\n').first.trim();

    setState(() {
      _noteController.text = generatedNote;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã tự động điền thông tin trích xuất từ ảnh vào ghi chú.',
        ),
      ),
    );
  }

  Future<bool> _confirmWarningsDialog(List<String> warnings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Lưu ý kiểm tra từ AI OCR',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hệ thống phát hiện một số điểm cần lưu ý trước khi gửi cho Admin xét duyệt:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(w, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Kiểm tra lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Vẫn gửi duyệt'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _submitProof() async {
    final integrity = await _storageService.verifyImageIntegrity(_storedImage);
    final check = _validationHelper.evaluate(
      memberName: _memberNameController.text,
      selectedChallengeId: _selectedChallenge.id,
      selectedChallengeTitle: _selectedChallenge.title,
      storedImage: _storedImage,
      imageIntegrity: integrity,
      ocrResult: _ocrResult,
    );

    if (!mounted) return;

    if (check.hasBlockingError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(check.blockingError!),
        ),
      );
      return;
    }

    if (check.hasWarnings) {
      final shouldContinue = await _confirmWarningsDialog(check.warnings);
      if (!shouldContinue || !mounted) return;
    }

    final memberName = _memberNameController.text.trim();
    final location = _locationController.text.trim();
    final userNote = _noteController.text.trim();
    final aiHint = _ocrService.buildAdminReviewHint(_ocrResult);
    final now = DateTime.now();

    final combinedNote = [
      aiHint,
      if (location.isNotEmpty) 'Vị trí: $location',
      if (userNote.isNotEmpty) userNote,
    ].join(' | ');

    final singleLineOcr = (_ocrResult?.rawText ?? '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' • ');
    final formattedOcrForAdmin = singleLineOcr.isEmpty
        ? aiHint
        : '$aiHint $singleLineOcr';

    final imagePath =
        _storedImage?.savedPath ??
        'mock://proof_images/${_selectedSample.id}_${now.millisecondsSinceEpoch}.jpg';

    final newProof = ProofModel(
      id: 'proof_${now.millisecondsSinceEpoch}',
      challengeId: _selectedChallenge.id,
      challengeTitle: _selectedChallenge.title,
      memberName: memberName,
      imagePath: imagePath,
      ocrExtractedText: formattedOcrForAdmin,
      detectedTime: _ocrResult?.extractedTime,
      submittedAt: _capturedAt ?? now,
      status: ProofStatus.pending,
      rewardAmount: _selectedChallenge.rewardAmount,
      note: combinedNote,
    );

    try {
      await _proofRepository.submitProof(newProof);
      final updatedProofs = await _proofRepository.getProofs();
      final stats = await _storageService.getStorageStats();
      if (!mounted) return;
      setState(() {
        _submittedProofs = updatedProofs;
        _storageStats = stats;
        _storedImage = null;
        _noteController.clear();
      });
    } catch (_) {
      final stats = await _storageService.getStorageStats();
      if (!mounted) return;
      setState(() {
        _submittedProofs = [newProof, ..._submittedProofs];
        _storageStats = stats;
        _storedImage = null;
        _noteController.clear();
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          'Đã lưu ảnh và chuyển minh chứng "${_selectedChallenge.title}" sang hàng đợi Admin duyệt!',
        ),
      ),
    );
  }

  String _formatReward(double amount) =>
      '${NumberFormat.decimalPattern('vi_VN').format(amount.round())} đ';

  @override
  Widget build(BuildContext context) {
    final result = _ocrResult;
    final stats = _storageStats;
    final suggestedChallenge = _findChallengeById(
      result?.analysisDetail?.suggestedChallengeId,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header tóm tắt bộ nhớ lưu trữ ảnh minh chứng & nút đồng bộ trạng thái duyệt
        Card(
          color: AppColors.primary.withValues(alpha: 0.08),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.sd_storage_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stats != null
                        ? 'Bộ nhớ ảnh cục bộ: ${stats.imageCount} tệp (${stats.formattedTotalSize})'
                        : 'Đang kiểm tra bộ nhớ lưu trữ ảnh...',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isProcessing ? null : _refreshSubmittedProofs,
                  icon: const Icon(Icons.sync, size: 20, color: AppColors.primary),
                  tooltip: 'Đồng bộ trạng thái Admin duyệt',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 1. Chọn thử thách & Thông tin thành viên nộp
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Thông tin thử thách & Người nộp',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ChallengeModel>(
                  key: ValueKey(_selectedChallenge.id),
                  initialValue: _selectedChallenge,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Thử thách thực hiện',
                    border: OutlineInputBorder(),
                  ),
                  items: _challenges.map((ch) {
                    return DropdownMenuItem<ChallengeModel>(
                      value: ch,
                      child: Text(
                        '${ch.title} (+${_formatReward(ch.rewardAmount)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (ch) {
                    if (ch != null) {
                      _reAnalyzeCurrentTextForChallenge(ch);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedChallenge.description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _memberNameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên thành viên',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Vị trí / Địa điểm check-in',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Chụp, Xem trước & Lưu trữ ảnh minh chứng vào bộ nhớ máy
        ProofImagePreviewCard(
          storedImage: _storedImage,
          locationLabel: _locationController.text,
          onRetakeCamera: _isProcessing
              ? null
              : () => _pickAndSaveImage(ImageSource.camera),
          onPickGallery: _isProcessing
              ? null
              : () => _pickAndSaveImage(ImageSource.gallery),
          onRemoveImage: _isProcessing ? null : _removeSelectedImage,
        ),
        const SizedBox(height: 16),

        // 3. Kịch bản mẫu thử nghiệm AI OCR
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '3. Kịch bản mẫu AI OCR (Hỗ trợ kiểm thử nhanh)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<MockOcrSample>(
                  key: ValueKey(_selectedSample.id),
                  initialValue: _selectedSample,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Chọn mẫu văn bản check-in',
                    border: OutlineInputBorder(),
                  ),
                  items: mockOcrSamples.map((sample) {
                    return DropdownMenuItem<MockOcrSample>(
                      value: sample,
                      child: Text(
                        '${sample.challengeTitle} (${sample.description})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (sample) {
                    if (sample != null) {
                      _runSampleOcr(sample);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Thẻ phân tích chuyên sâu AI OCR & Tự động điền ghi chú
        if (_isProcessing)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (result != null)
          OcrResultAnalysisCard(
            result: result,
            selectedChallengeId: _selectedChallenge.id,
            capturedAt: _capturedAt,
            suggestedChallengeTitle: suggestedChallenge?.title,
            onApplySuggestedChallenge: _applySuggestedChallenge,
            onAutoFillNote: _autoFillNoteFromOcr,
          ),
        const SizedBox(height: 16),

        // 5. Ghi chú & Nút Lưu / Gửi minh chứng
        TextField(
          controller: _noteController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Ghi chú minh chứng',
            hintText:
                'Nhập mô tả ngắn hoặc nhấn "Tự động điền vào ghi chú" từ AI OCR...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _isProcessing ? null : _submitProof,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text(
              'Lưu ảnh & Gửi minh chứng chờ duyệt',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 6. Danh sách minh chứng đã lưu trên máy
        SubmittedProofHistoryList(proofs: _submittedProofs),
      ],
    );
  }
}
