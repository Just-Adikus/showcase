import 'package:hive/hive.dart';
import '../models/product.dart';

class HiveService {
  static const String _productsBoxName = 'products';

  static Future<void> init() async {
    await Hive.openBox<Product>(_productsBoxName);
  }

  static Future<void> addProduct(Product product) async {
    final box = Hive.box<Product>(_productsBoxName);
    await box.add(product);
  }

  static List<Product> getProducts({String? category}) {
    final box = Hive.box<Product>(_productsBoxName);
    if (category == null) {
      return box.values.toList();
    }
    return box.values.where((product) => product.category == category).toList();
  }

  static Future<void> updateProduct(Product product) async {
    await product.save();
  }

  static Future<void> deleteProduct(Product product) async {
    await product.delete();
  }

  static List<String> getCategories() {
    final box = Hive.box<Product>(_productsBoxName);
    return box.values.map((product) => product.category).toSet().toList();
  }
}
