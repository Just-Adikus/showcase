import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import 'pay_screen.dart';

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Корзина'),
        actions: [
          if (cartService.items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                cartService.clearCart();
              },
            ),
        ],
      ),
      body:
          cartService.items.isEmpty
              ? Center(child: Text('Ваша корзина пуста'))
              : ListView.builder(
                itemCount: cartService.items.length,
                itemBuilder:
                    (ctx, i) => Card(
                      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: ListTile(
                          leading: loadImage(
                            cartService.items[i].product.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(cartService.items[i].product.name),
                          subtitle: Text(
                            'Итого: ${(cartService.items[i].product.price * cartService.items[i].quantity).toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  cartService.removeProduct(
                                    cartService.items[i].product,
                                  );
                                },
                              ),
                              Text('${cartService.items[i].quantity}'),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  cartService.addProduct(
                                    cartService.items[i].product,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ),
      bottomNavigationBar:
          cartService.items.isEmpty
              ? null
              : BottomAppBar(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Итого: ${cartService.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        // style: ElevatedButton.styleFrom(
                        //   backgroundColor: Colors.white,
                        //   foregroundColor: Colors.black,
                        //   padding: EdgeInsets.symmetric(
                        //     horizontal: 30,
                        //     vertical: 30,
                        //   ),
                        // ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MultiProductPayScreen(
                                    cartItems: cartService.items,
                                    totalAmount: cartService.totalAmount,
                                  ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              cartService.clearCart();
                            }
                          });
                        },
                        child: Text(
                          'Оплатить',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
