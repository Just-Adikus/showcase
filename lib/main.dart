import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:showcase/screens/product_list_screen.dart';
import 'models/product.dart';
import 'services/hive_service.dart';
import 'services/cart_service.dart';
import 'screens/home_screen.dart';

void main() async {
  await Hive.initFlutter();

  // Регистрация адаптера Hive для Product
  Hive.registerAdapter(ProductAdapter());

  // Открытие бокса только один раз
  await Hive.openBox<Product>('products');

  // Инициализация сервиса Hive
  await HiveService.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartService(),
      child: MaterialApp(
        routes: {'/products': (context) => ProductListPage()},
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: HomeScreen(),
      ),
    );
  }
}
