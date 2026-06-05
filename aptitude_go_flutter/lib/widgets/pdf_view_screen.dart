import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

class PdfViewScreen extends StatefulWidget {
  final List<int> pdfBytes;
  final String filename;
  final String? filePath; // optional direct path (avoids re-writing bytes)

  const PdfViewScreen({
    super.key,
    required this.pdfBytes,
    required this.filename,
    this.filePath,
  });

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  String? _localPath;
  bool _isReady = false;
  bool _hasError = false;
  int _currentPage = 0;
  int _totalPages = 0;
  PDFViewController? _controller;

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    try {
      if (widget.filePath != null && File(widget.filePath!).existsSync()) {
        setState(() => _localPath = widget.filePath);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${widget.filename}');
        await file.writeAsBytes(widget.pdfBytes, flush: true);
        if (mounted) setState(() => _localPath = file.path);
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text(
          widget.filename,
          style: const TextStyle(fontSize: 13, color: Colors.white70),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: _hasError
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                  SizedBox(height: 16),
                  Text('Failed to load PDF.',
                      style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : _localPath == null
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFA855F7)),
                )
              : Stack(
                  children: [
                    PDFView(
                      filePath: _localPath!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                      fitPolicy: FitPolicy.BOTH,
                      onRender: (pages) {
                        if (mounted) {
                          setState(() {
                            _totalPages = pages ?? 0;
                            _isReady = true;
                          });
                        }
                      },
                      onViewCreated: (controller) {
                        _controller = controller;
                      },
                      onPageChanged: (page, total) {
                        if (mounted) {
                          setState(() {
                            _currentPage = page ?? 0;
                            _totalPages = total ?? 0;
                          });
                        }
                      },
                      onError: (error) {
                        if (mounted) setState(() => _hasError = true);
                      },
                    ),
                    if (!_isReady)
                      const Center(
                        child: CircularProgressIndicator(color: Color(0xFFA855F7)),
                      ),
                  ],
                ),
      bottomNavigationBar: _isReady && _totalPages > 1
          ? Container(
              color: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white70),
                    onPressed: _currentPage > 0
                        ? () => _controller?.setPage(_currentPage - 1)
                        : null,
                  ),
                  Expanded(
                    child: Slider(
                      value: _currentPage.toDouble(),
                      min: 0,
                      max: (_totalPages - 1).toDouble(),
                      divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                      activeColor: const Color(0xFFA855F7),
                      inactiveColor: const Color(0xFF334155),
                      onChanged: (v) {
                        _controller?.setPage(v.toInt());
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white70),
                    onPressed: _currentPage < _totalPages - 1
                        ? () => _controller?.setPage(_currentPage + 1)
                        : null,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
