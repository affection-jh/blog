import 'package:flutter/material.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'document.dart' as editor;

/// 에디터의 상태를 관리하는 클래스입니다.
class EditorState extends ChangeNotifier {
  /// 편집 중인 문서
  editor.Document _document;

  /// 현재 선택 영역
  TextSelection _selection = const TextSelection.collapsed(offset: 0);

  /// 현재 포커스
  bool _hasFocus = false;

  /// 현재 커서가 위치한 블록 인덱스
  int _currentBlockIndex = 0;

  /// 현재 적용 중인 스타일
  editor.TextStyle _currentStyle = editor.TextStyle();

  /// UUID 생성기
  final Uuid _uuid = Uuid();

  /// 생성자
  EditorState({editor.Document? document})
    : _document = document ?? editor.Document() {
    // 문서가 비어있으면 기본 단락 추가
    if (_document.blocks.isEmpty) {
      _document.blocks.add(
        editor.Block(
          id: _generateId(),
          type: editor.BlockType.paragraph,
          content: '',
        ),
      );
    }
  }

  /// 현재 문서 반환
  editor.Document get document => _document;

  /// 현재 선택 영역 반환
  TextSelection get selection => _selection;

  /// 현재 포커스 상태 반환
  bool get hasFocus => _hasFocus;

  /// 현재 블록 인덱스 반환
  int get currentBlockIndex => _currentBlockIndex;

  /// 현재 블록 반환
  editor.Block get currentBlock => _document.blocks[_currentBlockIndex];

  /// 현재 스타일 반환
  editor.TextStyle get currentStyle => _currentStyle;

  /// 문서 업데이트
  void updateDocument(editor.Document newDocument) {
    _document = newDocument;
    notifyListeners();
  }

  /// 선택 영역 업데이트
  void updateSelection(TextSelection selection) {
    _selection = selection;
    notifyListeners();
  }

  /// 포커스 상태 업데이트
  void updateFocus(bool hasFocus) {
    _hasFocus = hasFocus;
    notifyListeners();
  }

  /// 현재 블록 인덱스 업데이트
  void updateCurrentBlockIndex(int index) {
    if (index >= 0 && index < _document.blocks.length) {
      _currentBlockIndex = index;
      notifyListeners();
    }
  }

  /// 현재 스타일 업데이트
  void updateCurrentStyle(editor.TextStyle style) {
    _currentStyle = style;
    notifyListeners();
  }

  /// 블록 추가
  void addBlock(editor.Block block) {
    // 블록을 현재 블록 바로 다음에 추가
    if (_currentBlockIndex >= 0 &&
        _currentBlockIndex < _document.blocks.length) {
      _document.blocks.insert(_currentBlockIndex + 1, block);
      // 추가된 블록으로 포커스 이동
      _currentBlockIndex += 1;
    } else {
      // 현재 선택된 블록이 없으면 끝에 추가
      _document.blocks.add(block);
      _currentBlockIndex = _document.blocks.length - 1;
    }

    // 선택 영역 초기화
    _selection = const TextSelection.collapsed(offset: 0);
    notifyListeners();
  }

  /// 블록 삭제
  void removeBlock(int index) {
    if (index >= 0 && index < _document.blocks.length) {
      _document.blocks.removeAt(index);
      // 현재 블록 인덱스 조정
      if (_currentBlockIndex >= _document.blocks.length) {
        _currentBlockIndex = max(0, _document.blocks.length - 1);
      }
      notifyListeners();
    }
  }

  /// 블록 교체
  void replaceBlock(int index, editor.Block newBlock) {
    if (index >= 0 && index < _document.blocks.length) {
      _document.blocks[index] = newBlock;
      notifyListeners();
    }
  }

  /// 블록 내용 업데이트
  void updateBlockContent(int index, String content) {
    if (index >= 0 && index < _document.blocks.length) {
      final block = _document.blocks[index];
      final updatedBlock = block.copyWith(content: content);
      _document.blocks[index] = updatedBlock;
      notifyListeners();
    }
  }

  /// 블록 타입 변경
  void changeBlockType(int index, editor.BlockType type) {
    if (index >= 0 && index < _document.blocks.length) {
      final block = _document.blocks[index];
      final updatedBlock = block.copyWith(
        type: type,
        checked: type == editor.BlockType.checkList ? false : null,
      );
      _document.blocks[index] = updatedBlock;
      notifyListeners();
    }
  }

  /// 블록에 스타일 적용
  void applyStyleToBlock(
    int blockIndex,
    editor.TextStyle style,
    int start,
    int end,
  ) {
    if (blockIndex >= 0 && blockIndex < _document.blocks.length) {
      final block = _document.blocks[blockIndex];

      // 블록에 스타일 적용
      block.applyStyle(start, end, style);

      notifyListeners();
    }
  }

  /// 선택 영역에 스타일 적용
  void applyStyleToSelection(editor.TextStyle style) {
    if (_selection.isValid && !_selection.isCollapsed) {
      applyStyleToBlock(
        _currentBlockIndex,
        style,
        _selection.start,
        _selection.end,
      );
    }
  }

  /// 체크리스트 상태 토글
  void toggleCheckList(int index) {
    if (index >= 0 && index < _document.blocks.length) {
      final block = _document.blocks[index];
      if (block.type == editor.BlockType.checkList) {
        final updatedBlock = block.copyWith(checked: !(block.checked ?? false));
        _document.blocks[index] = updatedBlock;
        notifyListeners();
      }
    }
  }

  /// 블록 ID 생성
  String _generateId() {
    return _uuid.v4();
  }

  /// 문자열을 볼드체로 설정
  void toggleBold() {
    if (_selection.isValid && !_selection.isCollapsed) {
      final bool isBold = _currentStyle.bold;
      final newStyle = _currentStyle.copyWith(bold: !isBold);
      applyStyleToSelection(newStyle);
      updateCurrentStyle(newStyle);
    }
  }

  /// 문자열을 이탤릭체로 설정
  void toggleItalic() {
    if (_selection.isValid && !_selection.isCollapsed) {
      final bool isItalic = _currentStyle.italic;
      final newStyle = _currentStyle.copyWith(italic: !isItalic);
      applyStyleToSelection(newStyle);
      updateCurrentStyle(newStyle);
    }
  }

  /// 문자열에 밑줄 설정
  void toggleUnderline() {
    if (_selection.isValid && !_selection.isCollapsed) {
      final bool isUnderline = _currentStyle.underline;
      final newStyle = _currentStyle.copyWith(underline: !isUnderline);
      applyStyleToSelection(newStyle);
      updateCurrentStyle(newStyle);
    }
  }

  /// 문자열에 색상 적용
  void applyColor(String colorHex) {
    if (_selection.isValid && !_selection.isCollapsed) {
      final newStyle = _currentStyle.copyWith(color: colorHex);
      applyStyleToSelection(newStyle);
      updateCurrentStyle(newStyle);
    }
  }

  /// 문자열에 링크 적용
  void applyLink(String url) {
    if (_selection.isValid && !_selection.isCollapsed) {
      final newStyle = _currentStyle.copyWith(link: url);
      applyStyleToSelection(newStyle);
      updateCurrentStyle(newStyle);
    }
  }

  /// 문자열에 폰트 적용
  void applyFontFamily(String fontFamily) {
    if (_selection.isValid && !_selection.isCollapsed) {
      final newStyle = _currentStyle.copyWith(fontFamily: fontFamily);
      applyStyleToSelection(newStyle);
      updateCurrentStyle(newStyle);
    }
  }
}
