import 'package:flutter/material.dart';
import '../model/document.dart' as editor;
import '../model/editor_state.dart';
import '../utils/style_utils.dart';
import 'custom_text_editor.dart';
import 'package:provider/provider.dart';
import 'dart:io';

/// 블록 렌더링 위젯
class BlockRenderer extends StatefulWidget {
  /// 렌더링할 블록
  final editor.Block block;

  /// 블록 인덱스
  final int index;

  /// 읽기 전용 모드
  final bool readOnly;

  /// 현재 선택된 블록인지 여부
  final bool isSelected;

  /// 블록 내용 변경 콜백
  final Function(String) onTextChanged;

  /// 포커스 변경 콜백
  final Function(bool) onFocusChanged;

  /// 선택 영역 변경 콜백
  final Function(TextSelection)? onSelectionChanged;

  /// 새 블록 추가 콜백
  final Function()? onAddBlock;

  const BlockRenderer({
    Key? key,
    required this.block,
    required this.index,
    required this.readOnly,
    required this.isSelected,
    required this.onTextChanged,
    required this.onFocusChanged,
    this.onSelectionChanged,
    this.onAddBlock,
  }) : super(key: key);

  @override
  _BlockRendererState createState() => _BlockRendererState();
}

class _BlockRendererState extends State<BlockRenderer> {
  /// 포커스 노드
  late FocusNode _focusNode;

  /// 마우스 호버 상태
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      widget.onFocusChanged(_focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color:
              widget.isSelected
                  ? Colors.blue.withOpacity(0.05)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Stack(
          children: [
            _buildBlockContent(),
            if (widget.isSelected && !widget.readOnly) _buildAddButton(),
          ],
        ),
      ),
    );
  }

  /// 블록 추가 버튼 (노션 스타일)
  Widget _buildAddButton() {
    return Positioned(
      left: -24, // 블록 왼쪽에 위치
      top: 4,
      child: AnimatedOpacity(
        opacity: widget.isSelected ? 1.0 : 0.0,
        duration: Duration(milliseconds: 150),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Color(0xFF363636),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade700, width: 1),
          ),
          child: IconButton(
            icon: Icon(Icons.add, size: 12, color: Colors.grey.shade300),
            tooltip: '새 블록 추가',
            padding: EdgeInsets.zero,
            splashRadius: 14,
            onPressed: widget.onAddBlock,
          ),
        ),
      ),
    );
  }

  /// 블록 내용 위젯
  Widget _buildBlockContent() {
    switch (widget.block.type) {
      case editor.BlockType.heading1:
        return _buildHeadingBlock(
          StyleUtils.getDefaultStyleForBlockType(editor.BlockType.heading1),
        );
      case editor.BlockType.heading2:
        return _buildHeadingBlock(
          StyleUtils.getDefaultStyleForBlockType(editor.BlockType.heading2),
        );
      case editor.BlockType.heading3:
        return _buildHeadingBlock(
          StyleUtils.getDefaultStyleForBlockType(editor.BlockType.heading3),
        );
      case editor.BlockType.bulletList:
        return _buildBulletListBlock();
      case editor.BlockType.numberedList:
        return _buildNumberedListBlock();
      case editor.BlockType.checkList:
        return _buildCheckListBlock();
      case editor.BlockType.divider:
        return _buildDividerBlock();
      case editor.BlockType.image:
        return _buildImageBlock();
      case editor.BlockType.paragraph:
      default:
        return _buildParagraphBlock();
    }
  }

  /// 기본 단락 블록
  Widget _buildParagraphBlock() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: CustomTextEditor(
        initialText: widget.block.content,
        readOnly: widget.readOnly,
        isSelected: widget.isSelected,
        textStyle: StyleUtils.getDefaultStyleForBlockType(
          editor.BlockType.paragraph,
        ),
        hintText: '텍스트를 입력하세요...',
        onTextChanged: widget.onTextChanged,
        onFocusChanged: widget.onFocusChanged,
        onSelectionChanged: widget.onSelectionChanged,
      ),
    );
  }

  /// 제목 블록
  Widget _buildHeadingBlock(TextStyle style) {
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 4, left: 2, right: 2),
      child: CustomTextEditor(
        initialText: widget.block.content,
        readOnly: widget.readOnly,
        isSelected: widget.isSelected,
        textStyle: style,
        hintText: '제목을 입력하세요...',
        onTextChanged: widget.onTextChanged,
        onFocusChanged: widget.onFocusChanged,
        onSelectionChanged: widget.onSelectionChanged,
      ),
    );
  }

  /// 글머리 기호 목록 블록
  Widget _buildBulletListBlock() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6, right: 8, left: 8),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade500,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: CustomTextEditor(
              initialText: widget.block.content,
              readOnly: widget.readOnly,
              isSelected: widget.isSelected,
              textStyle: StyleUtils.getDefaultStyleForBlockType(
                editor.BlockType.bulletList,
              ),
              hintText: '목록 항목을 입력하세요...',
              onTextChanged: widget.onTextChanged,
              onFocusChanged: widget.onFocusChanged,
              onSelectionChanged: widget.onSelectionChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// 번호 목록 블록
  Widget _buildNumberedListBlock() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            padding: EdgeInsets.only(top: 6, right: 4, left: 4),
            child: Text(
              '${widget.index + 1}.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
          Expanded(
            child: CustomTextEditor(
              initialText: widget.block.content,
              readOnly: widget.readOnly,
              isSelected: widget.isSelected,
              textStyle: StyleUtils.getDefaultStyleForBlockType(
                editor.BlockType.numberedList,
              ),
              hintText: '목록 항목을 입력하세요...',
              onTextChanged: widget.onTextChanged,
              onFocusChanged: widget.onFocusChanged,
              onSelectionChanged: widget.onSelectionChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// 체크 목록 블록
  Widget _buildCheckListBlock() {
    final editorState = Provider.of<EditorState>(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 3, right: 8, left: 4),
            child: SizedBox(
              width: 16,
              height: 16,
              child: Checkbox(
                value: widget.block.checked ?? false,
                onChanged:
                    widget.readOnly
                        ? null
                        : (value) {
                          editorState.toggleCheckList(widget.index);
                        },
                activeColor: Colors.blue.shade700,
                checkColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
                side: BorderSide(color: Colors.grey.shade600, width: 1),
              ),
            ),
          ),
          Expanded(
            child: CustomTextEditor(
              initialText: widget.block.content,
              readOnly: widget.readOnly,
              isSelected: widget.isSelected,
              textStyle: StyleUtils.getDefaultStyleForBlockType(
                editor.BlockType.checkList,
              ).copyWith(
                decoration:
                    widget.block.checked ?? false
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                decorationColor: Colors.grey.shade500,
                decorationThickness: 2,
                color:
                    widget.block.checked ?? false
                        ? Colors.grey.shade500
                        : Colors.white,
              ),
              hintText: '체크리스트 항목을 입력하세요...',
              onTextChanged: widget.onTextChanged,
              onFocusChanged: widget.onFocusChanged,
              onSelectionChanged: widget.onSelectionChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// 구분선 블록
  Widget _buildDividerBlock() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 2),
      height: 1,
      color: Colors.grey.shade700,
    );
  }

  /// 이미지 블록
  Widget _buildImageBlock() {
    if (widget.block.imagePath == null || widget.block.imagePath!.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        height: 200,
        decoration: BoxDecoration(
          color: Color(0xFF222222),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey.shade800, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image, size: 32, color: Colors.grey.shade700),
              SizedBox(height: 8),
              Text(
                '이미지를 추가하려면 클릭하세요',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: GestureDetector(
              onTap: () {
                // 이미지 전체 화면 보기
              },
              child: Container(
                constraints: BoxConstraints(maxHeight: 400),
                width: double.infinity,
                decoration: BoxDecoration(color: Color(0xFF222222)),
                child: Image.file(
                  File(widget.block.imagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          if (widget.block.content.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8, left: 2),
              child: Text(
                widget.block.content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
