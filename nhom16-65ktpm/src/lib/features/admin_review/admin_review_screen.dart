import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/proof_model.dart';
import '../../data/repositories/fund_repository.dart';
import 'widgets/proof_card.dart';

// Màn hình Kiểm duyệt minh chứng (Admin).
// Giai đoạn 2: giao diện + tương tác bằng dữ liệu mẫu (đã merge PR #14).
// Giai đoạn 3 – C1: nối dữ liệu thật — danh sách chờ duyệt đọc từ
// FundRepository.getPendingProofs() (SQLite) thay cho dữ liệu mẫu.
// C2: nút Duyệt gọi FundRepository.approveProof() — duyệt xong minh
// chứng rời danh sách chờ; giao dịch thu vào quỹ do tầng dữ liệu tự
// sinh.
// C3: SnackBar xác nhận sau khi duyệt; nếu approveProof trả về
// false (minh chứng đã bị xử lý trước đó) thì báo và tải lại danh sách.
// C4: nút Từ chối gọi FundRepository.rejectProof(id, reason:) — lý do
// lưu vào adminFeedback (ProofModel không có trường rejectReason),
// trạng thái chuyển rejected; không cộng quỹ. Hộp thoại lý do giữ
// nguyên từ Giai đoạn 2 (bắt buộc nhập).
// C5: chặn thao tác trùng — _processingIds giữ id đang duyệt/từ chối,
// bấm trùng trong lúc chờ thì bỏ qua, không gọi repository lần 2.
// C6: rà soát cuối Giai đoạn 3 — dispose controller hộp thoại lý do,
// kiểm chứng toàn trình duyệt/từ chối + đọc lại được lý do đã lưu.
class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final FundRepository _repo = FundRepository.instance;

  List<ProofModel> _pending = [];
  bool _loading = true;

  // Id các minh chứng đang chờ approve/reject trả về — chặn bấm trùng.
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    try {
      final proofs = await _repo.getPendingProofs();
      proofs.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
      if (!mounted) return;
      setState(() {
        _pending = proofs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được danh sách minh chứng: $e')),
      );
    }
  }

  Future<void> _approve(ProofModel proof) async {
    if (_processingIds.contains(proof.id)) return;
    _processingIds.add(proof.id);
    final ok = await _repo.approveProof(proof.id);
    _processingIds.remove(proof.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _pending.removeWhere((p) => p.id == proof.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã duyệt minh chứng của ${proof.memberName} — '
            'cộng ${_money(proof.rewardAmount)} vào quỹ',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minh chứng này đã được xử lý trước đó.')),
      );
      _loadPending();
    }
  }

  Future<void> _reject(ProofModel proof) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối minh chứng'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối (bắt buộc)',
            hintText: 'vd: Ảnh mờ, không đọc được giờ',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
            child: const Text('Xác nhận từ chối'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || reason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần nhập lý do mới từ chối được.')),
      );
      return;
    }
    if (_processingIds.contains(proof.id)) return;
    _processingIds.add(proof.id);
    final ok = await _repo.rejectProof(proof.id, reason: reason);
    _processingIds.remove(proof.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _pending.removeWhere((p) => p.id == proof.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã từ chối minh chứng của ${proof.memberName} — lý do: $reason',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minh chứng này đã được xử lý trước đó.')),
      );
      _loadPending();
    }
  }

  String _time(DateTime d) => DateFormat('dd/MM HH:mm').format(d);

  String _money(double v) =>
      '${NumberFormat.decimalPattern('vi_VN').format(v.round())} đ';

  double get _pendingTotal =>
      _pending.fold(0, (sum, p) => sum + p.rewardAmount);

  void _showDetail(ProofModel proof) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(proof.challengeTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 48),
              ),
              const SizedBox(height: 12),
              Text('Thành viên: ${proof.memberName}'),
              Text('Nộp lúc: ${_time(proof.submittedAt)}'),
              Text('Tiền tài trợ: ${_money(proof.rewardAmount)}'),
              const SizedBox(height: 8),
              Text('Ghi chú: ${proof.note}'),
              const SizedBox(height: 8),
              Chip(label: Text('OCR gợi ý: ${proof.ocrExtractedText}')),
              Text('Giờ OCR đọc được: ${proof.detectedTime ?? '—'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reject(proof);
            },
            child: const Text('Từ chối'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _approve(proof);
            },
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm duyệt minh chứng')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pending.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Không còn minh chứng chờ duyệt.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text('Tất cả minh chứng đã được xử lý. Làm tốt lắm!'),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đang chờ duyệt: ${_pending.length} minh chứng',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng tiền tài trợ đang chờ: '
                        '${_money(_pendingTotal)}',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _pending.length,
                    itemBuilder: (ctx, i) {
                      final proof = _pending[i];
                      return ProofCard(
                        proof: proof,
                        timeText: _time(proof.submittedAt),
                        onTap: () => _showDetail(proof),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
