import 'package:flutter/material.dart';
import '../model/document.dart' as editor;

/// 스타일 관련 유틸리티 클래스
class StyleUtils {
  /// 블록 타입에 맞는 기본 텍스트 스타일 반환
  static TextStyle getDefaultStyleForBlockType(editor.BlockType type) {
    switch (type) {
      case editor.BlockType.heading1:
        return const TextStyle(
          color: Colors.white,
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
          height: 1.4,
        );
      case editor.BlockType.heading2:
        return const TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          height: 1.4,
        );
      case editor.BlockType.heading3:
        return const TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          height: 1.4,
        );
      case editor.BlockType.bulletList:
      case editor.BlockType.numberedList:
      case editor.BlockType.checkList:
        return const TextStyle(
          color: Colors.white,
          fontSize: 16.0,
          height: 1.5,
        );
      case editor.BlockType.image:
        return const TextStyle(
          color: Colors.grey,
          fontSize: 14.0,
          fontStyle: FontStyle.italic,
        );
      case editor.BlockType.paragraph:
      default:
        return const TextStyle(
          color: Colors.white,
          fontSize: 16.0,
          height: 1.5,
        );
    }
  }

  /// 에디터에서 사용 가능한 폰트 목록
  static List<String> getAvailableFonts() {
    return [
      'Default',
      'Roboto',
      'Lato',
      'Open Sans',
      'Montserrat',
      'Source Sans Pro',
    ];
  }

  /// 에디터에서 사용 가능한 색상 목록
  static List<Color> getAvailableColors() {
    return [
      Colors.white,
      Colors.black,
      Colors.grey,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
    ];
  }

  /// 색상을 HEX 코드로 변환
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  /// HEX 코드를 색상으로 변환
  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  /// 블록의 텍스트를 스타일과 함께 TextSpan으로 변환
  static List<InlineSpan> getStyledSpans(editor.Block block) {
    List<InlineSpan> spans = [];
    String text = block.content;

    // 스타일이 없거나 텍스트가 비어있는 경우
    if (block.styles.isEmpty || text.isEmpty) {
      return [TextSpan(text: text)];
    }

    // 스타일을 시작 위치 기준으로 정렬
    List<editor.TextRange> sortedStyles = List.from(block.styles)
      ..sort((a, b) => a.start.compareTo(b.start));

    int lastEnd = 0;

    for (var styleRange in sortedStyles) {
      // 범위가 유효한지 확인
      if (styleRange.start < 0 ||
          styleRange.end > text.length ||
          styleRange.start >= styleRange.end) {
        continue;
      }

      // 스타일 없는 부분 추가
      if (styleRange.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, styleRange.start)));
      }

      // 스타일 적용된 부분 추가
      spans.add(
        TextSpan(
          text: text.substring(styleRange.start, styleRange.end),
          style: styleRange.style.toFlutterStyle(TextStyle()),
        ),
      );

      lastEnd = styleRange.end;
    }

    // 남은 텍스트 추가
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }
}
