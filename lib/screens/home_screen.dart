import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../services/hive_service.dart';
import '../models/product.dart';
import '../widgets/auth_dialog.dart';
import '../screens/cart_screen.dart';
import '../widgets/product_tile.dart';
import '../services/cart_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text('Каталог товаров'),
        actions: [
          Consumer<CartService>(
            builder:
                (_, cart, child) => Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shopping_cart),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CartScreen()),
                        );
                      },
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: EdgeInsets.all(2.0),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => showAuthDialog(context),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Product>('products').listenable(),
        builder: (context, Box box, _) {
          // Получаем уникальные категории
          final categories = HiveService.getCategories();

          return CustomScrollView(
            slivers: [
              // Создаем список секций по категориям
              ...categories.map((category) {
                // Получаем продукты для каждой категории
                final products = HiveService.getProducts(category: category);

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Заголовок категории
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Сетка товаров для категории
                    products.isEmpty
                        ? Center(child: Text('Нет товаров в этой категории'))
                        : GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.55,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            return ProductTile(
                              product: products[index],
                              onTap: () {
                                final cartService = Provider.of<CartService>(
                                  context,
                                  listen: false,
                                );
                                cartService.addProduct(products[index]);
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
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
                            );
                          },
                        ),
                  ]),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
