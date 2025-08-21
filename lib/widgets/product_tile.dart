import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../screens/cart_screen.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductTile({Key? key, required this.product, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final inCart = cartService.items.any(
      (item) => item.product.name == product.name,
    );
    final quantity =
        inCart
            ? cartService.items
                .firstWhere((item) => item.product.name == product.name)
                .quantity
            : 0;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Расчет высоты с учетом доступного пространства
              double availableHeight = constraints.maxHeight - 60;
              double imageHeight =
                  availableHeight > 0 ? availableHeight * 0.85 : 60;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Изображение с гибкой высотой
                  Stack(
                    children: [
                      Container(
                        constraints: BoxConstraints(maxHeight: imageHeight),
                        width: double.infinity,
                        child: loadImage(product.imageUrl, fit: BoxFit.contain),
                      ),
                      // Бейдж с количеством товаров в корзине
                      if (inCart)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              '$quantity',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  // Имя продукта с ограничением на одну строку
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  // Цена
                  Text(
                    "${product.price} ₸",
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 4),
                  // Кнопка добавления в корзину
                  InkWell(
                    onTap: () {
                      cartService.addProduct(product);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Товар добавлен в корзину'),
                          duration: Duration(seconds: 1),
                          action: SnackBarAction(
                            label: 'К КОРЗИНЕ',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CartScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_shopping_cart,
                            size: 14,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'В корзину',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

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
}
