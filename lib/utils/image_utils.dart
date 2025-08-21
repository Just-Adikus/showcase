import 'dart:io';
import 'package:flutter/material.dart';

Widget loadImage(
  String? imagePath, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (imagePath == null || imagePath.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey,
      child: Icon(Icons.image_not_supported, size: 40),
    );
  }

  // Сетевой URL
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return Image.network(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        print('Network image error: $error');
        return Container(
          width: width,
          height: height,
          color: Colors.grey,
          child: Icon(Icons.image_not_supported, size: 40),
        );
      },
    );
  }

  // Локальный файл
  String filePath =
      imagePath.startsWith('file://')
          ? imagePath.replaceFirst('file://', '')
          : imagePath;
  File imageFile = File(filePath);
  if (imageFile.existsSync()) {
    return Image.file(
      imageFile,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        print('File image error: $error');
        return Container(
          width: width,
          height: height,
          color: Colors.grey,
          child: Icon(Icons.image_not_supported, size: 40),
        );
      },
    );
  }

  // Активы
  if (imagePath.startsWith('assets/')) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        print('Asset image error: $error');
        return Container(
          width: width,
          height: height,
          color: Colors.grey,
          child: Icon(Icons.image_not_supported, size: 40),
        );
      },
    );
  }

  // Заглушка, если изображение не найдено
  print('Image not found: $imagePath');
  return Container(
    width: width,
    height: height,
    color: Colors.grey,
    child: Icon(Icons.image_not_supported, size: 40),
  );
}
