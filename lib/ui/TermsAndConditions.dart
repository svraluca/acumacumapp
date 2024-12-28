import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';
import 'package:flutter/material.dart';

class Terms extends StatefulWidget {
  const Terms({super.key});

  @override
  _TermsState createState() => _TermsState();
}

class _TermsState extends State<Terms> {
  bool _isLoading = true;
  PDFDocument? document;

  @override
  void initState() {
    super.initState();
    loadDocument();
  }

  loadDocument() async {
    try {
      document = await PDFDocument.fromAsset('assets/termsnc.pdf');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading PDF: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading terms and conditions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Terms and Conditions"),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : document != null
                  ? Container(
                      color: Colors.white,
                      child: PDFViewer(
                        document: document!,
                        backgroundColor: Colors.white,
                      ),
                    )
                  : const Center(
                      child: Text('Unable to load terms and conditions'),
                    ),
        ),
      ),
    );
  }
}
