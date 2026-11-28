import '../models/place_plan.dart';

List<String> findConflictingPlanIds(Iterable<PlacePlan> plans) {
  final ordered = plans.toList();
  final ids = <String>{};
  for (var i = 0; i < ordered.length; i++) {
    for (var j = i + 1; j < ordered.length; j++) {
      final a = ordered[i];
      final b = ordered[j];
      if (a.startTime.isBefore(b.endTime) && b.startTime.isBefore(a.endTime)) {
        ids
          ..add(a.id)
          ..add(b.id);
      }
    }
  }
  return ids.toList();
}

double totalTicketCost(Iterable<PlacePlan> plans) =>
    plans.fold(0, (sum, p) => sum + p.ticketCost);
double totalFoodCost(Iterable<PlacePlan> plans) =>
    plans.fold(0, (sum, p) => sum + p.foodCost);
double totalCost(Iterable<PlacePlan> plans) =>
    plans.fold(0, (sum, p) => sum + p.totalEstimatedCost);

String formatTime(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String formatVnd(num amount) {
  final text = amount.round().toString();
  final grouped = text.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '$grouped đ';
}
