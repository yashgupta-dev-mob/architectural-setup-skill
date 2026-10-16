class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.thumbnail,
    required this.inStock,
  });

  /// `id`: a number or a string; stored as its string form.
  /// `title`: required string. `price`: required number of paise.
  /// `thumbnail`: optional string, '' when missing.
  /// `in_stock`: optional bool, true when missing.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as Object).toString(),
      title: json['title'] as String,
      price: (json['price'] as num).toInt(),
      thumbnail: json['thumbnail'] as String? ?? '',
      inStock: json['in_stock'] as bool? ?? true,
    );
  }

  final String id;
  final String title;

  /// Price in paise.
  final int price;
  final String thumbnail;
  final bool inStock;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'thumbnail': thumbnail,
      'in_stock': inStock,
    };
  }
}
