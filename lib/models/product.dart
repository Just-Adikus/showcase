import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String category;

  @HiveField(3)
  late double price;

  @HiveField(4)
  String? imageUrl;

  Product({
    required this.name,
    required this.category,
    required this.price,
    this.imageUrl,
  }) {
    id = DateTime.now().millisecondsSinceEpoch.toString();
  }
}
