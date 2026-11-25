import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../core/l10n/tr.dart';

enum DiagramKind { mermaid, graphviz }

typedef DiagramColors = ({bool dark, String surface, String ink});

class DiagramRenderResult {
  const DiagramRenderResult._({this.svg, this.pngBytes, this.size, this.error});

  const DiagramRenderResult.success(String svg, Uint8List pngBytes, Size size)
    : this._(svg: svg, pngBytes: pngBytes, size: size);

  const DiagramRenderResult.failure(String error) : this._(error: error);

  /// Sanitized SVG, used by the vector lightbox.
  final String? svg;

  /// High-density raster for the inline preview.
  final Uint8List? pngBytes;

  /// Natural CSS size of the diagram.
  final Size? size;

  final String? error;

  bool get isSuccess => pngBytes != null;
}

/// Renders Mermaid and Graphviz diagrams in one hidden, script-only WebView.
///
/// Only bundled assets are loaded; navigation and network access are blocked,
/// and every SVG is sanitized with DOMPurify before it leaves the WebView.
class DiagramRenderService {
  DiagramRenderService._();
  static final instance = DiagramRenderService._();

  static const _readyTimeout = Duration(seconds: 15);
  static const _renderTimeout = Duration(seconds: 20);

  final Map<int, Completer<DiagramRenderResult>> _pending = {};
  final Map<String, Future<DiagramRenderResult>> _cache = {};
  final Map<String, DiagramRenderResult> _completed = {};
  late final WebViewController _controller;
  final Completer<void> _ready = Completer<void>();
  bool _initialized = false;
  String? _initializationError;
  int _nextId = 0;

  WebViewController get controller {
    _initialize();
    return _controller;
  }

  Future<DiagramRenderResult> render(
    String source, {
    required DiagramKind kind,
    required DiagramColors colors,
  }) {
    final key = _key(source, kind: kind, colors: colors);
    final cached = _cache[key];
    if (cached != null) return cached;
    final future = _render(source, kind: kind, colors: colors);
    _cache[key] = future;
    // Failed renders are not cached so a later rebuild can retry.
    future.then((result) {
      if (!result.isSuccess) {
        _cache.remove(key);
      } else if (_cache.containsKey(key)) {
        _completed[key] = result;
      }
    });
    if (_cache.length > 48) {
      final oldest = _cache.keys.first;
      _cache.remove(oldest);
      _completed.remove(oldest);
    }
    return future;
  }

  /// A finished render, available synchronously so a diagram that scrolls
  /// back into view is laid out at its final size on the first frame.
  DiagramRenderResult? completed(
    String source, {
    required DiagramKind kind,
    required DiagramColors colors,
  }) => _completed[_key(source, kind: kind, colors: colors)];

  static String _key(
    String source, {
    required DiagramKind kind,
    required DiagramColors colors,
  }) => '${kind.name}|${colors.dark}|${colors.surface}|${colors.ink}|$source';

  /// Re-rasterizes a rendered diagram at export quality.
  Future<DiagramRenderResult> rasterize(
    String svg, {
    double scale = 4,
    int maxEdge = 8192,
  }) {
    return _send('rasterizeDiagram', {
      'svg': svg,
      'scale': scale,
      'maxEdge': maxEdge,
    });
  }

  Future<DiagramRenderResult> _render(
    String source, {
    required DiagramKind kind,
    required DiagramColors colors,
  }) {
    return _send('renderDiagram', {
      'kind': kind.name,
      'source': source,
      'dark': colors.dark,
      'surface': colors.surface,
      'ink': colors.ink,
    });
  }

  Future<DiagramRenderResult> _send(
    String function,
    Map<String, Object?> payload,
  ) async {
    _initialize();
    try {
      await _ready.future.timeout(_readyTimeout);
    } on TimeoutException {
      return DiagramRenderResult.failure(tr('圖表功能載入太久，請稍後再試'));
    }
    if (_initializationError case final error?) {
      return DiagramRenderResult.failure(error);
    }
    final id = ++_nextId;
    final completer = Completer<DiagramRenderResult>();
    _pending[id] = completer;
    final request = jsonEncode({'id': id, ...payload});
    try {
      await _controller.runJavaScript('$function(${jsonEncode(request)})');
      return await completer.future.timeout(_renderTimeout);
    } on TimeoutException {
      return DiagramRenderResult.failure(tr('圖表產生太久，請稍後再試'));
    } catch (error) {
      return DiagramRenderResult.failure('$error');
    } finally {
      _pending.remove(id);
    }
  }

  void _initialize() {
    if (_initialized) return;
    _initialized = true;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            await _controller.runJavaScript('''
              DiagramBridge.postMessage(JSON.stringify({
                type: 'diagnostic',
                mermaid: typeof mermaid,
                purifier: typeof DOMPurify,
                renderer: typeof renderDiagram
              }));
            ''');
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && !_ready.isCompleted) {
              _initializationError = tr('圖表功能無法啟動');
              _ready.complete();
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final allowed =
                uri?.scheme == 'file' ||
                uri?.host == 'appassets.androidplatform.net';
            return allowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'DiagramBridge',
        onMessageReceived: (message) => _handle(message.message),
      )
      ..loadFlutterAsset('assets/diagram/renderer.html');
  }

  void _handle(String raw) {
    final message = jsonDecode(raw) as Map<String, dynamic>;
    if (message['type'] == 'ready') {
      if (!_ready.isCompleted) _ready.complete();
      return;
    }
    if (message['type'] == 'diagnostic') {
      final valid =
          message['mermaid'] == 'object' &&
          message['purifier'] == 'function' &&
          message['renderer'] == 'function';
      if (!valid && !_ready.isCompleted) {
        _initializationError =
            '${tr('圖表功能無法啟動')}'
            '（mermaid=${message['mermaid']}、DOMPurify=${message['purifier']}）';
      }
      if (!_ready.isCompleted) _ready.complete();
      return;
    }
    final id = message['id'] as int?;
    final completer = id == null ? null : _pending.remove(id);
    if (completer == null || completer.isCompleted) return;
    if (message['type'] == 'rendered') {
      completer.complete(
        DiagramRenderResult.success(
          message['svg'] as String,
          base64Decode(message['png'] as String),
          Size(
            (message['width'] as num).toDouble(),
            (message['height'] as num).toDouble(),
          ),
        ),
      );
    } else {
      completer.complete(
        DiagramRenderResult.failure(
          (message['message'] as String?) ?? tr('圖表發生未知問題'),
        ),
      );
    }
  }
}

/// Hosts the hidden renderer WebView; it must stay in the widget tree.
class DiagramRenderHost extends StatelessWidget {
  const DiagramRenderHost({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: 1,
        child: WebViewWidget(
          controller: DiagramRenderService.instance.controller,
        ),
      ),
    );
  }
}
