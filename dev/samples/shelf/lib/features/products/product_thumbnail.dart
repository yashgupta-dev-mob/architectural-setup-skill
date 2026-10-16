import 'package:flutter/material.dart';

/// A square product picture with a grey placeholder for a missing or
/// broken image.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({super.key, required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    const placeholderColor = Color(0xFF9E9E9E);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFFEEEEEE),
        child: url.isEmpty
            ? const Icon(Icons.image_outlined, color: placeholderColor)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: placeholderColor,
                ),
              ),
      ),
    );
  }
}
