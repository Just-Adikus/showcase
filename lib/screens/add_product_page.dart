import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:showcase/screens/bluetooth_settings_screen.dart';
import 'dart:io';
import '../models/product.dart';
import '../services/hive_service.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController quantityController = TextEditingController(text: "1");
  String selectedCategory = "Напитки";
  File? _image;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _addProduct() async {
    String name = nameController.text.trim();
    String priceText = priceController.text.trim();
    String quantityText = quantityController.text.trim();

    if (name.isEmpty || priceText.isEmpty || quantityText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Заполните все поля!")));
      return;
    }

    double? price = double.tryParse(priceText);
    int? quantity = int.tryParse(quantityText);

    if (price == null || price < 0.01 || price > 9999.99) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Цена должна быть от 0.01 до 9999.99")),
      );
      return;
    }

    if (quantity == null || quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Количество должно быть минимум 1")),
      );
      return;
    }

    String? imageUrl;
    if (_image != null) {
      // Сохраняем файл в директорию документов приложения
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(_image!.path);
      final savedImage = await _image!.copy('${appDir.path}/$fileName');
      imageUrl = savedImage.path;
    }

    Product product = Product(
      name: name,
      category: selectedCategory,
      price: price,
      imageUrl: imageUrl,
    );

    await HiveService.addProduct(product);

    nameController.clear();
    priceController.clear();
    quantityController.text = "1";
    setState(() => _image = null);

    // Возврат на предыдущий экран
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Добавить товар"),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedCategory,
              items:
                  ["Напитки", "Закуски"].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (value) => setState(() => selectedCategory = value!),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Название"),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: "Цена"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(labelText: "Количество"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            _image != null
                ? Image.file(_image!, height: 100)
                : Text("Изображение не выбрано"),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image),
              label: Text("Выбрать изображение"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addProduct,
              child: Text("Добавить товар"),
            ),
          ],
        ),
      ),
    );
  }
}
