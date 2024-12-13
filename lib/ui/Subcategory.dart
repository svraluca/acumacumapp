import 'package:flutter/material.dart';
import 'package:acumacum/ui/transport_category.dart';

class SubcategoryScreen extends StatelessWidget {
  final String category;
  final List<String> location;
  final Map<String, List<String>> categoriesWithSubcategories;

  const SubcategoryScreen({
    required this.category,
    required this.location,
    required this.categoriesWithSubcategories,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    List<String> subcategories = categoriesWithSubcategories[category] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: ListView.builder(
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(subcategories[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransportScreen(
                    subcategories[index],
                    location,
                    "",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
