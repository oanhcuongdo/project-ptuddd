import 'package:flutter_test/flutter_test.dart';
import 'package:src/models/match_journal.dart';

void main() {
  test('toJson/fromJson khớp cột match_journals', () {
    final journal = MatchJournal(
      userId: 'user-1',
      date: DateTime(2026, 11, 24),
      matchType: 'Buổi tập',
      rating: 4,
      goals: 2,
      assists: 1,
      reviewContent: 'Mất bóng ở cánh phải',
      imageUrl: 'https://example.com/a.jpg',
    );

    final map = journal.toJson();
    expect(map['user_id'], 'user-1');
    expect(map['date'], '2026-11-24');
    expect(map['match_type'], 'Buổi tập');
    expect(map['rating'], 4);
    expect(map['goals'], 2);
    expect(map['assists'], 1);
    expect(map['review_content'], 'Mất bóng ở cánh phải');
    expect(map['image_url'], 'https://example.com/a.jpg');
    expect(map.containsKey('id'), isFalse);

    final back = MatchJournal.fromJson({...map, 'id': 9});
    expect(back.id, 9);
    expect(back.dateIso, '2026-11-24');
    expect(back.rating, 4);
    expect(back.goals, 2);
  });
}
