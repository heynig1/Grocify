// lib/screens/product_listing_screen.dart
import 'package:flutter/material.dart';

class ProductListingScreen extends StatelessWidget {
  const ProductListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  hint: Text('Filter'),
                  items: ['Price', 'Category', 'Availability']
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (_) {},
                ),
                DropdownButton<String>(
                  hint: Text('Sort'),
                  items: ['Low to High', 'High to Low']
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[300],
                    child: Center(child: Text('Image')),
                  ),
                  title: Text('Product $index'),
                  subtitle: Text('\$${(index + 1) * 10}'),
                  trailing: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/product-details'),
                    child: Text('Add to Cart'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}