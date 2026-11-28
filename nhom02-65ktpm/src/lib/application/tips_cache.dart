import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/entities/tip.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/tip_repository.dart';

/// Bộ nhớ đệm thư viện gợi ý (tải một lần sau khi đăng nhập).
///
/// Danh sách mã gợi ý trong JSON schema của AI được tạo ĐỘNG từ cache này,
/// không hard-code trong code.
class TipsCache extends ChangeNotifier {
  TipsCache(this._repository, AuthRepository auth) {
    // Tự tải khi có người đăng nhập (đọc tips yêu cầu đã đăng nhập).
    _authSub = auth.authStateChanges().listen((user) {
      if (user != null) {
        unawaited(ensureLoaded());
      } else {
        _clear();
      }
    });
  }

  final TipRepository _repository;
  StreamSubscription<AuthUser?>? _authSub;
  Future<void>? _loading;

  List<Tip> _tips = const [];
  Map<String, Tip> _byCode = const {};

  List<Tip> get tips => _tips;
  Map<String, Tip> get byCode => _byCode;
  bool get isEmpty => _tips.isEmpty;

  /// Đảm bảo đã tải; gọi nhiều lần cũng chỉ tải một lần.
  Future<void> ensureLoaded() => _loading ??= _load();

  /// Tải lại (ví dụ sau khi vừa nạp tips mới).
  Future<void> refresh() {
    _loading = _load();
    return _loading!;
  }

  Future<void> _load() async {
    try {
      final tips = await _repository.fetchActiveTips();
      _tips = List.unmodifiable(tips);
      _byCode = Map.unmodifiable({for (final t in tips) t.code: t});
      notifyListeners();
    } catch (e) {
      debugPrint('Load tips failed: $e');
      _loading = null; // cho phép thử lại lần sau
    }
  }

  void _clear() {
    _loading = null;
    _tips = const [];
    _byCode = const {};
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
