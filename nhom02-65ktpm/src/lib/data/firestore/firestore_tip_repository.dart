import '../../domain/entities/tip.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/tip_repository.dart';
import 'firestore_converters.dart';
import 'firestore_paths.dart';

class FirestoreTipRepository implements TipRepository {
  FirestoreTipRepository(this._paths);

  final FirestorePaths _paths;

  @override
  Future<List<Tip>> fetchActiveTips() async {
    final snap = await _paths.tips().where('active', isEqualTo: true).get();
    return snap.docs.map((d) => _fromMap(d.id, d.data())).toList();
  }

  Tip _fromMap(String id, Map<String, dynamic> m) {
    final rawApplies = m['applies_to'] is Map ? m['applies_to'] as Map : const {};
    return Tip(
      code: (m['code'] as String?) ?? id,
      title: (m['title'] as String?) ?? '',
      content: (m['content'] as String?) ?? '',
      goals: FirestoreConverters.toStringList(m['goals'])
          .map((g) => tryParseWire(Goal.values, g))
          .whereType<Goal>()
          .toList(),
      appliesTo: {
        for (final entry in rawApplies.entries)
          entry.key.toString(): FirestoreConverters.toStringList(entry.value),
      },
      priority: FirestoreConverters.toInt(m['priority']),
      source: m['source'] as String?,
      active: m['active'] != false,
    );
  }
}
