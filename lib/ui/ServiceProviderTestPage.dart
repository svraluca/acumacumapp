import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProviderTestPage extends StatefulWidget {
  final String serviceProviderId;

  const ServiceProviderTestPage({super.key, required this.serviceProviderId});

  @override
  _ServiceProviderTestPageState createState() =>
      _ServiceProviderTestPageState();
}

class _ServiceProviderTestPageState extends State<ServiceProviderTestPage> {
  Map<String, dynamic>? serviceProviderData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchServiceProviderData();
  }

  Future<void> fetchServiceProviderData() async {
    try {
      DocumentSnapshot document = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.serviceProviderId)
          .get();

      if (document.exists) {
        final data = document.data() as Map<String, dynamic>?;
        if (data != null && data['userRole'] == 'Business') {
          // Validasi userRole
          setState(() {
            serviceProviderData = data;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          print(
              "Dokumen tidak valid untuk serviceProviderId: ${widget.serviceProviderId}");
        }
      } else {
        setState(() {
          isLoading = false;
        });
        print(
            "Dokumen tidak ditemukan untuk serviceProviderId: ${widget.serviceProviderId}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error saat mengambil data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Service Provider Test Page"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : serviceProviderData != null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nama: ${serviceProviderData?['name'] ?? 'Tidak tersedia'}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Alamat: ${serviceProviderData?['address'] ?? 'Tidak tersedia'}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Jam Buka: ${serviceProviderData?['openTime'] ?? 'Tidak tersedia'}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Jam Tutup: ${serviceProviderData?['closeTime'] ?? 'Tidak tersedia'}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Negara: ${serviceProviderData?['country'] ?? 'Tidak tersedia'}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      serviceProviderData?['avatarUrl'] != null &&
                              serviceProviderData!['avatarUrl'] != 'default'
                          ? Image.network(
                              serviceProviderData!['avatarUrl'],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.account_circle,
                              size: 100,
                              color: Colors.grey,
                            ),
                    ],
                  ),
                )
              : const Center(
                  child: Text("Data tidak ditemukan untuk ID ini."),
                ),
    );
  }
}
