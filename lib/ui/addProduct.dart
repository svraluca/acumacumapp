import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProduct extends StatefulWidget {
  final String userId;

  const AddProduct({Key? key, required this.userId}) : super(key: key);

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  XFile? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    print("Starting image picker"); // Debug log
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        print("Image picked successfully: ${image.path}"); // Debug log
        setState(() {
          _imageFile = image;
        });
      } else {
        print("No image selected"); // Debug log
      }
    } catch (e) {
      print("Error picking image: $e"); // Debug log
    }
  }

  int _getWordCount(String text) {
    return text.split(' ').where((word) => word.isNotEmpty).length;
  }

  String? _getWordCountError(String text) {
    int wordCount = _getWordCount(text);
    if (wordCount > 55) {
      return 'Description should not exceed 55 words. Current: $wordCount';
    }
    return null;
  }

  Future<bool> _checkImageContent(File imageFile) async {
    try {
      print('DEBUG: Starting image content check...'); 
      print('DEBUG: Image file path: ${imageFile.path}');
      print('DEBUG: Image file size: ${await imageFile.length()} bytes');

      List<int> imageBytes = await imageFile.readAsBytes();
      print('DEBUG: Successfully read image bytes');
      String base64Image = base64Encode(imageBytes);
      print('DEBUG: Successfully encoded image to base64');

      final body = {
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'SAFE_SEARCH_DETECTION',
                'maxResults': 1
              }
            ],
          }
        ]
      };
      print('DEBUG: Prepared API request body');

      print('DEBUG: Sending request to Vision API...');
      final response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=AIzaSyCVhYFD2mA9XGi0iizndFzgRs9kEGGvBZc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      print('DEBUG: Received API response');
      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Full response body: ${response.body}');

      if (response.statusCode == 200) {
        print('DEBUG: Successful API response (200)');
        final data = jsonDecode(response.body);
        final safeSearch = data['responses'][0]['safeSearchAnnotation'];

        print('DEBUG: ====== Safe Search Results ======');
        print('DEBUG: Adult: ${safeSearch['adult']}');
        print('DEBUG: Spoof: ${safeSearch['spoof']}');
        print('DEBUG: Medical: ${safeSearch['medical']}');
        print('DEBUG: Violence: ${safeSearch['violence']}');
        print('DEBUG: Racy: ${safeSearch['racy']}');
        print('DEBUG: ================================');

        // For testing, let's print the decision process
        print('DEBUG: Checking content rules...');
        
        if (safeSearch['adult'] == 'VERY_LIKELY') {
          print('DEBUG: Image rejected - adult content is VERY_LIKELY');
          return false;
        }

        print('DEBUG: Image passed all content checks');
        return true;
      } else {
        print('DEBUG: API request failed with status: ${response.statusCode}');
        print('DEBUG: Error response body: ${response.body}');
        // For testing purposes, let's allow images when API fails
        print('DEBUG: Allowing image despite API failure');
        return true;
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error in _checkImageContent:');
      print('DEBUG: Error message: $e');
      print('DEBUG: Stack trace: $stackTrace');
      // For testing purposes, let's allow images when there's an error
      print('DEBUG: Allowing image despite error');
      return true;
    }
  }

  Future<void> _saveProduct() async {
    print('DEBUG: Starting _saveProduct method');
    
    if (_imageFile == null) {
      print('DEBUG: No image file selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Starting image content check');
      bool isAppropriate = await _checkImageContent(File(_imageFile!.path));
      print('DEBUG: Content check result: $isAppropriate');

      if (!isAppropriate) {
        print('DEBUG: Image failed content check');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please choose an appropriate image'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('DEBUG: Proceeding with image upload');
      String? imageUrl;
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
            'product_images/${DateTime.now().millisecondsSinceEpoch}_${_imageFile!.name}');
        
        final uploadTask = storageRef.putFile(File(_imageFile!.path));
        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .collection('Products')
          .add({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'photoUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error in _saveProduct:');
      print('DEBUG: Error message: $e');
      print('DEBUG: Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A237E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Product',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Product Image',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imageFile!.path),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No image selected',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload, color: Colors.white),
                    label: Text(
                      'Upload Image',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Product Information',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1A237E)),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value != null) {
                          // Safely handle text changes
                        }
                      });
                    },
                    onSubmitted: (value) {
                      try {
                        // Handle submission
                      } catch (e) {
                        print('Error in text submission: $e');
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1A237E)),
                      ),
                      errorText: _getWordCountError(_descriptionController.text),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price',
                      labelStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1A237E)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Save Product',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1A237E),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
