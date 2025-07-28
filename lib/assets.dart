import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class assetsPage extends StatefulWidget {
  const assetsPage({super.key});

  @override
  State<assetsPage> createState() => _assetsPageState();
}

class _assetsPageState extends State<assetsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar:  AppBar(
          backgroundColor: Colors.white,
          title: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              border: InputBorder.none,
              icon: Icon(Icons.search, color: Colors.grey),
            ),
            onChanged: (value) {
              // Handle search logic here
              print('Searching for: $value');
            },
          ),
        ),
       body: Column(
        mainAxisAlignment:MainAxisAlignment.spaceEvenly,
    ),
    );
  }
}
