import 'place_plan.dart';

class PlaceSuggestion {
  final String id;
  final String name;
  final PlaceCategory category;
  final String address;
  final double latitude;
  final double longitude;
  final int defaultDurationMinutes;
  final double estimatedTicketCost;
  final double estimatedFoodCost;
  final double rating;

  const PlaceSuggestion({
    required this.id,
    required this.name,
    required this.category,
    this.address = '',
    required this.latitude,
    required this.longitude,
    this.defaultDurationMinutes = 60,
    this.estimatedTicketCost = 0,
    this.estimatedFoodCost = 0,
    this.rating = 0,
  });
}
