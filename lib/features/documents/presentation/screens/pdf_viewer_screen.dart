import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/models/document_entity.dart';

class PdfViewerArgs {
  final DocumentEntity document;
  final int? initialPageNumber;

  const PdfViewerArgs({
    required this.document,
    this.initialPageNumber,
  });
}

/// PDF Viewer screen using pdfrx with page jump and zoom support.
class PdfViewerScreen extends StatefulWidget {
  final DocumentEntity document;
  final int? initialPageNumber;

  const PdfViewerScreen({
    super.key,
    required this.document,
    this.initialPageNumber,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  int _currentPage = 1;
  int _pageCount = 0;

  @override
  Widget build(BuildContext context) {
    final file = File(widget.document.storedPath);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.document.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (_pageCount > 0)
              Text(
                'Page $_currentPage of $_pageCount',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.first_page_rounded),
            tooltip: 'First Page',
            onPressed: () {
              if (_controller.isReady) {
                _controller.goToPage(pageNumber: 1);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.last_page_rounded),
            tooltip: 'Last Page',
            onPressed: () {
              if (_controller.isReady && _pageCount > 0) {
                _controller.goToPage(pageNumber: _pageCount);
              }
            },
          ),
        ],
      ),
      body: !file.existsSync()
          ? const Center(
              child: Text('PDF file could not be found in local storage.'),
            )
          : PdfViewer.file(
              widget.document.storedPath,
              controller: _controller,
              params: PdfViewerParams(
                maxScale: 4.0,
                minScale: 0.8,
                enableTextSelection: true,
                onViewerReady: (document, controller) {
                  setState(() {
                    _pageCount = document.pages.length;
                  });
                  if (widget.initialPageNumber != null &&
                      widget.initialPageNumber! > 0 &&
                      widget.initialPageNumber! <= document.pages.length) {
                    controller.goToPage(pageNumber: widget.initialPageNumber!);
                  }
                },
                onPageChanged: (page) {
                  if (page != null) {
                    setState(() {
                      _currentPage = page;
                    });
                  }
                },
                loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                },
                errorBannerBuilder: (context, error, stackTrace, documentRef) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to render PDF: $error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
