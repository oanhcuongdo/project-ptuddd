import '../../models/shop.dart';

/// Tiêu chí sắp xếp danh sách tiệm hiển thị (UC-03).
enum ShopSort { nearest, highestRated }

/// Lọc danh sách tiệm theo tên tiệm, địa chỉ hoặc tên chủ tiệm (UC-03).
List<Shop> filterShops(List<Shop> shops, String query) {
  final normalized = query.toLowerCase().trim();
  if (normalized.isEmpty) return shops;
  return shops.where((s) {
    final owner = s.ownerName?.toLowerCase() ?? '';
    return s.name.toLowerCase().contains(normalized) ||
        s.address.toLowerCase().contains(normalized) ||
        owner.contains(normalized);
  }).toList();
}

/// Sắp xếp danh sách tiệm theo khoảng cách gần nhất hoặc điểm đánh giá cao nhất.
List<Shop> sortShops(List<Shop> shops, ShopSort sort) {
  final copy = List<Shop>.of(shops);
  switch (sort) {
    case ShopSort.nearest:
      copy.sort(
        (a, b) => (a.distanceM ?? double.infinity)
            .compareTo(b.distanceM ?? double.infinity),
      );
    case ShopSort.highestRated:
      copy.sort((a, b) {
        final byRating = b.rating.compareTo(a.rating);
        if (byRating != 0) return byRating;
        final byReviews = b.reviewCount.compareTo(a.reviewCount);
        if (byReviews != 0) return byReviews;
        return (a.distanceM ?? double.infinity)
            .compareTo(b.distanceM ?? double.infinity);
      });
  }
  return copy;
}
