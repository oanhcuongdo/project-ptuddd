import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/trip_member.dart';
import '../../../models/trip_model.dart';
import '../models/momo_fund_config.dart';
import '../models/saving_plan.dart';
import '../repository/saving_repository_impl.dart';

/// Realtime stream of [TripModel] metadata for a given [tripId].
final tripSummaryStreamProvider =
    StreamProvider.autoDispose.family<TripModel?, String>((ref, tripId) {
  final repository = ref.watch(savingRepositoryProvider);
  return repository.watchTripSummary(tripId);
});

/// Realtime stream of [TripMember]s for a given [tripId].
final tripMembersStreamProvider =
    StreamProvider.autoDispose.family<List<TripMember>, String>((ref, tripId) {
  final repository = ref.watch(savingRepositoryProvider);
  return repository.watchTripMembers(tripId);
});

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
    SavingFrequency? defaultFrequency,
    double? suggestedPerMemberAmount,
  }) async {
    final keepAliveLink = ref.keepAlive();
    try {
      final repository = ref.read(savingRepositoryProvider);
      final existing = state.value ?? await repository.getFundConfig(_tripId);
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
          defaultFrequency: defaultFrequency ??
              existing?.defaultFrequency ??
              SavingFrequency.weekly,
          suggestedPerMemberAmount:
              suggestedPerMemberAmount ?? existing?.suggestedPerMemberAmount,
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
