class Order {
  const Order({
    required this.id,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  /// `id`: a number or a string; stored as its string form.
  /// `total`: required number of paise. `status`: optional string,
  /// 'unknown' when missing. `created_at`: required ISO-8601 string.
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: (json['id'] as Object).toString(),
      total: (json['total'] as num).toInt(),
      status: json['status'] as String? ?? 'unknown',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;

  /// Total in paise.
  final int total;
  final String status;
  final DateTime createdAt;
}
