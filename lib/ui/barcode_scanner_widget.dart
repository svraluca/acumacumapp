import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:acumacum/ui/UserProfiles.dart';
import 'package:acumacum/ui/viewProfiles.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final String userId;

  const BarcodeScannerWidget({super.key, required this.userId});

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget>
    with WidgetsBindingObserver {
  MobileScannerController controller = MobileScannerController(
    torchEnabled: true,
    useNewCameraSelector: true,
    formats: [BarcodeFormat.qrCode],
  );
  StreamSubscription<Object?>? _subscription;

  void _handleBarcode(BarcodeCapture barcodes) async {
    if (mounted) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(barcodes.barcodes[0].displayValue)
          .get();
      if (snapshot.exists) {
        DocumentSnapshot snapshot2 = await FirebaseFirestore.instance
            .collection('Users')
            .doc(snapshot.id)
            .collection('BusinessAccount')
            .doc('detail')
            .get();
        navigateToUserProfilePage(snapshot, context, widget.userId, snapshot2);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _subscription = controller.barcodes.listen(_handleBarcode);

    unawaited(controller.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _subscription = controller.barcodes.listen(_handleBarcode);

        unawaited(controller.start());
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller.stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Scan Barcode"),
      ),
      body: MobileScanner(
        controller: controller,
      ),
    );
  }

  void navigateToUserProfilePage(
    DocumentSnapshot snapshot,
    BuildContext context,
    String userId,
    DocumentSnapshot snapshot2,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryProfiles(
          UserProfiles(
            snapshot.id,
            (snapshot.data() as Map)['name'],
            (snapshot.data() as Map)['avatarUrl'],
            (snapshot.data() as Map)['address'],
            (snapshot2.data() as Map)['category'],
          ),
          userId,
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
    await controller.dispose();
  }
}
