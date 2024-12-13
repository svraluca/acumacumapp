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

  @override
  void initState() {
    super.initState();
    // Memastikan keyboard langsung muncul saat halaman terbuka
    Future.delayed(
        Duration.zero, () => FocusScope.of(context).requestFocus(_focusNode));
  }

  final FocusNode _focusNode = FocusNode();

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
    return Container(
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
            // Remove this as we don't want to track with "General Search"
            // performSearch(value, 'General Search');
          }
        },
        decoration: InputDecoration(
          hintText: 'Search for a service or business',
          hintStyle: const TextStyle(color: Colors.black54),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Remove this as well
              // if (searchString != null && searchString!.isNotEmpty) {
              //   performSearch(searchString!, 'General Search');
              // }
              setState(() {});
            },
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> processBusinessDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final businessDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final searchLower = searchString.toLowerCase();
    final processedServices = Set<String>(); // Track processed services

    for (var doc in docs) {
      final businessData = doc.data();
      
      if (businessData['userRole'] == 'Business') {
        final businessDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(doc.id)
            .collection('BusinessAccount')
            .doc('detail')
            .get();

        if (businessDoc.exists) {
          final businessCategory = businessDoc.data()?['category'] ?? 
                                 businessDoc.data()?['mainCategory'];
          
          final businessName = (businessData['name'] ?? '').toString().toLowerCase();
          
          // Just add to results if business name matches, but don't track in analytics
          if (businessName.contains(searchLower)) {
            businessDocs.add(doc);
            continue;
          }

          // Only track service searches in analytics
          final servicesSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .doc(doc.id)
              .collection('Services')
              .get();

          for (var service in servicesSnapshot.docs) {
            final serviceData = service.data();
            final serviceName = (serviceData['name'] ?? '').toString().toLowerCase();
            
            if (serviceName.contains(searchLower)) {
              // Only track if we haven't processed this service name before
              final serviceKey = '${businessCategory}_${serviceData['name']}';
              if (!processedServices.contains(serviceKey)) {
                processedServices.add(serviceKey);
                
                if (businessCategory != null && businessCategory.isNotEmpty) {
                  print('Tracking search for service: ${serviceData['name']} in category: $businessCategory');
                  await trackSearch(
                    serviceData['name'],
                    businessCategory
                  );
                }
              }
              
              if (!businessDocs.contains(doc)) {
                businessDocs.add(doc);
              }
            }
          }
        }
      }
    }

    return businessDocs;
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

    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .where('userRole', isEqualTo: 'Business')
          .where('country', isEqualTo: 'Romania')
          .snapshots()
          .asyncMap((snapshot) async {
        final businessDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        for (var doc in snapshot.docs) {
          final businessData = doc.data();
          
          // When accessing the business profile, fetch its category
          if (businessData['userRole'] == 'Business') {
            final businessDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(doc.id)
                .collection('BusinessAccount')
                .doc('detail')
                .get();

            if (businessDoc.exists) {
              final businessCategory = businessDoc.data()?['category'] ?? businessDoc.data()?['mainCategory'];
              print('Fetched business category: $businessCategory for ${businessData['name']}'); // Debug log

              final businessName = (businessData['name'] ?? '').toString().toLowerCase();
              
              // Just add to results if business name matches, but don't track in analytics
              if (businessName.contains(searchString.toLowerCase())) {
                businessDocs.add(doc);
                continue;
              }

              // Only track service searches in analytics
              final servicesSnapshot = await FirebaseFirestore.instance
                  .collection('Users')
                  .doc(doc.id)
                  .collection('Services')
                  .get();

              for (var service in servicesSnapshot.docs) {
                final serviceData = service.data();
                final serviceName = (serviceData['name'] ?? '').toString().toLowerCase();
                
                if (serviceName.contains(searchString.toLowerCase())) {
                  print('Found matching service: ${serviceData['name']} in business: ${businessData['name']}');
                  print('Using category: $businessCategory');
                  
                  // Only track service searches
                  if (businessCategory != null && businessCategory.isNotEmpty) {
                    trackSearch(
                      serviceData['name'],
                      businessCategory
                    );
                  } else {
                    print('Warning: Missing category for business ${businessData['name']}');
                  }
                  
                  if (!businessDocs.contains(doc)) {
                    businessDocs.add(doc);
                  }
                }
              }
            }
          }
        }

        return businessDocs;
      }),
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
