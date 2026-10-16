/// One product line in an analytics event.
class AnalyticsItem {
  const AnalyticsItem({
    required this.sku,
    required this.quantity,
    required this.price,
    this.name,
    this.category,
  });

  final String sku;
  final num quantity;

  /// The price of one unit, in rupees.
  final num price;
  final String? name;
  final String? category;
}
