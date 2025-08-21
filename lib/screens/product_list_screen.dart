import 'package:flutter/material.dart';
import 'package:showcase/screens/bluetooth_settings_screen.dart';
import 'package:showcase/screens/enhanced_kiosk_screen.dart';
import 'package:showcase/screens/kiosk_mode_settings_screen.dart';
import '../models/product.dart';
import '../services/hive_service.dart';
import '../services/auth_service.dart';
import 'add_product_page.dart';

class ProductListPage extends StatefulWidget {
  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<String> categories = [];
  Map<String, List<Product>> productsByCategory = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() {
      categories = HiveService.getCategories();
      productsByCategory = {};
      for (var category in categories) {
        productsByCategory[category] = HiveService.getProducts(
          category: category,
        );
      }
    });
  }

  void _editProduct(Product product) {
    TextEditingController nameController = TextEditingController(
      text: product.name,
    );
    TextEditingController priceController = TextEditingController(
      text: product.price.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Редактировать товар"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Название"),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: "Цена"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Отмена"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text("Сохранить"),
              onPressed: () {
                product.name = nameController.text;
                product.price = double.parse(priceController.text);
                HiveService.updateProduct(product);
                Navigator.pop(context);
                _loadProducts();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Все товары"),
        actions: [
          IconButton(
            icon: Icon(Icons.bluetooth),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BluetoothSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.display_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EnhancedKioskModeSettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pop(context);
            },
            // child: Text("Выйти", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: ListView(
        children:
            categories.map((category) {
              return ExpansionTile(
                title: Text(category),
                children:
                    productsByCategory[category]!.map((product) {
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text("${product.price} ₸"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editProduct(product),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                HiveService.deleteProduct(product);
                                _loadProducts();
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              );
            }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductPage()),
          );
          _loadProducts();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
