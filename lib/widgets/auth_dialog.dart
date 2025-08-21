import 'package:flutter/material.dart';
import '../screens/product_list_screen.dart';

void showAuthDialog(BuildContext context) {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Авторизация'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Пароль'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              // Здесь простейшая проверка авторизации
              if (emailController.text == 'admin@example.com' &&
                  passwordController.text == 'admin123') {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductListPage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Неверный логин или пароль')),
                );
              }
            },
            child: Text('Войти'),
          ),
        ],
      );
    },
  );
}
