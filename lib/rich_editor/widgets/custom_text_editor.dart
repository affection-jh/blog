import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'dart:async';
import '../model/document.dart' as editor_model;

/// 텍스트 에디터 위젯
class CustomTextEditor extends StatefulWidget {
  /// 초기 텍스트 내용
  final String initialText;

  /// 읽기 전용 모드
  final bool readOnly;

  /// 현재 선택된 상태인지 여부
  final bool isSelected;

  /// 힌트 텍스트
  final String hintText;

  /// 텍스트 스타일
  final TextStyle textStyle;

  /// 내용 변경 콜백
  final Function(String) onTextChanged;

  /// 포커스 변경 콜백
  final Function(bool) onFocusChanged;

  /// 선택 영역 변경 콜백
  final Function(TextSelection)? onSelectionChanged;

  const CustomTextEditor({
    Key? key,
    required this.initialText,
    this.readOnly = false,
    this.isSelected = false,
    this.hintText = '',
    required this.textStyle,
    required this.onTextChanged,
    required this.onFocusChanged,
    this.onSelectionChanged,
  }) : super(key: key);

  @override
  _CustomTextEditorState createState() => _CustomTextEditorState();
}

class _CustomTextEditorState extends State<CustomTextEditor> {
  /// 텍스트 편집 컨트롤러
  late TextEditingController _controller;

  /// 포커스 노드
  late FocusNode _focusNode;

  /// 현재 선택 영역
  TextSelection _selection = const TextSelection.collapsed(offset: 0);

  /// 커서 깜빡임 타이머
  Timer? _cursorTimer;

  /// 커서 보이기 여부
  bool _showCursor = false;

  /// 커서 깜빡임 상태
  bool _cursorVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();

    _controller.addListener(_handleTextChange);

    // 선택 영역 변경 감지 설정
    _controller.addListener(_handleSelectionChangeFromController);

    _focusNode.addListener(() {
      setState(() {
        _showCursor = _focusNode.hasFocus;
      });
      widget.onFocusChanged(_focusNode.hasFocus);

      if (_focusNode.hasFocus) {
        _startCursorBlink();
      } else {
        _stopCursorBlink();
      }
    });

    // 선택된 경우 포커스 요청
    if (widget.isSelected && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(CustomTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 텍스트가 외부에서 변경된 경우 업데이트
    if (widget.initialText != _controller.text) {
      _controller.text = widget.initialText;
    }

    // 선택된 경우 포커스 요청
    if (widget.isSelected && !oldWidget.isSelected && !widget.readOnly) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _stopCursorBlink();
    _controller.removeListener(_handleTextChange);
    _controller.removeListener(_handleSelectionChangeFromController);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 텍스트 변경 이벤트 처리
  void _handleTextChange() {
    widget.onTextChanged(_controller.text);
  }

  /// 선택 영역 변경 감지 (컨트롤러 통해)
  void _handleSelectionChangeFromController() {
    final TextSelection selection = _controller.selection;
    if (_selection != selection) {
      setState(() {
        _selection = selection;
      });

      if (widget.onSelectionChanged != null) {
        widget.onSelectionChanged!(_selection);
      }
    }
  }

  /// 커서 깜빡임 시작
  void _startCursorBlink() {
    _stopCursorBlink();
    _cursorTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _cursorVisible = !_cursorVisible;
        });
      } else {
        _stopCursorBlink();
      }
    });
    _cursorVisible = true;
  }

  /// 커서 깜빡임 중지
  void _stopCursorBlink() {
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _cursorVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.readOnly) {
          _focusNode.requestFocus();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: _buildTextField(),
      ),
    );
  }

  /// 텍스트 필드 위젯 생성
  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.readOnly,
      style: widget.textStyle,
      maxLines: null,
      minLines: 1,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
        hintText: widget.hintText,
        hintStyle: widget.textStyle.copyWith(color: Colors.grey.shade500),
      ),
      cursorColor: const Color.fromARGB(255, 255, 255, 255),
      cursorWidth: 2.0,
      onChanged: (value) => widget.onTextChanged(value),
      onTap: () {
        // 선택 영역은 컨트롤러에서 자동으로 감지됨
      },
      textInputAction: TextInputAction.newline,
      keyboardType: TextInputType.multiline,
      enableInteractiveSelection: !widget.readOnly,
    );
  }
}
