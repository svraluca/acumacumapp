import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';
import 'package:flutter/material.dart';

class Privacy extends StatefulWidget {
  const Privacy({super.key});

  @override
  _PrivacyState createState() => _PrivacyState();
}

class _PrivacyState extends State<Privacy> {
  bool _isLoading = true;
  late PDFDocument document;

  @override
  void initState() {
    // super.initState();
    // loadDocument();
  }

  loadDocument() async {
    document = await PDFDocument.fromAsset('assets/privacy.pdf');

    setState(() => _isLoading = false);
  }

  /* changePDF(value) async {
    setState(() => _isLoading = true);
    if (value == 1) {
      document = await PDFDocument.fromAsset('assets/sample2.pdf');
    } else if (value == 2) {
      document = await PDFDocument.fromURL("http://conorlastowka.com/book/CitationNeededBook-Sample.pdf");
    } else {
      document = await PDFDocument.fromAsset('assets/privacy.pdf');
    }
    setState(() => _isLoading = false);
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy and Security"),
      ),
      body: Center(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PDFViewer(
                document: document,
              ),
      ),
    );
  }
}
