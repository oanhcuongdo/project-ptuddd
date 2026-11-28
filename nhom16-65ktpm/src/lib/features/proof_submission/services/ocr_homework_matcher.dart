/// Kết quả phân tích nội dung chữ trên bài làm / ảnh check-in theo loại thử thách (Sprint 3 - Giai đoạn 3).
class HomeworkMatchResult {
  const HomeworkMatchResult({
    this.suggestedChallengeId,
    this.suggestedCategory,
    this.matchedKeywords = const [],
    this.homeworkMetrics = const {},
    this.contentScore = 0,
    this.isTargetChallengeMatched = false,
  });

  /// Mã thử thách có mức độ khớp từ khóa cao nhất (vd: 'ch_01', 'ch_02', 'ch_03', 'ch_04').
  final String? suggestedChallengeId;

  /// Danh mục thử thách tương ứng ('Kỷ luật', 'Gia sư', 'Học tập', 'Sức khỏe').
  final String? suggestedCategory;

  /// Các từ khóa trên bài làm phát hiện được trong văn bản OCR.
  final List<String> matchedKeywords;

  /// Các chỉ số định lượng bóc tách được từ chữ trên bài làm (số bài tập, số km, sĩ số...).
  final Map<String, String> homeworkMetrics;

  /// Điểm đánh giá nội dung chữ trên bài làm (thang điểm 0 - 60, kết hợp với điểm thời gian 0 - 40).
  final int contentScore;

  /// Đánh dấu nội dung bài làm có khớp với thử thách người dùng đang chọn hay không.
  final bool isTargetChallengeMatched;
}

/// Thuật toán nhận diện chữ trên bài làm và chấm điểm mức độ khớp với thử thách (Sprint 3 - Giai đoạn 3).
class OcrHomeworkMatcher {
  const OcrHomeworkMatcher();

  static const Map<String, String> _challengeCategories = {
    'ch_01': 'Kỷ luật',
    'ch_02': 'Gia sư',
    'ch_03': 'Học tập',
    'ch_04': 'Sức khỏe',
  };

  static const Map<String, List<String>> _keywordsByChallenge = {
    'ch_01': [
      'dậy sớm',
      'bàn học',
      'ôn tập',
      'giáo trình',
      'đọc tài liệu',
      'buổi sáng',
      'báo thức',
      'almw',
      'học bài',
    ],
    'ch_02': [
      'gia sư',
      'lớp học',
      'tình thương',
      'bài giảng',
      'học sinh',
      'sĩ số',
      'phân số',
      'dạy học',
      'dạy kèm',
    ],
    'ch_03': [
      'toán',
      'lập trình',
      'thuật toán',
      'leetcode',
      'hackerrank',
      'quy hoạch động',
      'cấu trúc dữ liệu',
      'test cases',
      'bài tập',
      'passed',
      'flutter',
    ],
    'ch_04': [
      'strava',
      'running',
      'chạy bộ',
      'distance',
      'pace',
      'km',
      'thể thao',
      'activity',
    ],
  };

  static final RegExp _exerciseCountPattern = RegExp(
    r'(\d+)\s*(?:bài tập|bài toán|test cases)',
    caseSensitive: false,
  );

  static final RegExp _studentCountPattern = RegExp(
    r'(?:sĩ số[:\s]*(\d+)\s*(?:học sinh|em)?|(\d+)\s*học sinh)',
    caseSensitive: false,
  );

  static final RegExp _distanceKmPattern = RegExp(
    r'(\d+(?:[\.,]\d+)?)\s*km\b',
    caseSensitive: false,
  );

  /// Phân tích chữ trên bài làm [rawText] và đối chiếu với [targetChallengeId] (nếu có).
  HomeworkMatchResult matchHomeworkContent(
    String rawText, {
    String? targetChallengeId,
  }) {
    final normalized = rawText.trim();
    if (normalized.isEmpty) {
      return const HomeworkMatchResult();
    }

    final lower = normalized.toLowerCase();
    final allMatchedKeywords = <String>{};
    final matchCountByChallenge = <String, int>{};

    for (final entry in _keywordsByChallenge.entries) {
      var count = 0;
      for (final kw in entry.value) {
        if (lower.contains(kw)) {
          count++;
          allMatchedKeywords.add(kw);
        }
      }
      if (count > 0) {
        matchCountByChallenge[entry.key] = count;
      }
    }

    String? bestChallengeId;
    var bestCount = 0;
    for (final entry in matchCountByChallenge.entries) {
      if (entry.value > bestCount) {
        bestCount = entry.value;
        bestChallengeId = entry.key;
      }
    }

    final metrics = _extractHomeworkMetrics(normalized);

    final bool isMatched;
    if (targetChallengeId == null || targetChallengeId.isEmpty) {
      isMatched = bestChallengeId != null;
    } else {
      isMatched =
          (matchCountByChallenge[targetChallengeId] ?? 0) > 0 ||
          bestChallengeId == targetChallengeId;
    }

    // Tính điểm nội dung bài làm (tối đa 60 điểm):
    // - Mỗi từ khóa khớp: +15 điểm (tối đa 45 điểm)
    // - Có chỉ số định lượng trên bài làm (số bài, km, sĩ số): +15 điểm
    var score = (allMatchedKeywords.length * 15).clamp(0, 45);
    if (metrics.isNotEmpty) {
      score += 15;
    }
    if (targetChallengeId != null &&
        targetChallengeId.isNotEmpty &&
        !isMatched &&
        score > 20) {
      score = 20;
    }

    return HomeworkMatchResult(
      suggestedChallengeId: bestChallengeId,
      suggestedCategory: bestChallengeId != null
          ? _challengeCategories[bestChallengeId]
          : null,
      matchedKeywords: allMatchedKeywords.toList(),
      homeworkMetrics: metrics,
      contentScore: score.clamp(0, 60),
      isTargetChallengeMatched: isMatched,
    );
  }

  Map<String, String> _extractHomeworkMetrics(String text) {
    final metrics = <String, String>{};

    final exerciseMatch = _exerciseCountPattern.firstMatch(text);
    if (exerciseMatch != null) {
      metrics['so_bai_hoan_thanh'] = '${exerciseMatch.group(1)} bài';
    }

    final studentMatch = _studentCountPattern.firstMatch(text);
    if (studentMatch != null) {
      final count = studentMatch.group(1) ?? studentMatch.group(2);
      if (count != null) {
        metrics['si_so_lop'] = '$count học sinh';
      }
    }

    final distanceMatch = _distanceKmPattern.firstMatch(text);
    if (distanceMatch != null) {
      final kmValue = distanceMatch.group(1)!.replaceAll(',', '.');
      metrics['quang_duong'] = '$kmValue km';
    }

    return metrics;
  }
}
