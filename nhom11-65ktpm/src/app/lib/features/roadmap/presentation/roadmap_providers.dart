import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/contracts.dart';

final roadmapProvider = FutureProvider<PathMap>(
  (ref) => ref.watch(pathRepositoryProvider).loadPath(),
);