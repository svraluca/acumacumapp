import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'UserProfiles.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchString = '';
  String? activeFilter;

  @override
  void initState() {
    super.initState();
    // Memastikan keyboard langsung muncul saat halaman terbuka
    Future.delayed(
        Duration.zero, () => FocusScope.of(context).requestFocus(_focusNode));
  }

  final FocusNode _focusNode = FocusNode();

  String normalizeString(String input) {
    // Convert to lowercase
    String normalized = input.toLowerCase();
    
    // Replace diacritics
    normalized = normalized
      .replaceAll('ș', 's')
      .replaceAll('ț', 't')
      .replaceAll('ă', 'a')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ţ', 't')
      .replaceAll('à', 'a')
      .replaceAll('á', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ì', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ò', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ù', 'u')
      .replaceAll('ü', 'u');
    
    return normalized.trim();
  }

  Future<void> trackSearch(String serviceName, String category) async {
    try {
      print('Starting trackSearch...');
      print('Service Name: $serviceName');
      print('Category: $category');
      
      // Create a unique document ID based on category and service name
      final docId = '${category}_$serviceName'.replaceAll(' ', '_').toLowerCase();
      
      final searchRef = FirebaseFirestore.instance
          .collection('serviceSearches')
          .doc(docId);
      
      print('Document path: ${searchRef.path}');

      // Get the current document
      final doc = await searchRef.get();
      
      if (doc.exists) {
        print('Current search count: ${doc.data()?['searchCount']}');
        // Update existing document
        await searchRef.update({
          'searchCount': FieldValue.increment(1),
          'lastSearched': FieldValue.serverTimestamp(),
        });
      } else {
        print('Creating new document...');
        // Create new document
        await searchRef.set({
          'category': category,
          'serviceName': serviceName,
          'searchCount': 1,
          'lastSearched': FieldValue.serverTimestamp(),
          'isServiceSearch': true,
        });
      }
      
      // Verify the document after update
      final verifyDoc = await searchRef.get();
      if (verifyDoc.exists) {
        print('After update - Search count: ${verifyDoc.data()?['searchCount']}');
      }

    } catch (e) {
      print('Error in trackSearch: $e');
    }
  }

  void performSearch(String searchTerm, String category) {
    // Your existing search logic
    // ...

    // Add search tracking
    trackSearch(searchTerm, category);
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  focusNode: _focusNode,
                  onChanged: (value) {
                    setState(() {
                      searchString = value;
                    });
                  },
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      // Your existing submit logic
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for a service or business',
                    hintStyle: const TextStyle(color: Colors.black54),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        setState(() {});
                      },
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  _showFilterDialog();
                },
              ),
            ),
          ],
        ),
        if (activeFilter != null)
          Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeFilter!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      activeFilter = null;
                      searchString = '';
                    });
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchSuggestions() {
    if (searchString.isEmpty) {
      return const Center(
        child: Text(
          'No data searched yet',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: searchBusinesses(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error occurred'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final suggestions = snapshot.data!;

        if (suggestions.isEmpty) {
          return const Center(child: Text('No suggestions found.'));
        }

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final doc = suggestions[index];
              final data = doc.data();
              final businessName = data['name'] ?? 'No Name';
              final businessId = doc.id;
              final coverPhotoUrl = data['coverPhotoUrl'] ?? 'default';
              final address = data['address'] ?? 'No Address';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfiles(
                        businessId,
                        businessName,
                        coverPhotoUrl,
                        address,
                        data['mainCategory'] ?? 'Business', // Use mainCategory here
                      ),
                    ),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: coverPhotoUrl == 'default'
                        ? const NetworkImage(
                            "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png",
                          )
                        : NetworkImage(coverPhotoUrl),
                    radius: 24,
                  ),
                  title: Text(
                    businessName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black54,
                    size: 16,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> searchBusinesses() async {
    final businessDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final searchLower = normalizeString(searchString);

    print('Searching for: $searchLower');

    try {
      // Single query to get all businesses
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('userRole', isEqualTo: 'Business')
          .get();

      print('Total businesses found: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        final businessData = doc.data();
        final businessName = normalizeString(businessData['name'] ?? '');
        final businessAddress = normalizeString(businessData['address'] ?? '');

        // Check if the search matches business name or address first
        bool shouldInclude = false;
        
        // If searching for Bucharest/Bucuresti, include businesses from that address
        if (searchLower == 'bucharest' || searchLower == 'bucuresti') {
          shouldInclude = businessAddress.contains('bucharest') || 
                         businessAddress.contains('bucuresti');
        } else {
          shouldInclude = businessName.contains(searchLower) || 
                         businessAddress.contains(searchLower);
        }

        if (shouldInclude) {
          businessDocs.add(doc);
          continue; // Skip service check if already included
        }

        // Only check services if necessary (name/address didn't match)
        if (!shouldInclude && searchLower.isNotEmpty) {
          // Get services in a single query instead of multiple streams
          final servicesSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .doc(doc.id)
              .collection('Services')
              .get();

          // Check if any service matches
          for (var service in servicesSnapshot.docs) {
            final serviceData = service.data();
            final serviceName = normalizeString(serviceData['name'] ?? '');
            
            if (serviceName.contains(searchLower)) {
              businessDocs.add(doc);
              break; // Exit loop once a match is found
            }
          }
        }
      }

      print('Final results count: ${businessDocs.length}');
      return businessDocs;

    } catch (e) {
      print('Error in searchBusinesses: $e');
      return [];
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter by City',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchString = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter city name',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.grey[200],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              if (searchString.isNotEmpty) {
                                this.setState(() {
                                  activeFilter = searchString;
                                });
                              }
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Apply',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Color(0xFF000080),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 10),
            Expanded(child: _buildSearchSuggestions()),
          ],
        ),
      ),
    );
  }
}
