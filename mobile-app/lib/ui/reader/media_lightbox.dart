import 'package:flutter/material.dart';

import '../../core/l10n/tr.dart';

/// Fits the image initially and exposes its current pinch-zoom scale.
class ZoomableLightboxImage extends StatefulWidget {
  const ZoomableLightboxImage({super.key, required this.image});

  final Widget image;

  @override
  State<ZoomableLightboxImage> createState() => _ZoomableLightboxImageState();
}

class _ZoomableLightboxImageState extends State<ZoomableLightboxImage> {
  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: 0.8,
            maxScale: 8,
            child: SizedBox.expand(child: Center(child: widget.image)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<Matrix4>(
                valueListenable: _transform,
                builder: (context, matrix, _) {
                  final percent = (matrix.getMaxScaleOnAxis() * 100).round();
                  return Text('$percent%');
                },
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: () => _transform.value = Matrix4.identity(),
                icon: const Icon(Icons.fit_screen_outlined),
                label: Text(tr('符合螢幕')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-screen controls shared by images and vector diagrams.
class MediaLightbox extends StatefulWidget {
  const MediaLightbox({
    super.key,
    required this.background,
    required this.content,
    required this.onSave,
  });

  final Color background;
  final Widget content;
  final Future<bool> Function(VoidCallback beginSaving) onSave;

  @override
  State<MediaLightbox> createState() => _MediaLightboxState();
}

class _MediaLightboxState extends State<MediaLightbox> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  bool _saving = false;
  bool _saveInProgress = false;

  Future<void> _save() async {
    if (_saveInProgress) return;
    _saveInProgress = true;
    try {
      if (await widget.onSave(() {
            if (mounted) setState(() => _saving = true);
          }) &&
          mounted) {
        _notify(tr('已儲存圖片'));
      }
    } catch (_) {
      if (mounted) _notify(tr('圖片儲存失敗，請再試一次'));
    } finally {
      _saveInProgress = false;
      if (mounted && _saving) setState(() => _saving = false);
    }
  }

  void _notify(String message) {
    _messenger.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: widget.background,
      child: ScaffoldMessenger(
        key: _messenger,
        child: Scaffold(
          backgroundColor: widget.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton.filledTonal(
                        tooltip: tr('儲存成圖片'),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: tr('關閉'),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(child: widget.content),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
