import 'package:flutter/material.dart' as flutter;
import '../model/document.dart' as editor;
import '../model/editor_state.dart';
import '../utils/image_utils.dart';
import '../utils/text_input_utils.dart';

/// 에디터 툴바 위젯
class EditorToolbar extends flutter.StatelessWidget {
  /// 에디터 상태
  final EditorState editorState;

  const EditorToolbar({flutter.Key? key, required this.editorState})
    : super(key: key);

  @override
  flutter.Widget build(flutter.BuildContext context) {
    return flutter.Container(
      decoration: flutter.BoxDecoration(
        color: flutter.Color(0xFF363636),
        borderRadius: flutter.BorderRadius.circular(8),
        boxShadow: [
          flutter.BoxShadow(
            color: flutter.Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: flutter.Offset(0, 2),
          ),
        ],
      ),
      padding: flutter.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: flutter.SingleChildScrollView(
        scrollDirection: flutter.Axis.horizontal,
        child: flutter.Row(
          children: [
            // 블록 타입 선택 드롭다운
            _buildBlockTypeDropdown(),

            // 구분선
            _buildDivider(),

            // 텍스트 스타일 버튼들
            _buildTextStyleButtons(),

            // 구분선
            _buildDivider(),

            // 정렬 버튼들
            _buildAlignmentButtons(),

            // 구분선
            _buildDivider(),

            // 미디어 삽입 버튼들
            _buildMediaButtons(context),
          ],
        ),
      ),
    );
  }

  /// 블록 타입 선택 드롭다운
  flutter.Widget _buildBlockTypeDropdown() {
    String blockTypeText;
    flutter.IconData blockTypeIcon;

    switch (editorState.currentBlock.type) {
      case editor.BlockType.heading1:
        blockTypeText = 'H1';
        blockTypeIcon = flutter.Icons.title;
        break;
      case editor.BlockType.heading2:
        blockTypeText = 'H2';
        blockTypeIcon = flutter.Icons.title;
        break;
      case editor.BlockType.heading3:
        blockTypeText = 'H3';
        blockTypeIcon = flutter.Icons.title;
        break;
      case editor.BlockType.bulletList:
        blockTypeText = '글머리 기호';
        blockTypeIcon = flutter.Icons.format_list_bulleted;
        break;
      case editor.BlockType.numberedList:
        blockTypeText = '번호 매기기';
        blockTypeIcon = flutter.Icons.format_list_numbered;
        break;
      case editor.BlockType.checkList:
        blockTypeText = '체크리스트';
        blockTypeIcon = flutter.Icons.check_box;
        break;
      case editor.BlockType.paragraph:
      default:
        blockTypeText = '일반 텍스트';
        blockTypeIcon = flutter.Icons.text_fields;
        break;
    }

    return flutter.PopupMenuButton<editor.BlockType>(
      tooltip: '블록 타입',
      child: flutter.Container(
        padding: flutter.EdgeInsets.symmetric(horizontal: 8),
        child: flutter.Row(
          children: [
            flutter.Icon(blockTypeIcon, color: flutter.Colors.white, size: 18),
            flutter.SizedBox(width: 4),
            flutter.Text(
              blockTypeText,
              style: flutter.TextStyle(
                color: flutter.Colors.white,
                fontSize: 14,
              ),
            ),
            flutter.Icon(
              flutter.Icons.arrow_drop_down,
              color: flutter.Colors.white,
            ),
          ],
        ),
      ),
      onSelected: (editor.BlockType type) {
        editorState.changeBlockType(editorState.currentBlockIndex, type);
      },
      itemBuilder:
          (context) => [
            _buildPopupMenuItem(
              'TT',
              '일반 텍스트',
              editor.BlockType.paragraph,
              flutter.Icons.text_fields,
            ),
            _buildPopupMenuItem(
              'H1',
              '큰 제목',
              editor.BlockType.heading1,
              flutter.Icons.title,
            ),
            _buildPopupMenuItem(
              'H2',
              '중간 제목',
              editor.BlockType.heading2,
              flutter.Icons.title,
            ),
            _buildPopupMenuItem(
              'H3',
              '작은 제목',
              editor.BlockType.heading3,
              flutter.Icons.title,
            ),
            _buildPopupMenuItem(
              '•',
              '글머리 기호 목록',
              editor.BlockType.bulletList,
              flutter.Icons.format_list_bulleted,
            ),
            _buildPopupMenuItem(
              '1.',
              '번호 매기기 목록',
              editor.BlockType.numberedList,
              flutter.Icons.format_list_numbered,
            ),
            _buildPopupMenuItem(
              '☑',
              '체크리스트',
              editor.BlockType.checkList,
              flutter.Icons.check_box,
            ),
            _buildPopupMenuItem(
              '---',
              '구분선',
              editor.BlockType.divider,
              flutter.Icons.horizontal_rule,
            ),
          ],
    );
  }

  /// 팝업 메뉴 아이템
  flutter.PopupMenuItem<editor.BlockType> _buildPopupMenuItem(
    String prefix,
    String title,
    editor.BlockType type,
    flutter.IconData icon,
  ) {
    return flutter.PopupMenuItem<editor.BlockType>(
      value: type,
      child: flutter.Row(
        children: [
          flutter.Icon(icon, size: 18, color: flutter.Colors.white),
          flutter.SizedBox(width: 8),
          flutter.Text(
            title,
            style: flutter.TextStyle(color: flutter.Colors.white),
          ),
        ],
      ),
    );
  }

  /// 텍스트 스타일 버튼들
  flutter.Widget _buildTextStyleButtons() {
    return flutter.Row(
      children: [
        // 굵게
        _buildToolbarButton(
          tooltip: '굵게',
          icon: flutter.Icons.format_bold,
          isActive: editorState.currentStyle.bold,
          onPressed: () {
            final newStyle = editor.TextStyle(
              bold: !editorState.currentStyle.bold,
            );
            editorState.applyStyleToSelection(newStyle);
          },
        ),

        // 기울임
        _buildToolbarButton(
          tooltip: '기울임',
          icon: flutter.Icons.format_italic,
          isActive: editorState.currentStyle.italic,
          onPressed: () {
            final newStyle = editor.TextStyle(
              italic: !editorState.currentStyle.italic,
            );
            editorState.applyStyleToSelection(newStyle);
          },
        ),

        // 밑줄
        _buildToolbarButton(
          tooltip: '밑줄',
          icon: flutter.Icons.format_underlined,
          isActive: editorState.currentStyle.underline,
          onPressed: () {
            final newStyle = editor.TextStyle(
              underline: !editorState.currentStyle.underline,
            );
            editorState.applyStyleToSelection(newStyle);
          },
        ),

        // 취소선
        _buildToolbarButton(
          tooltip: '취소선',
          icon: flutter.Icons.format_strikethrough,
          isActive: false, // 현재 구현되지 않음
          onPressed: () {
            // 취소선 스타일 적용 로직
          },
        ),

        // 코드
        _buildToolbarButton(
          tooltip: '코드',
          icon: flutter.Icons.code,
          isActive: false, // 현재 구현되지 않음
          onPressed: () {
            // 코드 스타일 적용 로직
          },
        ),
      ],
    );
  }

  /// 정렬 버튼들
  flutter.Widget _buildAlignmentButtons() {
    final flutter.TextAlign currentAlign = editorState.currentStyle.textAlign;

    return flutter.Row(
      children: [
        // 왼쪽 정렬
        _buildToolbarButton(
          tooltip: '왼쪽 정렬',
          icon: flutter.Icons.format_align_left,
          isActive: currentAlign == flutter.TextAlign.left,
          onPressed: () {
            final newStyle = editor.TextStyle(
              textAlign: flutter.TextAlign.left,
            );
            editorState.updateCurrentStyle(newStyle);
          },
        ),

        // 가운데 정렬
        _buildToolbarButton(
          tooltip: '가운데 정렬',
          icon: flutter.Icons.format_align_center,
          isActive: currentAlign == flutter.TextAlign.center,
          onPressed: () {
            final newStyle = editor.TextStyle(
              textAlign: flutter.TextAlign.center,
            );
            editorState.updateCurrentStyle(newStyle);
          },
        ),

        // 오른쪽 정렬
        _buildToolbarButton(
          tooltip: '오른쪽 정렬',
          icon: flutter.Icons.format_align_right,
          isActive: currentAlign == flutter.TextAlign.right,
          onPressed: () {
            final newStyle = editor.TextStyle(
              textAlign: flutter.TextAlign.right,
            );
            editorState.updateCurrentStyle(newStyle);
          },
        ),

        // 양쪽 정렬
        _buildToolbarButton(
          tooltip: '양쪽 정렬',
          icon: flutter.Icons.format_align_justify,
          isActive: currentAlign == flutter.TextAlign.justify,
          onPressed: () {
            final newStyle = editor.TextStyle(
              textAlign: flutter.TextAlign.justify,
            );
            editorState.updateCurrentStyle(newStyle);
          },
        ),
      ],
    );
  }

  /// 미디어 삽입 버튼들
  flutter.Widget _buildMediaButtons(flutter.BuildContext context) {
    return flutter.Row(
      children: [
        // 이미지 삽입
        _buildToolbarButton(
          tooltip: '이미지 삽입',
          icon: flutter.Icons.image,
          isActive: false,
          onPressed: () async {
            await ImageUtils.pickAndInsertImage(editorState);
          },
        ),

        // 파일 첨부
        _buildToolbarButton(
          tooltip: '파일 첨부',
          icon: flutter.Icons.attach_file,
          isActive: false,
          onPressed: () {
            // 파일 첨부 로직
          },
        ),

        // 테이블 삽입
        _buildToolbarButton(
          tooltip: '테이블 삽입',
          icon: flutter.Icons.grid_on,
          isActive: false,
          onPressed: () {
            // 테이블 삽입 로직
          },
        ),

        // 링크 삽입
        _buildToolbarButton(
          tooltip: '링크 삽입',
          icon: flutter.Icons.link,
          isActive: false,
          onPressed: () {
            // 링크 삽입 로직
          },
        ),
      ],
    );
  }

  /// 툴바 버튼
  flutter.Widget _buildToolbarButton({
    required String tooltip,
    required flutter.IconData icon,
    required bool isActive,
    required flutter.VoidCallback onPressed,
  }) {
    return flutter.Tooltip(
      message: tooltip,
      child: flutter.InkWell(
        borderRadius: flutter.BorderRadius.circular(4),
        onTap: onPressed,
        child: flutter.Container(
          padding: flutter.EdgeInsets.all(8),
          decoration: flutter.BoxDecoration(
            color: flutter.Colors.transparent,
            borderRadius: flutter.BorderRadius.circular(4),
          ),
          child: flutter.Icon(
            icon,
            color: isActive ? flutter.Colors.blue : flutter.Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// 구분선
  flutter.Widget _buildDivider() {
    return flutter.Container(
      height: 24,
      width: 1,
      color: flutter.Colors.grey.shade700,
      margin: flutter.EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
