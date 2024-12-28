import 'package:acumacum/notifications_setup/cloud_functions/app_cloud_functions.dart';
import 'package:acumacum/widgets/app_button.dart';
import 'package:flutter/material.dart';

const Color darkBlueColor = Color(0xFF1A237E);
const Color lightBlueColor = Color(0xFFE8EAF6);

class EditProduct extends StatefulWidget {
  final String userId;
  final String productId;
  final Map<String, dynamic> currentData;

  const EditProduct({
    Key? key,
    required this.userId,
    required this.productId,
    required this.currentData,
  }) : super(key: key);

  @override
  State<EditProduct> createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentData['name']);
    descriptionController = TextEditingController(text: widget.currentData['description']);
    priceController = TextEditingController(text: widget.currentData['price'].toString());
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Edit Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: darkBlueColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Editing Tips'),
                  content: const Text(
                    '• Give your product a clear, descriptive name\n'
                    '• Include key details in the description\n'
                    '• Set a competitive price\n'
                    '• Double-check all information before saving',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: lightBlueColor,
                image: widget.currentData['photoUrl'] != null
                    ? DecorationImage(
                        image: NetworkImage(widget.currentData['photoUrl']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.currentData['photoUrl'] == null
                  ? const Center(
                      child: Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: darkBlueColor,
                      ),
                    )
                  : null,
            ),
            
            // Form Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title
                  const Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkBlueColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name Field
                  _buildFormField(
                    controller: nameController,
                    label: 'Product Name',
                    icon: Icons.inventory_2,
                    hint: 'Enter product name',
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  _buildFormField(
                    controller: descriptionController,
                    label: 'Description',
                    icon: Icons.description,
                    hint: 'Describe your product',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Price Field
                  _buildFormField(
                    controller: priceController,
                    label: 'Price (RON)',
                    icon: Icons.attach_money,
                    hint: 'Enter price',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  AppButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlueColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => _saveChanges(context),
                    text: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines ?? 1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: darkBlueColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveChanges(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(darkBlueColor),
            ),
          );
        },
      );

      AppCloudFunctionService appCloudFunctionService = AppCloudFunctionService();
      final result = await appCloudFunctionService.updateUserData({
        'uid': widget.userId,
        'product': {
          'productId': widget.productId,
          'name': nameController.text.trim(),
          'description': descriptionController.text.trim(),
          'price': double.parse(priceController.text),
          'photoUrl': widget.currentData['photoUrl'],
        },
      });

      if (context.mounted) {
        // Hide loading indicator
        Navigator.pop(context);

        if (result) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Hide loading indicator
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating product: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
