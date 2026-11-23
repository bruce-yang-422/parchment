import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:parchment_mobile/ui/reader/reader_screen.dart';

Uint8List _text(String value) => Uint8List.fromList(utf8.encode(value));

void main() {
  test('SVG 文件判定為 SVG', () {
    expect(
      looksLikeSvg(_text('<svg xmlns="http://www.w3.org/2000/svg"/>')),
      isTrue,
    );
    expect(
      looksLikeSvg(_text('﻿<?xml version="1.0"?>\n<!-- logo -->\n<svg/>')),
      isTrue,
    );
  });

  test('中繼資料內含 SVG 的 PNG 不會被當成 SVG', () {
    final png = File(
      '../image/parchment-logo-transparent.png',
    ).readAsBytesSync();
    expect(
      utf8.decode(png.take(1024).toList(), allowMalformed: true),
      contains('<svg'),
    );
    expect(looksLikeSvg(png), isFalse);
  });

  test('一般文字不是 SVG', () {
    expect(looksLikeSvg(_text('hello <svg> inside text')), isFalse);
  });

  test('下載圖片時以 App 名稱表明身分', () {
    expect(
      imageUserAgent,
      matches(
        RegExp(
          r'^Parchment/\d+\.\d+\.\d+ \(\w+; \+https://parchment\.stack-base\.com/\)$',
        ),
      ),
    );
  });
}
