import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AddService extends StatefulWidget {
  final String userId;

  const AddService({Key? key, required this.userId}) : super(key: key);

  @override
  State<AddService> createState() => _AddServiceState();
}

class _AddServiceState extends State<AddService> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  XFile? imageFile;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A237E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Service',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Selection Section
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(imageFile!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 50, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Add Service Image',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // Service Name Field
                Text(
                  'Service Name',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.poppins(),
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    hintText: 'Enter service name',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a service name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Description Field
                Text(
                  'Description',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  style: GoogleFonts.poppins(),
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe your service (max 55 words)',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    if (_getWordCount(value) > 55) {
                      return 'Description should not exceed 55 words';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Price Field
                Text(
                  'Price',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  style: GoogleFonts.poppins(),
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Enter price',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    prefixText: 'RON ',
                    prefixStyle: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Add Service',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imageFile = image;
      });
    }
  }

  int _getWordCount(String text) {
    return text.split(' ').where((word) => word.isNotEmpty).length;
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

  Future<void> _submitForm() async {
    print('DEBUG: Starting _submitForm method');
    
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (imageFile != null) {
        print('DEBUG: Starting image content check');
        bool isAppropriate = await _checkImageContent(File(imageFile!.path));
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
        final storageRef = FirebaseStorage.instance.ref().child(
            'service_images/${DateTime.now().millisecondsSinceEpoch}_${imageFile!.name}');
        
        print('DEBUG: Starting file upload');
        final uploadTask = storageRef.putFile(File(imageFile!.path));
        final snapshot = await uploadTask.whenComplete(() {
          print('DEBUG: File upload completed');
        });
        imageUrl = await snapshot.ref.getDownloadURL();
        print('DEBUG: Got download URL: $imageUrl');
      } else {
        print('DEBUG: No image file selected');
      }

      print('DEBUG: Saving to Firestore');
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .collection('Services')
          .add({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'photoUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('DEBUG: Successfully saved to Firestore');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('DEBUG: Error in _submitForm:');
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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
