import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PdfViewScreen extends StatefulWidget {
  final List<int> pdfBytes;
  final String filename;

  const PdfViewScreen({
    super.key,
    required this.pdfBytes,
    required this.filename,
  });

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  late String _viewId;
  late html.Blob _blob;
  late String _url;

  @override
  void initState() {
    super.initState();
    _blob = html.Blob([widget.pdfBytes], 'application/pdf');
    _url = html.Url.createObjectUrlFromBlob(_blob);
    _viewId = 'pdf-viewer-${DateTime.now().millisecondsSinceEpoch}';

    // Register the iframe creator
    // ignore: undefined_prefixed_name
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId, {Object? params}) => html.IFrameElement()
          ..src = _url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%',
      );
    }
  }

  @override
  void dispose() {
    html.Url.revokeObjectUrl(_url);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(widget.filename),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: HtmlElementView(viewType: _viewId),
    );
  }
}
