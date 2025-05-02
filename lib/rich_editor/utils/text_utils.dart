import 'package:flutter/material.dart' as flutter;
import '../model/document.dart' as editor;

/// 텍스트 관련 유틸리티 클래스
class TextUtils {
  /// 스타일을 적용한 TextSpan 생성
  static flutter.TextSpan buildStyledTextSpan(
    String text,
    List<editor.TextStyle> styles,
    List<editor.TextRange> ranges, {
    flutter.TextStyle? defaultStyle,
  }) {
    if (text.isEmpty) {
      return flutter.TextSpan(text: text, style: defaultStyle);
    }

    if (ranges.isEmpty || styles.isEmpty) {
      return flutter.TextSpan(text: text, style: defaultStyle);
    }

    // 스타일이 적용된 범위가 없는 경우 전체 텍스트에 기본 스타일 적용
    if (ranges.isEmpty) {
      return flutter.TextSpan(text: text, style: defaultStyle);
    }

    // 범위 순서로 정렬 (시작 위치 기준)
    final sortedRanges = List<editor.TextRange>.from(ranges)
      ..sort((a, b) => a.start.compareTo(b.start));

    // 스팬 목록 생성
    final List<flutter.TextSpan> spans = [];
    int currentPosition = 0;

    for (var i = 0; i < sortedRanges.length; i++) {
      final range = sortedRanges[i];
      final style = styles[i % styles.length]; // 스타일 인덱스가 범위를 벗어나지 않도록 처리

      // 현재 위치가 범위 시작 이전인 경우, 스타일 없는 텍스트 추가
      if (currentPosition < range.start) {
        spans.add(
          flutter.TextSpan(
            text: text.substring(currentPosition, range.start),
            style: defaultStyle,
          ),
        );
      }

      // 스타일이 적용된 텍스트 추가
      spans.add(
        flutter.TextSpan(
          text: text.substring(range.start, range.end),
          style: style.toFlutterStyle(
            defaultStyle ?? const flutter.TextStyle(),
          ),
        ),
      );

      currentPosition = range.end;
    }

    // 마지막 범위 이후의 텍스트가 있다면 추가
    if (currentPosition < text.length) {
      spans.add(
        flutter.TextSpan(
          text: text.substring(currentPosition),
          style: defaultStyle,
        ),
      );
    }

    return flutter.TextSpan(children: spans);
  }

  /// 블록 타입에 따른 기본 텍스트 스타일 반환
  static flutter.TextStyle getDefaultStyleForBlock(editor.BlockType type) {
    switch (type) {
      case editor.BlockType.heading1:
        return flutter.TextStyle(
          fontSize: 24,
          fontWeight: flutter.FontWeight.bold,
          color: flutter.Colors.white,
          height: 1.5,
        );
      case editor.BlockType.heading2:
        return flutter.TextStyle(
          fontSize: 20,
          fontWeight: flutter.FontWeight.bold,
          color: flutter.Colors.white,
          height: 1.5,
        );
      case editor.BlockType.heading3:
        return flutter.TextStyle(
          fontSize: 18,
          fontWeight: flutter.FontWeight.bold,
          color: flutter.Colors.white,
          height: 1.5,
        );
      case editor.BlockType.paragraph:
      default:
        return flutter.TextStyle(
          fontSize: 16,
          color: flutter.Colors.white,
          height: 1.5,
        );
    }
  }

  /// 블록 타입에 따른 접두사 텍스트 반환
  static String getPrefixForBlock(editor.BlockType type, {int index = 0}) {
    switch (type) {
      case editor.BlockType.bulletList:
        return '• ';
      case editor.BlockType.numberedList:
        return '${index + 1}. ';
      case editor.BlockType.checkList:
        return '☐ ';
      default:
        return '';
    }
  }

  /// 텍스트에서 마크다운 형식 파싱하여 블록 타입 결정
  static editor.BlockType parseBlockTypeFromText(String text) {
    if (text.isEmpty) return editor.BlockType.paragraph;

    // 텍스트 앞부분 확인
    final trimmed = text.trim();

    if (trimmed.startsWith('# ')) {
      return editor.BlockType.heading1;
    } else if (trimmed.startsWith('## ')) {
      return editor.BlockType.heading2;
    } else if (trimmed.startsWith('### ')) {
      return editor.BlockType.heading3;
    } else if (trimmed.startsWith('* ') ||
        trimmed.startsWith('- ') ||
        trimmed.startsWith('• ')) {
      return editor.BlockType.bulletList;
    } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
      return editor.BlockType.numberedList;
    } else if (trimmed.startsWith('[ ] ') ||
        trimmed.startsWith('[]') ||
        trimmed.startsWith('☐ ') ||
        trimmed.startsWith('☑ ')) {
      return editor.BlockType.checkList;
    } else if (trimmed == '---' || trimmed == '___' || trimmed == '***') {
      return editor.BlockType.divider;
    }

    return editor.BlockType.paragraph;
  }

  /// 마크다운 접두사를 제거한 텍스트 반환
  static String removeMarkdownPrefix(String text, editor.BlockType type) {
    final trimmed = text.trim();

    switch (type) {
      case editor.BlockType.heading1:
        return trimmed.startsWith('# ') ? trimmed.substring(2) : text;
      case editor.BlockType.heading2:
        return trimmed.startsWith('## ') ? trimmed.substring(3) : text;
      case editor.BlockType.heading3:
        return trimmed.startsWith('### ') ? trimmed.substring(4) : text;
      case editor.BlockType.bulletList:
        if (trimmed.startsWith('* ')) return trimmed.substring(2);
        if (trimmed.startsWith('- ')) return trimmed.substring(2);
        if (trimmed.startsWith('• ')) return trimmed.substring(2);
        return text;
      case editor.BlockType.numberedList:
        final match = RegExp(r'^\d+\.\s').firstMatch(trimmed);
        return match != null ? trimmed.substring(match.end) : text;
      case editor.BlockType.checkList:
        if (trimmed.startsWith('[ ] ')) return trimmed.substring(4);
        if (trimmed.startsWith('[]')) return trimmed.substring(2);
        if (trimmed.startsWith('☐ ')) return trimmed.substring(2);
        if (trimmed.startsWith('☑ ')) return trimmed.substring(2);
        return text;
      default:
        return text;
    }
  }
}
