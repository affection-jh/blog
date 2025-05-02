import 'package:flutter/material.dart' as flutter;
import 'package:flutter/services.dart' as services;
import '../model/document.dart' as editor;

/// 텍스트 입력 처리 유틸리티
class TextInputUtils {
  /// 텍스트 선택 위치에 문자 삽입
  static String insertTextAtSelection(
    String text,
    String input,
    flutter.TextSelection selection,
  ) {
    if (selection.isCollapsed) {
      // 커서 위치에 삽입
      return text.substring(0, selection.start) +
          input +
          text.substring(selection.start);
    } else {
      // 선택 영역 대체
      return text.substring(0, selection.start) +
          input +
          text.substring(selection.end);
    }
  }

  /// 텍스트 선택 위치에서 문자 삭제 (백스페이스)
  static String deleteTextBeforeSelection(
    String text,
    flutter.TextSelection selection,
  ) {
    if (selection.isCollapsed && selection.start > 0) {
      // 커서 앞 문자 삭제
      return text.substring(0, selection.start - 1) +
          text.substring(selection.start);
    } else if (!selection.isCollapsed) {
      // 선택 영역 삭제
      return text.substring(0, selection.start) + text.substring(selection.end);
    }
    return text;
  }

  /// 텍스트 선택 위치에서 문자 삭제 (Delete)
  static String deleteTextAfterSelection(
    String text,
    flutter.TextSelection selection,
  ) {
    if (selection.isCollapsed && selection.start < text.length) {
      // 커서 뒤 문자 삭제
      return text.substring(0, selection.start) +
          text.substring(selection.start + 1);
    } else if (!selection.isCollapsed) {
      // 선택 영역 삭제
      return text.substring(0, selection.start) + text.substring(selection.end);
    }
    return text;
  }

  /// 텍스트 선택 영역에 스타일 적용
  static void applyStyleToText(
    editor.Block block,
    flutter.TextSelection selection,
    editor.TextStyle style,
  ) {
    if (!selection.isValid || selection.isCollapsed) return;

    // 블록에 스타일 적용
    block.applyStyle(selection.start, selection.end, style);
  }

  /// 키 이벤트를 기반으로 새 텍스트 및 선택 영역 계산
  static Map<String, dynamic> processKeyEvent(
    services.RawKeyEvent event,
    String currentText,
    flutter.TextSelection currentSelection,
  ) {
    String newText = currentText;
    flutter.TextSelection newSelection = currentSelection;
    bool handled = false;

    if (event is services.RawKeyDownEvent) {
      if (event.logicalKey == services.LogicalKeyboardKey.backspace) {
        if (currentSelection.isCollapsed && currentSelection.start > 0) {
          newText = deleteTextBeforeSelection(currentText, currentSelection);
          newSelection = flutter.TextSelection.collapsed(
            offset: currentSelection.start - 1,
          );
          handled = true;
        } else if (!currentSelection.isCollapsed) {
          newText = deleteTextBeforeSelection(currentText, currentSelection);
          newSelection = flutter.TextSelection.collapsed(
            offset: currentSelection.start,
          );
          handled = true;
        }
      } else if (event.logicalKey == services.LogicalKeyboardKey.delete) {
        if (currentSelection.isCollapsed &&
            currentSelection.start < currentText.length) {
          newText = deleteTextAfterSelection(currentText, currentSelection);
          newSelection = currentSelection;
          handled = true;
        } else if (!currentSelection.isCollapsed) {
          newText = deleteTextAfterSelection(currentText, currentSelection);
          newSelection = flutter.TextSelection.collapsed(
            offset: currentSelection.start,
          );
          handled = true;
        }
      } else if (event.logicalKey == services.LogicalKeyboardKey.arrowLeft) {
        if (currentSelection.isCollapsed) {
          if (currentSelection.start > 0) {
            newSelection = flutter.TextSelection.collapsed(
              offset: currentSelection.start - 1,
            );
          }
        } else {
          newSelection = flutter.TextSelection.collapsed(
            offset: currentSelection.start,
          );
        }
        handled = true;
      } else if (event.logicalKey == services.LogicalKeyboardKey.arrowRight) {
        if (currentSelection.isCollapsed) {
          if (currentSelection.start < currentText.length) {
            newSelection = flutter.TextSelection.collapsed(
              offset: currentSelection.start + 1,
            );
          }
        } else {
          newSelection = flutter.TextSelection.collapsed(
            offset: currentSelection.end,
          );
        }
        handled = true;
      }
    }

    return {'text': newText, 'selection': newSelection, 'handled': handled};
  }

  /// 키 이벤트에서 문자 추출
  static String? getCharFromKeyEvent(services.RawKeyEvent event) {
    if (event is! services.RawKeyDownEvent) return null;

    // 특수 키 필터링
    if (event.logicalKey == services.LogicalKeyboardKey.backspace ||
        event.logicalKey == services.LogicalKeyboardKey.delete ||
        event.logicalKey == services.LogicalKeyboardKey.tab ||
        event.logicalKey == services.LogicalKeyboardKey.enter ||
        event.logicalKey == services.LogicalKeyboardKey.escape ||
        event.logicalKey == services.LogicalKeyboardKey.shift ||
        event.logicalKey == services.LogicalKeyboardKey.control ||
        event.logicalKey == services.LogicalKeyboardKey.alt ||
        event.logicalKey == services.LogicalKeyboardKey.meta) {
      return null;
    }

    // 기본 문자 매핑
    final character = event.character;
    if (character != null && character.isNotEmpty) {
      return character;
    }

    return null;
  }

  /// 마크다운 텍스트로부터 스타일 추출 (기본 구현)
  static List<Map<String, dynamic>> parseMarkdownStyles(String text) {
    final List<Map<String, dynamic>> styles = [];

    // 굵은 텍스트 (**text** 또는 __text__)
    RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*|__(.*?)__');
    boldRegex.allMatches(text).forEach((match) {
      final String matchedText = match.group(1) ?? match.group(2) ?? '';
      final int start = text.indexOf(match.group(0)!);
      final int end = start + matchedText.length;

      styles.add({
        'range': {'start': start, 'end': end},
        'style': editor.TextStyle(bold: true),
      });
    });

    // 기울임 텍스트 (*text* 또는 _text_)
    RegExp italicRegex = RegExp(r'\*(.*?)\*|_(.*?)_');
    italicRegex.allMatches(text).forEach((match) {
      final String matchedText = match.group(1) ?? match.group(2) ?? '';
      final int start = text.indexOf(match.group(0)!);
      final int end = start + matchedText.length;

      styles.add({
        'range': {'start': start, 'end': end},
        'style': editor.TextStyle(italic: true),
      });
    });

    return styles;
  }
}
