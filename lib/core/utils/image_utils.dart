import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageUtils {
  static ImageProvider? getImageProvider(String imageSource) {
    if (imageSource.isEmpty) return null;
    if (imageSource.startsWith('data:image') || !imageSource.startsWith('http')) {
      try {
        final base64Str = imageSource.contains('base64,')
            ? imageSource.split('base64,')[1]
            : imageSource;
        final bytes = base64Decode(base64Str.trim());
        return MemoryImage(bytes);
      } catch (e) {
        print('Error decoding base64 image provider: $e');
        return null;
      }
    } else {
      return CachedNetworkImageProvider(imageSource);
    }
  }

  static Widget buildImage(
    String imageSource, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imageSource.isEmpty) {
      return errorWidget ?? const Icon(Icons.broken_image);
    }
    if (imageSource.startsWith('data:image') || !imageSource.startsWith('http')) {
      try {
        final base64Str = imageSource.contains('base64,')
            ? imageSource.split('base64,')[1]
            : imageSource;
        final bytes = base64Decode(base64Str.trim());
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? const Icon(Icons.broken_image),
        );
      } catch (e) {
        print('Error building base64 image: $e');
        return errorWidget ?? const Icon(Icons.broken_image);
      }
    } else {
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: fit,
        width: width,
        height: height,
        placeholder: placeholder != null ? (context, url) => placeholder : null,
        errorWidget: errorWidget != null ? (context, url, error) => errorWidget : null,
      );
    }
  }
}
