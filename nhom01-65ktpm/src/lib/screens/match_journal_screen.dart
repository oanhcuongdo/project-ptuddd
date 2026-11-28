import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/match_journal.dart';
import '../services/auth_service.dart';
import '../services/match_journal_service.dart';

/// Nhật ký trận đấu & buổi tập — Hà Văn Phong.
/// Ghi phong độ 1–5 sao, bàn thắng, kiến tạo, nhận xét, ảnh sân.
class MatchJournalScreen extends StatefulWidget {
  const MatchJournalScreen({super.key});

  @override
  State<MatchJournalScreen> createState() => _MatchJournalScreenState();
}

class _MatchJournalScreenState extends State<MatchJournalScreen> {
  final _auth = AuthService();
  final _service = MatchJournalService();

  List<MatchJournal> _items = [];
  bool _loading = true;
  String? _error;

  String _filterType = 'Tất cả'; // Tất cả, Trận đấu, Buổi tập
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();

  static const List<String> _tabs = ['Tất cả', 'Trận đấu', 'Buổi tập'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Chưa đăng nhập';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.listMine(user.id);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([MatchJournal? existing]) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại!')),
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _JournalForm(existing: existing, service: _service, userId: user.id),
    );
    if (saved == true) _load();
  }

  Future<void> _remove(MatchJournal item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162032),
        title: const Text('Xóa nhật ký?', style: TextStyle(color: Colors.white)),
        content: Text(
          '${item.matchType} ngày ${item.dateLabel}',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true || item.id == null) return;
    try {
      await _service.delete(item.id!);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán thống kê tổng hợp cá nhân
    final totalMatches = _items.length;
    final totalGoals = _items.fold(0, (sum, item) => sum + item.goals);
    final totalAssists = _items.fold(0, (sum, item) => sum + item.assists);
    final avgRating = totalMatches == 0
        ? 0.0
        : _items.fold(0.0, (sum, item) => sum + item.rating) / totalMatches;

    // Lọc theo loại và từ khóa tìm kiếm
    final filteredItems = _items.where((item) {
      if (_filterType != 'Tất cả' && item.matchType != _filterType) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchReview = (item.reviewContent ?? '').toLowerCase().contains(q);
        final matchType = item.matchType.toLowerCase().contains(q);
        final matchDate = item.dateLabel.contains(q);
        return matchReview || matchType || matchDate;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131C2E),
        title: const Text('NHẬT KÝ TRẬN ĐẤU & HIỆU SUẤT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.black,
        onPressed: _auth.currentUser == null ? null : () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('GHI NHẬT KÝ', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFEF4444))),
                  ),
                )
              : Column(
                  children: [
                    // 1. Header Thống kê hiệu suất cá nhân
                    Container(
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF131D2E), Color(0xFF18243A)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF283856)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Tổng số', '$totalMatches', Icons.sports_soccer, const Color(0xFF38BDF8)),
                          _buildStatItem('Bàn thắng', '$totalGoals', Icons.sports, const Color(0xFF10B981)),
                          _buildStatItem('Kiến tạo', '$totalAssists', Icons.trending_up, const Color(0xFFF59E0B)),
                          _buildStatItem('Sao TB', avgRating.toStringAsFixed(1), Icons.star, const Color(0xFFF59E0B)),
                        ],
                      ),
                    ),

                    // 2. Thanh tìm kiếm và Bộ lọc
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm nhận xét, ngày, loại...',
                              hintStyle: const TextStyle(color: Color(0xFF64748B)),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFF131D2E),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF283856))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF283856))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildFilterChip('Tất cả'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Trận đấu'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Buổi tập'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3. PageView với hiệu ứng trượt mượt mà giữa các tab lọc
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _filterType = _tabs[index];
                          });
                        },
                        children: [
                          _buildJournalListView(_items), // Tất cả
                          _buildJournalListView(_items.where((i) => i.matchType == 'Trận đấu').toList()), // Trận đấu
                          _buildJournalListView(_items.where((i) => i.matchType == 'Buổi tập').toList()), // Buổi tập
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _filterType == label;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _filterType = label;
          });
          final index = _tabs.indexOf(label);
          if (index != -1) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF10B981) : const Color(0xFF131D2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? const Color(0xFF10B981) : const Color(0xFF283856)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : const Color(0xFF94A3B8),
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJournalListView(List<MatchJournal> sourceItems) {
    final list = sourceItems.where((item) {
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchReview = (item.reviewContent ?? '').toLowerCase().contains(q);
        final matchType = item.matchType.toLowerCase().contains(q);
        final matchDate = item.dateLabel.contains(q);
        return matchReview || matchType || matchDate;
      }
      return true;
    }).toList();

    if (list.isEmpty) {
      return Center(
        child: Text(
          _items.isEmpty
              ? 'Chưa có nhật ký.\nGhi lại phong độ sau trận hoặc buổi tập.'
              : 'Không tìm thấy nhật ký phù hợp.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 88),
        itemCount: list.length,
        itemBuilder: (_, i) => _card(list[i]),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => const Text(
                    'Không thể tải ảnh',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(MatchJournal j) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131D2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF283856)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openForm(j),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (j.imageUrl != null && j.imageUrl!.startsWith('http'))
                GestureDetector(
                  onTap: () => _showFullScreenImage(j.imageUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      j.imageUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => _thumbPlaceholder(),
                    ),
                  ),
                )
              else
                _thumbPlaceholder(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${j.matchType} • ${j.dateLabel}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'★' * j.rating}${'☆' * (5 - j.rating)}   ${j.goals} bàn • ${j.assists} kiến tạo',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 13),
                    ),
                    if ((j.reviewContent ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        j.reviewContent!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _remove(j),
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.stadium, color: Color(0xFF10B981)),
    );
  }
}

class _JournalForm extends StatefulWidget {
  final MatchJournal? existing;
  final MatchJournalService service;
  final String userId;

  const _JournalForm({required this.existing, required this.service, required this.userId});

  @override
  State<_JournalForm> createState() => _JournalFormState();
}

class _JournalFormState extends State<_JournalForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late String _type;
  late int _rating;
  late final TextEditingController _goals;
  late final TextEditingController _assists;
  late final TextEditingController _review;
  String? _imageUrl;
  XFile? _picked;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? DateTime.now();
    _type = e?.matchType ?? 'Trận đấu';
    _rating = e?.rating ?? 3;
    _goals = TextEditingController(text: '${e?.goals ?? 0}');
    _assists = TextEditingController(text: '${e?.assists ?? 0}');
    _review = TextEditingController(text: e?.reviewContent ?? '');
    _imageUrl = e?.imageUrl;
  }

  @override
  void dispose() {
    _goals.dispose();
    _assists.dispose();
    _review.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 75,
      );
      if (file != null) {
        setState(() {
          _picked = file;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở máy ảnh/thư viện: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _adjustCounter(TextEditingController controller, int delta) {
    final current = int.tryParse(controller.text.trim()) ?? 0;
    final next = current + delta;
    if (next < 0) return;
    controller.text = '$next';
    _formKey.currentState?.validate();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại thông tin số bàn thắng và kiến tạo!'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final goals = int.tryParse(_goals.text.trim()) ?? 0;
    final assists = int.tryParse(_assists.text.trim()) ?? 0;

    setState(() => _saving = true);
    try {
      var url = _imageUrl;
      if (_picked != null) {
        final bytes = await _picked!.readAsBytes();
        final ext = _picked!.name.contains('.') ? _picked!.name.split('.').last : 'jpg';
        url = await widget.service.uploadPhoto(
          userId: widget.userId,
          bytes: bytes,
          fileExtension: ext,
        );
      }
      await widget.service.save(MatchJournal(
        id: widget.existing?.id,
        userId: widget.userId,
        date: DateTime(_date.year, _date.month, _date.day),
        matchType: _type,
        rating: _rating,
        goals: goals,
        assists: assists,
        reviewContent: _review.text.trim().isEmpty ? null : _review.text.trim(),
        imageUrl: url,
      ));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GHI NHẬT KÝ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text(
                'Hôm nay xử lý bóng tốt pha nào? Pha nào bị mất bóng cần sửa?',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final t in MatchJournal.types) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Center(child: Text(t)),
                          selected: _type == t,
                          selectedColor: const Color(0xFF10B981),
                          onSelected: (_) => setState(() => _type = t),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFF38BDF8)),
                onTap: _pickDate,
              ),
              const Text('Phong độ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              Row(
                children: List.generate(5, (i) {
                  final n = i + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = n),
                    icon: Icon(n <= _rating ? Icons.star : Icons.star_border, color: const Color(0xFFF59E0B)),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCounterField(_goals, 'Bàn thắng')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCounterField(_assists, 'Kiến tạo')),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _review,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nhận xét sau trận',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  hintText: 'Xử lý bóng, chuyền, sút, tranh chấp...',
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  filled: true,
                  fillColor: const Color(0xFF0B111E),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF233352))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF233352))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Chọn ảnh'),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Chụp'),
                  ),
                  Expanded(
                    child: Text(
                      _picked?.name ?? (_imageUrl == null ? 'Chưa có ảnh' : 'Đã có ảnh'),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.black),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Đang lưu...' : 'LƯU NHẬT KÝ', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B111E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF233352)),
          ),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                icon: const Icon(Icons.remove, size: 18, color: Color(0xFF94A3B8)),
                onPressed: () => _adjustCounter(controller, -1),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nhập số';
                    }
                    final n = int.tryParse(val.trim());
                    if (n == null || n < 0) {
                      return 'Cần số ≥ 0';
                    }
                    return null;
                  },
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    errorStyle: TextStyle(fontSize: 10, color: Color(0xFFEF4444)),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                icon: const Icon(Icons.add, size: 18, color: Color(0xFF10B981)),
                onPressed: () => _adjustCounter(controller, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
