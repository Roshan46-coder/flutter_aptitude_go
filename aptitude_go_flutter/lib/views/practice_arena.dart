import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/api_client.dart';
import '../core/theme.dart';
import '../widgets/web_download_helper.dart' if (dart.library.html) '../widgets/web_download_helper_web.dart' as web_helper;
import '../widgets/pdf_view_screen.dart' if (dart.library.html) '../widgets/pdf_view_screen_web.dart' as pdf_viewer;
const List<Map<String, String>> _DEFAULT_PDFS = [
  {'name': '01_Quantitative_Aptitude_Numerical_Ability_Full_Content.pdf', 'size': '0.1 MB'},
  {'name': '02_Logical_Reasoning_Analytical_Ability_Full_Content.pdf', 'size': '0.1 MB'},
  {'name': '03_Verbal_Ability_English_Comprehension_Full_Content.pdf', 'size': '0.1 MB'},
  {'name': '04_Data_Interpretation_and_Analysis_Full_Content.pdf', 'size': '0.1 MB'},
  {'name': '05_Abstract_Reasoning_Non-Verbal_Reasoning_Full_Content.pdf', 'size': '0.1 MB'},
  {'name': '06_Technical_Aptitude_Basic_Programming_and_AIML_Concepts_Full_Content.pdf', 'size': '0.1 MB'},
  {'name': 'core_aptitudelevel_questions.pdf', 'size': '0.2 MB'},
  {'name': 'hr_interview_part1.pdf', 'size': '21.6 MB'},
  {'name': 'hr_interview_part2.pdf', 'size': '21.6 MB'},
  {'name': 'hr_interview_part3.pdf', 'size': '21.6 MB'},
  {'name': 'hr_interview_part4.pdf', 'size': '21.6 MB'},
];

class PracticeArena extends StatefulWidget {
  const PracticeArena({super.key});

  @override
  State<PracticeArena> createState() => _PracticeArenaState();
}

class _PracticeArenaState extends State<PracticeArena> {
  List<dynamic> _pdfs = [];
  List<dynamic> _filteredPdfs = [];
  bool _isLoading = true;
  String? _error;
  final Map<String, double> _downloadProgress = {};
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPdfs();
    _searchController.addListener(_filterPdfs);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPdfs);
    _searchController.dispose();
    super.dispose();
  }

  void _filterPdfs() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPdfs = List.from(_pdfs);
      } else {
        _filteredPdfs = _pdfs.where((pdf) {
          final name = (pdf['name'] as String? ?? '').toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchPdfs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    _pdfs = List.from(_DEFAULT_PDFS);
    _filterPdfs();
    setState(() {
      _isLoading = false;
    });

    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.get('tests/arena/practice/');
      if (mounted) {
        final remote = response.data['pdfs'] as List<dynamic>?;
        if (remote != null && remote.isNotEmpty) {
          setState(() {
            _pdfs = remote.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _filterPdfs();
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<String> _pdfStorageDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory("${appDir.path}/pdfs");
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<void> _downloadAndOpenPdf(String filename, {bool isView = false}) async {
    final api = Provider.of<ApiClient>(context, listen: false);
    final String encodedName = Uri.encodeComponent(filename);
    // Base URL adjustments for download endpoints
    final String base = api.baseUrl.replaceAll('/api/', '/');
    final List<String> urls = [
      "${api.baseUrl}tests/arena/practice/pdf/$encodedName",
      "${base}media/practice_questions/$encodedName",
      "assets/pdfs/$encodedName",
    ];
    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _downloadProgress[filename] = 0.01;
      });

      // 1. Try to load PDF from assets first (enabling fully offline/independent download)
      bool downloaded = false;
      try {
        final byteData = await DefaultAssetBundle.of(context).load("assets/pdfs/$filename");
        final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
        if (isView) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => pdf_viewer.PdfViewScreen(
                pdfBytes: bytes,
                filename: filename,
              ),
            ),
          );
        } else {
          web_helper.downloadFileWeb(bytes, filename);
        }
        downloaded = true;
      } catch (e) {
        debugPrint("Failed to load PDF from web assets, falling back to HTTP download: $e");
      }

      // 2. Fall back to downloading via HTTP using the URLs list
      if (!downloaded) {
        for (final url in urls) {
          try {
            final response = await api.dio.get<List<int>>(
              url,
              options: Options(responseType: ResponseType.bytes),
            );
            if (response.statusCode == 200 && response.data != null) {
              if (isView) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => pdf_viewer.PdfViewScreen(
                      pdfBytes: response.data!,
                      filename: filename,
                    ),
                  ),
                );
              } else {
                web_helper.downloadFileWeb(response.data!, filename);
              }
              downloaded = true;
              break;
            }
          } catch (e) {
            debugPrint("Failed HTTP download from $url on Web: $e");
          }
        }
      }

      if (mounted) {
        setState(() {
          _downloadProgress.remove(filename);
        });
      }

      if (!downloaded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to download or view PDF $filename on Web."),
            backgroundColor: AppTheme.livesRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    final storageDir = await _pdfStorageDir();
    final filePath = "$storageDir/$filename";
    final file = File(filePath);
    bool downloadSuccess = false;

    // 1. Check if already downloaded or perform download
    try {
      if (await file.exists() && await file.length() > 0) {
        downloadSuccess = true;
      } else {
        setState(() {
          _downloadProgress[filename] = 0.01;
        });

        // Try to load from local assets first (enabling fully offline/independent work)
        bool loadedFromAssets = false;
        try {
          final byteData = await DefaultAssetBundle.of(context).load("assets/pdfs/$filename");
          final buffer = byteData.buffer;
          await file.writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
          loadedFromAssets = true;
          downloadSuccess = true;
        } catch (e) {
          debugPrint("Failed to load PDF from assets, falling back to network: $e");
        }

        if (!loadedFromAssets) {
          String? lastError;
          for (final url in urls) {
            try {
              final response = await api.dio.download(
                url,
                filePath,
                onReceiveProgress: (count, total) {
                  if (total > 0 && mounted) {
                    setState(() {
                      _downloadProgress[filename] = count / total;
                    });
                  }
                },
              );

              if (response.statusCode != 200) {
                lastError = "Server returned status code ${response.statusCode}";
                if (await file.exists()) {
                  await file.delete();
                }
                continue;
              }

              lastError = null;
              break;
            } catch (e) {
              lastError = e.toString();
              if (await file.exists()) {
                try {
                  await file.delete();
                } catch (_) {}
              }
            }
          }

          if (lastError != null) {
            throw Exception(lastError);
          }
          downloadSuccess = true;
        }

        if (mounted) {
          setState(() {
            _downloadProgress.remove(filename);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(filename);
        });
        final msg = e.toString().contains('Connection refused')
            ? "Connect to the server (Aptitude_GO) to download PDFs."
            : "Failed to download $filename: $e";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppTheme.livesRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // 2. Open/View the PDF file
    if (downloadSuccess) {
      try {
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to view $filename: ${result.message}"),
              backgroundColor: AppTheme.livesRed,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error opening PDF: $e"),
              backgroundColor: AppTheme.livesRed,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Practice PDF Arena"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPdfs,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPurple),
                        child: const Text("Retry"),
                      )
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Search PDFs...",
                          hintStyle: const TextStyle(color: Colors.white30),
                          prefixIcon: const Icon(Icons.search, color: Colors.white38),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white38),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppTheme.cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.neonPurple),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _filteredPdfs.isEmpty
                          ? Center(
                              child: Text(
                                _searchController.text.isEmpty
                                    ? "No practice PDFs available yet."
                                    : "No PDFs match your search.",
                                style: const TextStyle(color: Colors.white30),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredPdfs.length,
                              itemBuilder: (context, index) {
                                final pdf = _filteredPdfs[index];
                                final name = pdf['name'] as String;
                                final size = pdf['size'] as String;
                                final progress = _downloadProgress[name];
                                final isDownloading = progress != null;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.neonPurple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.neonPurple),
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      size,
                                      style: const TextStyle(fontSize: 12, color: Colors.white30),
                                    ),
                                    trailing: isDownloading
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              value: progress == 0.01 ? null : progress,
                                              strokeWidth: 2,
                                              color: AppTheme.neonPurple,
                                            ),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.open_in_new, color: Colors.white54, size: 20),
                                                onPressed: () => _downloadAndOpenPdf(name, isView: true),
                                                tooltip: "View",
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.file_download_outlined, color: Colors.white54, size: 20),
                                                onPressed: () => _downloadAndOpenPdf(name, isView: false),
                                                tooltip: "Download",
                                              ),
                                            ],
                                          ),
                                    onTap: isDownloading ? null : () => _downloadAndOpenPdf(name, isView: true),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
