import 'package:flutter/material.dart' as flutter;
import 'dart:convert';

/// 문서 내 블록 타입 정의
enum BlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  bulletList,
  numberedList,
  checkList,
  image,
  divider,
}

/// 문서의 텍스트 스타일 정보
class TextStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final String? color;
  final String? fontFamily;
  final String? link;
  final flutter.TextAlign textAlign;
  final double? fontSize;

  TextStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.color,
    this.fontFamily,
    this.link,
    this.textAlign = flutter.TextAlign.left,
    this.fontSize,
  });

  /// 스타일 복사 생성자
  TextStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    String? color,
    String? fontFamily,
    String? link,
    flutter.TextAlign? textAlign,
    double? fontSize,
  }) {
    return TextStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      color: color ?? this.color,
      fontFamily: fontFamily ?? this.fontFamily,
      link: link ?? this.link,
      textAlign: textAlign ?? this.textAlign,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  /// Flutter TextStyle로 변환
  flutter.TextStyle toFlutterStyle(flutter.TextStyle baseStyle) {
    flutter.TextStyle style = baseStyle;

    if (bold) style = style.copyWith(fontWeight: flutter.FontWeight.bold);
    if (italic) style = style.copyWith(fontStyle: flutter.FontStyle.italic);
    if (underline)
      style = style.copyWith(decoration: flutter.TextDecoration.underline);
    if (color != null) {
      try {
        final colorValue = int.parse(color!.replaceAll('#', ''), radix: 16);
        style = style.copyWith(color: flutter.Color(colorValue | 0xFF000000));
      } catch (e) {
        // 색상 파싱 오류 무시
      }
    }
    if (fontFamily != null) style = style.copyWith(fontFamily: fontFamily);
    if (fontSize != null) style = style.copyWith(fontSize: fontSize);

    return style;
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'bold': bold,
      'italic': italic,
      'underline': underline,
      'textAlign': textAlign.index,
      if (color != null) 'color': color,
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (link != null) 'link': link,
      if (fontSize != null) 'fontSize': fontSize,
    };
  }

  /// JSON에서 생성
  factory TextStyle.fromJson(Map<String, dynamic> json) {
    return TextStyle(
      bold: json['bold'] ?? false,
      italic: json['italic'] ?? false,
      underline: json['underline'] ?? false,
      color: json['color'],
      fontFamily: json['fontFamily'],
      link: json['link'],
      textAlign:
          json['textAlign'] != null
              ? flutter.TextAlign.values[json['textAlign']]
              : flutter.TextAlign.left,
      fontSize: json['fontSize'],
    );
  }
}

/// 문서의 텍스트 범위
class TextRange {
  final int start;
  final int end;
  final TextStyle style;

  TextRange({required this.start, required this.end, required this.style});

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {'start': start, 'end': end, 'style': style.toJson()};
  }

  /// JSON에서 생성
  factory TextRange.fromJson(Map<String, dynamic> json) {
    return TextRange(
      start: json['start'],
      end: json['end'],
      style: TextStyle.fromJson(json['style']),
    );
  }
}

/// 블록 모델 - 각 줄이나 단락을 표현
class Block {
  /// 블록 고유 ID
  final String id;

  /// 블록 타입
  BlockType type;

  /// 블록 내 텍스트 내용 (이미지 등에서는 빈 값)
  String content;

  /// 텍스트 스타일 적용 범위
  List<TextRange> styles;

  /// 이미지 블록의 경우 이미지 경로
  String? imagePath;

  /// 체크리스트 블록의 경우 체크 여부
  bool? checked;

  Block({
    required this.id,
    required this.type,
    this.content = '',
    List<TextRange>? styles,
    this.imagePath,
    this.checked,
  }) : styles = styles ?? [];

  /// 블록 복사본 생성
  Block copyWith({
    String? id,
    BlockType? type,
    String? content,
    List<TextRange>? styles,
    String? imagePath,
    bool? checked,
  }) {
    return Block(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      styles: styles ?? List.from(this.styles),
      imagePath: imagePath ?? this.imagePath,
      checked: checked ?? this.checked,
    );
  }

  /// 텍스트 선택 영역에 스타일 적용
  void applyStyle(int start, int end, TextStyle newStyle) {
    if (start >= end || start < 0 || end > content.length) return;

    // 적용 범위와 겹치는 모든 스타일 제거
    styles.removeWhere(
      (range) =>
          (range.start <= start && range.end > start) ||
          (range.start < end && range.end >= end) ||
          (start <= range.start && end > range.start),
    );

    // 새 스타일 추가
    styles.add(TextRange(start: start, end: end, style: newStyle));

    // 스타일을 시작 위치 기준으로 정렬
    styles.sort((a, b) => a.start.compareTo(b.start));
  }

  /// 특정 위치의 스타일 가져오기
  TextStyle getStyleAt(int offset) {
    if (offset < 0 || offset >= content.length) {
      return TextStyle();
    }

    // 해당 위치를 포함하는 스타일 찾기
    for (final range in styles) {
      if (offset >= range.start && offset < range.end) {
        return range.style;
      }
    }

    return TextStyle();
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'content': content,
      'styles': styles.map((style) => style.toJson()).toList(),
      if (imagePath != null) 'imagePath': imagePath,
      if (checked != null) 'checked': checked,
    };
  }

  /// JSON에서 생성
  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'],
      type: _parseBlockType(json['type']),
      content: json['content'] ?? '',
      styles:
          (json['styles'] as List?)
              ?.map((item) => TextRange.fromJson(item))
              .toList() ??
          [],
      imagePath: json['imagePath'],
      checked: json['checked'],
    );
  }

  /// 문자열에서 블록 타입 파싱
  static BlockType _parseBlockType(String typeStr) {
    return BlockType.values.firstWhere(
      (type) => type.toString() == typeStr,
      orElse: () => BlockType.paragraph,
    );
  }
}

/// 문서 클래스
class Document {
  /// 문서에 포함된 블록 목록
  List<Block> blocks;

  /// 문서 제목
  String title;

  Document({List<Block>? blocks, this.title = '새 페이지'}) : blocks = blocks ?? [];

  /// 문서 복사 생성자
  Document copyWith({List<Block>? blocks, String? title}) {
    return Document(
      blocks: blocks ?? List.from(this.blocks),
      title: title ?? this.title,
    );
  }

  /// 새 블록 추가
  void addBlock(Block block) {
    blocks.add(block);
  }

  /// 블록 삭제
  void removeBlock(String id) {
    blocks.removeWhere((block) => block.id == id);
  }

  /// 블록 업데이트
  void updateBlock(String id, Block newBlock) {
    final index = blocks.indexWhere((block) => block.id == id);
    if (index != -1) {
      blocks[index] = newBlock;
    }
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'blocks': blocks.map((block) => block.toJson()).toList(),
    };
  }

  /// JSON 문자열로 변환
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// JSON에서 생성
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      title: json['title'] ?? '새 페이지',
      blocks:
          (json['blocks'] as List?)
              ?.map((item) => Block.fromJson(item))
              .toList() ??
          [],
    );
  }

  /// JSON 문자열에서 생성
  factory Document.fromJsonString(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    return Document.fromJson(data);
  }
}
