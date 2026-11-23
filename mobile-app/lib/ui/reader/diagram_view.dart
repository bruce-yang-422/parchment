import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../infrastructure/diagram_render_service.dart';
import '../../infrastructure/image_exporter.dart';
import '../../core/l10n/tr.dart';

class DiagramView extends StatefulWidget {
  const DiagramView({
    required this.kind,
    required this.source,
    required this.dark,
    super.key,
  });

  final DiagramKind kind;
  final String source;
  final bool dark;

  @override
  State<DiagramView> createState() => _DiagramViewState();
}

class _DiagramViewState extends State<DiagramView> {
  late Future<DiagramRenderResult> _result;
  DiagramRenderResult? _initial;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void didUpdateWidget(covariant DiagramView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.dark != widget.dark ||
        oldWidget.kind != widget.kind) {
      _render();
    }
  }

  void _render() {
    final service = DiagramRenderService.instance;
    _initial = service.completed(
      widget.source,
      kind: widget.kind,
      dark: widget.dark,
    );
    _result = service.render(
      widget.source,
      kind: widget.kind,
      dark: widget.dark,
    );
  }

  String get _name =>
      widget.kind == DiagramKind.graphviz ? 'Graphviz' : 'Mermaid';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FutureBuilder<DiagramRenderResult>(
        future: _result,
        initialData: _initial,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _DiagramError(
              name: _name,
              source: widget.source,
              error: '${snapshot.error}',
            );
          }
          final result = snapshot.data;
          if (result == null) {
            return const SizedBox(
              height: 120,
              child: Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (!result.isSuccess) {
            return _DiagramError(
              name: _name,
              source: widget.source,
              error: result.error!,
            );
          }
          return _DiagramPreview(name: _name, result: result);
        },
      ),
    );
  }
}

class _DiagramPreview extends StatelessWidget {
  const _DiagramPreview({required this.name, required this.result});

  static const double _maxHeight = 480;

  final String name;
  final DiagramRenderResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: tr('圖表，點一下放大'),
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showDiagramLightbox(context, result, name: name),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final natural = result.size!;
              final available = math.max(1.0, constraints.maxWidth - 24);
              var width = math.min(available, natural.width);
              var height = width * natural.height / natural.width;
              if (height > _maxHeight) {
                width *= _maxHeight / height;
                height = _maxHeight;
              }
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Image.memory(
                        result.pngBytes!,
                        width: width,
                        height: height,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Icon(
                      Icons.zoom_out_map,
                      size: 18,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Opens [svg] full screen in a script-free WebView so pinch zoom stays
/// vector-sharp instead of scaling a bitmap.
void showDiagramLightbox(
  BuildContext context,
  DiagramRenderResult result, {
  required String name,
}) {
  final background = Theme.of(context).colorScheme.surface;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    builder: (dialogContext) => _VectorDiagramLightbox(
      result: result,
      name: name,
      background: background,
      onClose: () => Navigator.pop(dialogContext),
    ),
  );
}

class _VectorDiagramLightbox extends StatefulWidget {
  const _VectorDiagramLightbox({
    required this.result,
    required this.name,
    required this.background,
    required this.onClose,
  });

  final DiagramRenderResult result;
  final String name;
  final Color background;
  final VoidCallback onClose;

  @override
  State<_VectorDiagramLightbox> createState() => _VectorDiagramLightboxState();
}

class _VectorDiagramLightboxState extends State<_VectorDiagramLightbox> {
  late final WebViewController _controller;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _saving = false;

  Future<void> _savePng() async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = _messengerKey.currentState!;
    try {
      final raster = await DiagramRenderService.instance.rasterize(
        widget.result.svg!,
      );
      if (!raster.isSuccess) throw StateError(raster.error ?? tr('圖片產生失敗'));
      final png = await ImageExporter.flattenPng(
        raster.pngBytes!,
        background: widget.background,
        padding: 96,
      );
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[^0-9]'), '')
          .substring(0, 14);
      final saved = await ImageExporter.savePng(
        png,
        fileName: '${widget.name.toLowerCase()}-$stamp.png',
      );
      if (saved) {
        messenger.showSnackBar(SnackBar(content: Text(tr('已儲存圖片'))));
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(tr('圖片儲存失敗，請再試一次'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final background = _cssColor(widget.background);
    // The SVG was sanitized by DOMPurify in the renderer. It is inlined (not
    // an <img>) so the WebView re-rasterizes vector paths at every zoom level.
    final html =
        '''<!doctype html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,minimum-scale=1,maximum-scale=12,user-scalable=yes">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data:; style-src 'unsafe-inline'">
<style>
html,body{margin:0;min-height:100%;background:$background}
body{display:flex;align-items:center;justify-content:center;min-height:100vh;box-sizing:border-box;padding:64px 12px 24px}
.diagram{width:100%}
.diagram svg{display:block;width:100%!important;max-width:none!important;height:auto!important;margin:0 auto}
</style></head><body><div class="diagram">${widget.result.svg}</div></body></html>''';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(widget.background)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) =>
              request.url.startsWith('data:') || request.url == 'about:blank'
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
        ),
      )
      ..loadHtmlString(html);
  }

  static String _cssColor(Color color) {
    int channel(double value) => (value * 255).round().clamp(0, 255);
    return 'rgb(${channel(color.r)},${channel(color.g)},${channel(color.b)})';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: widget.background,
      child: ScaffoldMessenger(
        key: _messengerKey,
        child: Scaffold(backgroundColor: widget.background, body: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: _controller)),
        Positioned(
          top: 8,
          right: 8,
          child: SafeArea(
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: tr('儲存成圖片'),
                  onPressed: _saving ? null : _savePng,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: tr('關閉'),
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DiagramError extends StatelessWidget {
  const _DiagramError({
    required this.name,
    required this.source,
    required this.error,
  });

  final String name;
  final String source;
  final String error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('這張圖表無法顯示，可能是內容格式有誤。以下是原始內容：'),
            style: TextStyle(color: colors.onErrorContainer),
          ),
          const SizedBox(height: 4),
          Text(
            '$name：$error',
            style: TextStyle(
              fontSize: 12,
              color: colors.onErrorContainer.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              source,
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
