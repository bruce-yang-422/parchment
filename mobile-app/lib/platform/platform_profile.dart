import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformProfile {
  const PlatformProfile._({
    required this.pagePadding,
    required this.readerPadding,
  });

  final EdgeInsets pagePadding;
  final EdgeInsets readerPadding;

  static PlatformProfile current() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => const PlatformProfile._(
        pagePadding: EdgeInsets.symmetric(horizontal: 18),
        readerPadding: EdgeInsets.fromLTRB(20, 20, 20, 48),
      ),
      _ => const PlatformProfile._(
        pagePadding: EdgeInsets.symmetric(horizontal: 16),
        readerPadding: EdgeInsets.fromLTRB(18, 18, 18, 40),
      ),
    };
  }
}
