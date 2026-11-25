import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../infrastructure/diagram_render_service.dart';
import '../../infrastructure/image_exporter.dart';
import '../../core/l10n/tr.dart';
import 'media_lightbox.dart';

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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 8, 6),
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Icon(
                        Icons.zoom_out_map,
                        size: 18,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
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
    builder: (_) => _VectorDiagramLightbox(
      result: result,
      name: name,
      background: background,
    ),
  );
}

class _VectorDiagramLightbox extends StatefulWidget {
  const _VectorDiagramLightbox({
    required this.result,
    required this.name,
    required this.background,
  });

  final DiagramRenderResult result;
  final String name;
  final Color background;

  @override
  State<_VectorDiagramLightbox> createState() => _VectorDiagramLightboxState();
}

class _VectorDiagramLightboxState extends State<_VectorDiagramLightbox> {
  late final WebViewController _controller;
  Future<bool> _savePng(VoidCallback beginSaving) async {
    final natural = widget.result.size!;
    var selection = _DiagramExportSize.m;
    final resolution = await showDialog<_DiagramExportSize>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) {
          final colors = Theme.of(context).colorScheme;
          return AlertDialog(
            icon: const Icon(Icons.image_outlined),
            title: Text(tr('選擇下載尺寸')),
            scrollable: true,
            content: SizedBox(
              width: 320,
              child: RadioGroup<_DiagramExportSize>(
                groupValue: selection,
                onChanged: (size) {
                  if (size != null) update(() => selection = size);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final size in _DiagramExportSize.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RadioListTile<_DiagramExportSize>(
                          value: size,
                          selected: selection == size,
                          selectedTileColor: colors.secondaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: selection == size
                                  ? colors.primary
                                  : colors.outlineVariant,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.trailing,
                          title: Text(
                            size.name.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${size.outputPixels(natural.width, natural)} × '
                            '${size.outputPixels(natural.height, natural)} px',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(tr('取消')),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, selection),
                icon: const Icon(Icons.download_rounded),
                label: Text(tr('儲存')),
              ),
            ],
          );
        },
      ),
    );
    if (resolution == null || !mounted) return false;
    beginSaving();
    final raster = await DiagramRenderService.instance.rasterize(
      widget.result.svg!,
      scale: resolution.scaleFor(natural),
      maxEdge: resolution.diagramEdge,
    );
    if (!raster.isSuccess) throw StateError(raster.error ?? tr('圖片產生失敗'));
    final png = await ImageExporter.flattenPng(
      raster.pngBytes!,
      background: widget.background,
      padding: resolution.padding.toDouble(),
    );
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .substring(0, 14);
    return ImageExporter.savePng(
      png,
      fileName: '${widget.name.toLowerCase()}-$stamp-${resolution.name}.png',
    );
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
body{display:flex;align-items:center;justify-content:center;min-height:100vh;box-sizing:border-box;padding:12px}
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
    return MediaLightbox(
      background: widget.background,
      content: WebViewWidget(controller: _controller),
      onSave: _savePng,
    );
  }
}

enum _DiagramExportSize {
  s(1024),
  m(2048),
  l(4096);

  const _DiagramExportSize(this.longestEdge);

  final int longestEdge;

  int get padding => longestEdge ~/ 32;
  int get diagramEdge => longestEdge - 2 * padding;

  double scaleFor(Size natural) => diagramEdge / natural.longestSide;

  int outputPixels(double axis, Size natural) =>
      math.max(1, (axis * scaleFor(natural)).round()) + 2 * padding;
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
