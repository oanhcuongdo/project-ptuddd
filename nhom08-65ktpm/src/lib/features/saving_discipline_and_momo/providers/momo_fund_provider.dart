import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/momo_fund_config.dart';
import '../repository/saving_repository_impl.dart';

/// Realtime stream of [MoMoFundConfig] for a given [tripId].
final momoFundStreamProvider =
    StreamProvider.autoDispose.family<MoMoFundConfig?, String>((ref, tripId) {
  final repository = ref.watch(savingRepositoryProvider);
  return repository.watchFundConfig(tripId);
});

/// State notifier for creating/updating [MoMoFundConfig] for a given [tripId].
final momoFundProvider =
    AsyncNotifierProvider.autoDispose.family<MoMoFundNotifier, MoMoFundConfig?, String>(
  MoMoFundNotifier.new,
);

class MoMoFundNotifier extends AsyncNotifier<MoMoFundConfig?> {
  final String _tripId;

  MoMoFundNotifier(this._tripId);

  @override
  Future<MoMoFundConfig?> build() async {
    final repository = ref.watch(savingRepositoryProvider);
    return await repository.getFundConfig(_tripId);
  }

  /// Saves or updates the host's MoMo Group Fund configuration.
  Future<MoMoFundConfig> saveFundConfig({
    required String fundName,
    required String hostUserId,
    required String hostName,
    required String momoPhoneNumber,
    String? momoFundDeeplink,
    String? qrCodeUrl,
    required double targetTotalAmount,
  }) async {
    final keepAliveLink = ref.keepAlive();
    try {
      final repository = ref.read(savingRepositoryProvider);
      final existing = state.value;
      state = const AsyncLoading();

      final result = await AsyncValue.guard(() async {
        final config = MoMoFundConfig(
          tripId: _tripId,
          fundName: fundName.trim(),
          hostUserId: hostUserId,
          hostName: hostName,
          momoPhoneNumber: momoPhoneNumber.trim(),
          momoFundDeeplink: momoFundDeeplink?.trim().isEmpty == true
              ? null
              : momoFundDeeplink?.trim(),
          qrCodeUrl: qrCodeUrl?.trim().isEmpty == true ? null : qrCodeUrl?.trim(),
          targetTotalAmount: targetTotalAmount,
          currentCollectedAmount: existing?.currentCollectedAmount ?? 0.0,
          currency: existing?.currency ?? 'VND',
          updatedAt: DateTime.now(),
        );

        await repository.saveFundConfig(config);
        return config;
      });

      if (!ref.mounted) {
        if (result.hasError) {
          Error.throwWithStackTrace(result.error!, result.stackTrace!);
        }
        return result.requireValue;
      }

      state = result;
      if (state.hasError) {
        Error.throwWithStackTrace(state.error!, state.stackTrace!);
      }
      return state.requireValue!;
    } finally {
      keepAliveLink.close();
    }
  }
}
