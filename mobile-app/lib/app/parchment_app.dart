import 'package:flutter/material.dart';

import '../core/services/document_inspector.dart';
import '../core/services/document_picker.dart';
import '../core/services/document_writer.dart';
import '../core/services/folder_source.dart';
import '../core/services/incoming_documents.dart';
import '../core/services/recent_folders.dart';
import '../features/reader/reader_controller.dart';
import '../ui/reader/reader_screen.dart';
import '../ui/theme/parchment_theme.dart';

class ParchmentApp extends StatefulWidget {
  const ParchmentApp({
    required this.documentPicker,
    this.documentWriter,
    this.folderSource,
    this.incomingSource,
    this.recentFoldersStore,
    this.documentInspector,
    super.key,
  });

  final DocumentPicker documentPicker;
  final DocumentWriter? documentWriter;
  final FolderSource? folderSource;
  final IncomingDocumentSource? incomingSource;
  final RecentFoldersStore? recentFoldersStore;
  final DocumentInspector? documentInspector;

  @override
  State<ParchmentApp> createState() => _ParchmentAppState();
}

class _ParchmentAppState extends State<ParchmentApp> {
  late final ReaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReaderController(
      documentPicker: widget.documentPicker,
      documentWriter: widget.documentWriter,
      folderSource: widget.folderSource,
      incomingSource: widget.incomingSource,
      recentFoldersStore: widget.recentFoldersStore,
      documentInspector: widget.documentInspector,
    )..loadRecentFolders();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => MaterialApp(
        title: 'Parchment',
        debugShowCheckedModeBanner: false,
        theme: ParchmentTheme.light(_controller.palette),
        darkTheme: ParchmentTheme.dark(_controller.palette),
        themeMode: _controller.themeMode,
        home: ReaderScreen(controller: _controller),
      ),
    );
  }
}
