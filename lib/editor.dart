import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:ui';
// 드래그 앤 드롭 API
import 'package:flutter/gestures.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart'; // RenderEditable 클래스 사용을 위한 import 추가

class NotionEditor extends StatefulWidget {
  @override
  _NotionEditorState createState() => _NotionEditorState();
}

class _NotionEditorState extends State<NotionEditor> {
  final TextEditingController _titleController = TextEditingController(
    text: '새 페이지',
  );
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _textFieldKey = GlobalKey();

  OverlayEntry? _plusButtonOverlay;
  // 텍스트 스타일 상태
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderlined = false;

  // 현재 선택된 폰트 사이즈와 텍스트 정렬
  String _currentStyle = 'Body 2';
  TextAlign _textAlign = TextAlign.left;

  // 이미지 관련
  final ImagePicker _imagePicker = ImagePicker();
  final List<ImageItem> _images = [];

  bool _showImageOptions = false;
  double _dragPositionY = 0;

  // 커서 위치 관련
  double _cursorPositionY = 0;

  final LayerLink _layerLink = LayerLink();

  double _hoverLineY = 0;

  // 스크롤 오프셋
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _scrollController.dispose();
    _plusButtonOverlay?.remove();
    super.dispose();
  }

  // 텍스트 변경 감지
  void _handleTextChange() async {
    _updateCursorPosition(); // 커서 위치 먼저 업데이트

    if (_scrollController.hasClients) {
      final viewHeight = MediaQuery.of(context).size.height;
      final expectedY = _hoverLineY;

      if (_scrollController.offset + viewHeight - 100 < expectedY) {
        _scrollController.animateTo(
          expectedY,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }

    _checkForSlashCommand();
  }

  // 커서 위치 업데이
  void _updateCursorPosition() async {
    final selection = _contentController.selection;
    if (!selection.isValid) return;

    await Future.delayed(Duration.zero);

    final context = _textFieldKey.currentContext;
    if (context == null) return;

    RenderObject? renderObject = context.findRenderObject();
    RenderEditable? renderEditable;

    void findEditable(RenderObject child) {
      child.visitChildren((subChild) {
        if (subChild is RenderEditable) {
          renderEditable = subChild;
        } else {
          findEditable(subChild);
        }
      });
    }

    if (renderObject != null) findEditable(renderObject);
    if (renderEditable == null) return;

    final caretRect = renderEditable!.getLocalRectForCaret(selection.extent);
    final caretOffset = renderEditable!.localToGlobal(caretRect.topLeft);

    _plusButtonOverlay?.remove();

    // 텍스트 필드 위치와 크기 정보 가져오기
    RenderBox? textFieldBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (textFieldBox == null) return;

    // 텍스트 필드의 글로벌 위치와 크기
    final textFieldOffset = textFieldBox.localToGlobal(Offset.zero);
    final textFieldWidth = textFieldBox.size.width;

    // 텍스트 정렬에 따라 + 버튼 위치 결정
    double leftPosition;
    if (_textAlign == TextAlign.right) {
      // 오른쪽 정렬일 경우 텍스트 필드의 오른쪽 끝에 배치
      leftPosition = textFieldOffset.dx + textFieldWidth + 10;
    } else {
      // 왼쪽 정렬이나 가운데 정렬일 경우 왼쪽에 배치
      leftPosition = textFieldOffset.dx - 40; // 여백 고려해서 약간 왼쪽으로 이동
    }

    _plusButtonOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            left: leftPosition,
            top: caretOffset.dy,
            child: toolButton(),
          ),
    );

    Overlay.of(context, rootOverlay: true).insert(_plusButtonOverlay!);
  }

  // 슬래시 명령 감지
  void _checkForSlashCommand() {
    if (!_contentFocusNode.hasFocus || !_contentController.selection.isValid)
      return;

    // 현재 라인의 텍스트 가져오기
    final text = _contentController.text;
    final selection = _contentController.selection;
    final currentLineStart =
        text.lastIndexOf('\n', selection.baseOffset - 1) + 1;
    final currentLineEnd = text.indexOf('\n', selection.baseOffset);
    final currentLine = text.substring(
      currentLineStart,
      currentLineEnd > 0 ? currentLineEnd : text.length,
    );

    // 라인이 슬래시로 시작하는지 확인
    if (currentLine.startsWith('/') && currentLine.length == 1) {
      // 슬래시 메뉴 표시
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSlashCommandMenu();
      });
    }
  }

  // 슬래시 명령 메뉴 표시
  void _showSlashCommandMenu() {
    // 메뉴를 표시할 위치 계산

    // 노션 스타일 슬래시 명령 메뉴
    final List<PopupMenuEntry<String>> menuItems = [
      _buildMenuItem('텍스트', Icons.text_fields, 'text'),
      _buildMenuItem('제목1', Icons.title, 'h1'),
      _buildMenuItem('제목2', Icons.title, 'h2'),
      _buildMenuItem('제목3', Icons.title, 'h3'),
      _buildMenuItem('글머리 기호', Icons.format_list_bulleted, 'bullet'),
      _buildMenuItem('번호 매기기', Icons.format_list_numbered, 'numbered'),
      _buildMenuItem('체크리스트', Icons.check_box, 'checklist'),
      _buildMenuItem('구분선', Icons.horizontal_rule, 'divider'),
      _buildMenuItem('이미지', Icons.image, 'image'),
    ];

    // 팝업 메뉴 표시
    showMenu<String>(
      context: context,

      color: Color(0xFF333333),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      items: menuItems,
    ).then((value) {
      if (value == null) return;

      // 슬래시 지우기
      final text = _contentController.text;
      final selection = _contentController.selection;
      final currentLineStart =
          text.lastIndexOf('\n', selection.baseOffset - 1) + 1;
      _contentController.value = TextEditingValue(
        text: text.replaceRange(currentLineStart, selection.baseOffset, ''),
        selection: TextSelection.collapsed(offset: currentLineStart),
      );

      // 명령 실행
      _executeCommand(value);
    });
  }

  // 명령 실행
  void _executeCommand(String command) {
    final currentText = _contentController.text;
    final selection = _contentController.selection;

    switch (command) {
      case 'text':
        // 텍스트 블록 추가 (기본 상태)
        break;
      case 'h1':
        // 제목1 추가
        final newText =
            '${currentText.substring(0, selection.extentOffset)}# ${currentText.substring(selection.extentOffset)}';
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.extentOffset + 2,
          ),
        );
        break;
      case 'h2':
        // 제목2 추가
        final newText =
            '${currentText.substring(0, selection.extentOffset)}## ${currentText.substring(selection.extentOffset)}';
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.extentOffset + 3,
          ),
        );
        break;
      case 'h3':
        // 제목3 추가
        final newText =
            '${currentText.substring(0, selection.extentOffset)}### ${currentText.substring(selection.extentOffset)}';
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.extentOffset + 4,
          ),
        );
        break;
      case 'bullet':
        // 글머리 기호 추가
        final newText =
            '${currentText.substring(0, selection.extentOffset)}• ${currentText.substring(selection.extentOffset)}';
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.extentOffset + 2,
          ),
        );
        break;
      case 'numbered':
        // 번호 매기기 추가
        final newText =
            '${currentText.substring(0, selection.extentOffset)}1. ${currentText.substring(selection.extentOffset)}';
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.extentOffset + 3,
          ),
        );
        break;
      case 'checklist':
        // 체크리스트 추가
        final newText =
            '${currentText.substring(0, selection.extentOffset)}- [ ] ${currentText.substring(selection.extentOffset)}';
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.extentOffset + 6,
          ),
        );
        break;
      case 'divider':
        // 구분선 추가
        final newText =
            '${currentText.substring(0, selection.extentOffset)}\n---\n${currentText.substring(selection.extentOffset)}';
        _contentController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.extentOffset + 5,
          ),
        );
        break;
      case 'image':
        // 이미지 추가
        _getImageFromGallery();
        break;
    }

    // 포커스 유지
    _contentFocusNode.requestFocus();
  }

  // 이미지 옵션 버튼 위젯
  Widget _imageOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 12),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // 이미지 옵션 버튼 클릭 시 메뉴 표시
  void _showPlusMenu(double lineY) {
    // 메뉴를 표시할 위치 계산
    final RelativeRect position = RelativeRect.fromLTRB(
      24, // 왼쪽에서 약간 떨어진 위치
      lineY, // 현재 커서 라인의 Y 위치
      0, // 오른쪽 여백 (의미 없음)
      0, // 아래 여백 (의미 없음)
    );

    // 노션 스타일 메뉴 아이템
    final List<PopupMenuEntry<String>> menuItems = [
      _buildMenuItem('텍스트', Icons.text_fields, 'text'),
      _buildMenuItem('제목1', Icons.title, 'h1', shortcut: '#'),
      _buildMenuItem('제목2', Icons.title, 'h2', shortcut: '##'),
      _buildMenuItem('제목3', Icons.title, 'h3', shortcut: '###'),
      _buildMenuItem('글머리 기호', Icons.format_list_bulleted, 'bullet'),
      _buildMenuItem('번호 매기기', Icons.format_list_numbered, 'numbered'),
      _buildMenuItem('체크리스트', Icons.check_box, 'checklist'),
      _buildMenuItem('구분선', Icons.horizontal_rule, 'divider'),
      _buildMenuItem('이미지', Icons.image, 'image'),
    ];

    // 팝업 메뉴 표시
    showMenu<String>(
      context: context,
      position: position,
      color: Color(0xFF333333),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      items: menuItems,
    ).then((value) {
      if (value == null) return;

      _executeCommand(value);
    });
  }

  // 메뉴 아이템 위젯 생성
  PopupMenuItem<String> _buildMenuItem(
    String title,
    IconData icon,
    String value, {
    String? shortcut,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade300),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
            ),
          ),
          if (shortcut != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                shortcut,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // 이미지 추가 (카메라)
  Future<void> _getImageFromCamera() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (image != null) {
      setState(() {
        _images.add(
          ImageItem(
            file: File(image.path),
            position: _dragPositionY > 0 ? _dragPositionY : 200.0,
          ),
        );
      });
    }
  }

  // 이미지 추가 (갤러리)
  Future<void> _getImageFromGallery() async {
    if (kIsWeb) {
      // 웹에서는 WebImagePicker 사용
      final webImages = await WebImagePicker.pickImages();
      if (webImages.isNotEmpty) {
        double position = _dragPositionY > 0 ? _dragPositionY : 200.0;
        for (var webImage in webImages) {
          final imageUrl = await WebImagePicker.createFileUrl(webImage);
          setState(() {
            _images.add(
              ImageItem(file: imageUrl, position: position, isWeb: true),
            );
            position += 300; // 이미지 간 간격
          });
        }
      }
    } else {
      // 네이티브 플랫폼에서는 기존 방식 사용
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        setState(() {
          _images.add(
            ImageItem(
              file: File(image.path),
              position: _dragPositionY > 0 ? _dragPositionY : 200.0,
            ),
          );
        });
      }
    }
  }

  // 이미지 추가 (다중 선택)
  Future<void> _getMultipleImages() async {
    if (kIsWeb) {
      // 웹에서는 WebImagePicker 사용
      await _getImageFromGallery();
    } else {
      // 네이티브 플랫폼에서는 기존 방식 사용
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          double position = _dragPositionY > 0 ? _dragPositionY : 200.0;
          for (var file in result.files) {
            if (file.path != null) {
              _images.add(
                ImageItem(file: File(file.path!), position: position),
              );
              // 이미지 간격 조정
              position += 300;
            }
          }
        });
      }
    }
  }

  // 이미지 메뉴 표시
  void _showImageMenu() {
    setState(() {
      _showImageOptions = true;
    });

    // 5초 후 자동으로 숨김
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showImageOptions = false;
        });
      }
    });
  }

  // 이미지 자동 정렬
  void _autoArrangeImages() {
    if (_images.isEmpty) return;

    setState(() {
      double position = 150.0;
      for (var i = 0; i < _images.length; i++) {
        _images[i].position = position;
        position += 300; // 이미지 간 간격
      }
    });
  }

  // 이미지 삭제
  void _deleteImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // 블록 메뉴 표시 함수
  void _showBlockMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 240,
        position.dy,
      ),
      color: Color(0xFF1F1F1F),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      items: [
        // 카테고리: 추천
        PopupMenuItem<String>(
          enabled: false,
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '추천',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              SizedBox(height: 4),
              Container(height: 1, color: Colors.grey.shade800),
            ],
          ),
        ),
        _buildMenuItem('텍스트', Icons.text_fields, 'text'),
        _buildMenuItem('제목1', Icons.title, 'heading1', shortcut: '#'),
        _buildMenuItem('제목2', Icons.title, 'heading2', shortcut: '##'),
        _buildMenuItem('제목3', Icons.title, 'heading3', shortcut: '###'),

        // 카테고리: 기본 블록
        PopupMenuItem<String>(
          enabled: false,
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '기본 블록',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              SizedBox(height: 4),
              Container(height: 1, color: Colors.grey.shade800),
            ],
          ),
        ),
        _buildMenuItem(
          '글머리 기호 목록',
          Icons.format_list_bulleted,
          'bullet_list',
          shortcut: '-',
        ),
        _buildMenuItem(
          '번호 매기기 목록',
          Icons.format_list_numbered,
          'numbered_list',
          shortcut: '1.',
        ),
        _buildMenuItem(
          '할 일 목록',
          Icons.check_box_outlined,
          'todo',
          shortcut: '[]',
        ),
        _buildMenuItem('구분선', Icons.remove, 'divider', shortcut: '---'),
        _buildMenuItem('이미지', Icons.image, 'image'),
      ],
    ).then((value) {
      if (value != null) {
        _handleMenuSelection(value);
      }
    });
  }

  // 메뉴 선택 처리
  void _handleMenuSelection(String value) {
    String insertText = '';
    final currentText = _contentController.text;
    final selection = _contentController.selection;

    switch (value) {
      case 'text':
        // 텍스트 블록 (기본)
        insertText = '\n';
        break;
      case 'heading1':
        // 제목1
        insertText = '# ';
        break;
      case 'heading2':
        // 제목2
        insertText = '## ';
        break;
      case 'heading3':
        // 제목3
        insertText = '### ';
        break;
      case 'bullet_list':
        // 글머리 기호
        insertText = '• ';
        break;
      case 'numbered_list':
        // 번호 매기기
        insertText = '1. ';
        break;
      case 'todo':
        // 체크리스트
        insertText = '☐ ';
        break;
      case 'divider':
        // 구분선
        insertText = '\n───────────────────\n';
        break;
      case 'image':
        // 이미지 추가
        _getImageFromGallery();
        return;
    }

    if (insertText.isNotEmpty) {
      // 현재 커서 위치에 삽입
      final newText = currentText.replaceRange(
        selection.baseOffset,
        selection.extentOffset,
        insertText,
      );

      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset + insertText.length,
        ),
      );
    }

    // 포커스 유지
    _contentFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2D2D2D),
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImageMenu,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add_photo_alternate, color: Colors.white),
        tooltip: '이미지 추가',
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // 스크롤 가능한 메인 콘텐츠
                SingleChildScrollView(
                  controller: _scrollController,
                  child: MouseRegion(
                    child: Stack(
                      children: [
                        // 노션 스타일 레이아웃 - 가운데 정렬, 제한된 너비
                        Center(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: 800,
                              minHeight: constraints.maxHeight,
                            ),
                            alignment: Alignment.topLeft,
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                // 제목 입력 (새 페이지 )- 패딩 조정
                                Padding(
                                  padding: EdgeInsets.only(top: 16, bottom: 16),
                                  child: TextField(
                                    controller: _titleController,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    cursorColor: Colors.white,
                                    cursorWidth: 2,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '제목 없음',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),

                                // 스타일링 툴바
                                toolBar(),
                                // 메인 에디터
                                Container(
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight - 300,
                                  ),
                                  child: Stack(
                                    children: [
                                      // 에디터 콘텐츠 영역
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (_textAlign != TextAlign.right)
                                            SizedBox(width: 10),
                                          // 실제 텍스트 필드
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                left: 30,
                                              ), // 왼쪽 여백 추가
                                              child: ScrollConfiguration(
                                                behavior: ScrollBehavior()
                                                    .copyWith(
                                                      scrollbars: false,
                                                    ),
                                                child: SingleChildScrollView(
                                                  child: CompositedTransformTarget(
                                                    link: _layerLink,
                                                    child: TextField(
                                                      key: _textFieldKey,
                                                      controller:
                                                          _contentController,
                                                      focusNode:
                                                          _contentFocusNode,
                                                      expands: false,
                                                      minLines: 1,
                                                      maxLines: null,
                                                      textAlign: _textAlign,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            _isBold
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .normal,
                                                        fontStyle:
                                                            _isItalic
                                                                ? FontStyle
                                                                    .italic
                                                                : FontStyle
                                                                    .normal,
                                                        decoration:
                                                            _isUnderlined
                                                                ? TextDecoration
                                                                    .underline
                                                                : TextDecoration
                                                                    .none,
                                                        color: Colors.white,
                                                        height: 1.5,
                                                      ),
                                                      onChanged:
                                                          (_) =>
                                                              _handleTextChange(),
                                                      onTap:
                                                          _updateCursorPosition,
                                                      cursorColor: Colors.white,
                                                      decoration:
                                                          InputDecoration(
                                                            border:
                                                                InputBorder
                                                                    .none,
                                                            hintText:
                                                                '여기에 입력하세요...',
                                                            contentPadding:
                                                                EdgeInsets.only(
                                                                  left: 0,
                                                                  right: 16,
                                                                ),
                                                            isDense: true,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (_textAlign == TextAlign.right)
                                            SizedBox(width: 30),
                                        ],
                                      ),

                                      // 플러스 버튼

                                      // 이미지 항목들 - 가운데 정렬
                                      ..._images.asMap().entries.map((entry) {
                                        int index = entry.key;
                                        ImageItem image = entry.value;
                                        return Positioned(
                                          left: 16,
                                          top: image.position,
                                          right: 16,
                                          child: GestureDetector(
                                            onVerticalDragUpdate: (details) {
                                              setState(() {
                                                image.position +=
                                                    details.delta.dy;
                                              });
                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // 이미지 - 노션 스타일로 가운데 정렬된 이미지 컨테이너
                                                Container(
                                                  constraints: BoxConstraints(
                                                    maxWidth:
                                                        700, // 최대 너비 제한 (노션과 유사하게)
                                                    maxHeight: 400, // 높이 제한 추가
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    child:
                                                        image.isWeb
                                                            ? Image.network(
                                                              image.file
                                                                  as String,
                                                              fit:
                                                                  BoxFit
                                                                      .contain,
                                                            )
                                                            : Image.file(
                                                              image.file
                                                                  as File,
                                                              fit:
                                                                  BoxFit
                                                                      .contain,
                                                            ),
                                                  ),
                                                ),

                                                // 삭제 버튼
                                                Positioned(
                                                  right: 0,
                                                  top: 0,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            50,
                                                          ),
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                      padding: EdgeInsets.all(
                                                        4,
                                                      ),
                                                      constraints:
                                                          BoxConstraints(),
                                                      onPressed:
                                                          () => _deleteImage(
                                                            index,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),

                                // 추가 여백 확보 (스크롤 시 충분한 공간 제공)
                                SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 이미지 옵션 메뉴
                if (_showImageOptions)
                  Positioned(
                    right: 80,
                    bottom: 20,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF333333),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '이미지 추가',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Divider(color: Colors.grey.shade700, height: 1),
                          SizedBox(height: 8),
                          _imageOptionButton(
                            icon: Icons.photo_library,
                            label: '갤러리에서 선택',
                            onPressed: _getImageFromGallery,
                          ),
                          SizedBox(height: 8),
                          _imageOptionButton(
                            icon: Icons.camera_alt,
                            label: '카메라로 촬영',
                            onPressed: _getImageFromCamera,
                          ),
                          SizedBox(height: 8),
                          _imageOptionButton(
                            icon: Icons.photo_library,
                            label: '여러 이미지 선택',
                            onPressed: _getMultipleImages,
                          ),
                          SizedBox(height: 8),
                          _imageOptionButton(
                            icon: Icons.format_line_spacing,
                            label: '이미지 자동 정렬',
                            onPressed: _autoArrangeImages,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget toolBar() {
    return Container(
      margin: EdgeInsets.only(bottom: 20), // 아래쪽 마진만 유지
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFF333333),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 텍스트 스타일 선택
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text(
                  _currentStyle,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
              ],
            ),
          ),
          SizedBox(width: 8),

          // 굵게
          IconButton(
            icon: Icon(
              Icons.format_bold,
              color: _isBold ? Colors.white : Colors.grey,
            ),
            iconSize: 20,
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(),
            onPressed: () {
              setState(() {
                _isBold = !_isBold;
              });
            },
          ),

          // 기울임
          IconButton(
            icon: Icon(
              Icons.format_italic,
              color: _isItalic ? Colors.white : Colors.grey,
            ),
            iconSize: 20,
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(),
            onPressed: () {
              setState(() {
                _isItalic = !_isItalic;
              });
            },
          ),

          // 밑줄
          IconButton(
            icon: Icon(
              Icons.format_underlined,
              color: _isUnderlined ? Colors.white : Colors.grey,
            ),
            iconSize: 20,
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(),
            onPressed: () {
              setState(() {
                _isUnderlined = !_isUnderlined;
              });
            },
          ),

          // 링크
          IconButton(
            icon: Icon(Icons.link, color: Colors.grey),
            iconSize: 20,
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(),
            onPressed: () {},
          ),

          // 이미지 추가 버튼
          IconButton(
            icon: Icon(Icons.image, color: Colors.grey),
            iconSize: 20,
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(),
            onPressed: _getImageFromGallery,
          ),

          // 텍스트 색상
          Container(
            width: 20,
            height: 20,
            margin: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),

          Spacer(),

          // 텍스트 정렬 - 왼쪽
          IconButton(
            icon: Icon(
              Icons.format_align_left,
              color: _textAlign == TextAlign.left ? Colors.white : Colors.grey,
            ),
            iconSize: 20,
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(),
            onPressed: () {
              setState(() {
                _textAlign = TextAlign.left;
              });
              // 정렬 변경 시 커서 위치 업데이트하여 + 버튼 위치도 업데이트
              _updateCursorPosition();
            },
          ),

          // 텍스트 정렬 - 가운데
          IconButton(
            icon: Icon(
              Icons.format_align_center,
              color:
                  _textAlign == TextAlign.center ? Colors.white : Colors.grey,
            ),
            iconSize: 20,
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(),
            onPressed: () {
              setState(() {
                _textAlign = TextAlign.center;
              });
              // 정렬 변경 시 커서 위치 업데이트하여 + 버튼 위치도 업데이트
              _updateCursorPosition();
            },
          ),

          // 텍스트 정렬 - 오른쪽
          IconButton(
            icon: Icon(
              Icons.format_align_right,
              color: _textAlign == TextAlign.right ? Colors.white : Colors.grey,
            ),
            iconSize: 20,
            padding: EdgeInsets.all(8),
            constraints: BoxConstraints(),
            onPressed: () {
              setState(() {
                _textAlign = TextAlign.right;
              });
              // 정렬 변경 시 커서 위치 업데이트하여 + 버튼 위치도 업데이트
              _updateCursorPosition();
            },
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF2D2D2D),
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 150,
      titleSpacing: 16,
      title: Row(
        children: [
          Text('새 페이지', style: TextStyle(color: Colors.white, fontSize: 14)),
          Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: Colors.grey.shade400),
          onPressed: () {},
          tooltip: '공유',
        ),
        IconButton(
          icon: Icon(Icons.comment_outlined, color: Colors.grey.shade400),
          onPressed: () {},
          tooltip: '댓글',
        ),
        IconButton(
          icon: Icon(Icons.star_border, color: Colors.grey.shade400),
          onPressed: () {},
          tooltip: '즐겨찾기',
        ),
        IconButton(
          icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
          onPressed: () {},
          tooltip: '더 보기',
        ),
      ],
    );
  }

  Widget toolButton() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Color(0xFF333333),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap:
              () => _showBlockMenu(
                context,
                Offset(32, 0), // 현재 위치에서 오른쪽으로 32px 이동
              ),
          child: Center(child: Icon(Icons.add, size: 15, color: Colors.white)),
        ),
      ),
    );
  }
}

// 웹 플랫폼에서 이미지를 처리하기 위한 클래스
class WebImagePicker {
  static Future<List<html.File>> pickImages() async {
    final uploadInput =
        html.FileUploadInputElement()
          ..accept = 'image/*'
          ..multiple = true;

    uploadInput.click();

    await uploadInput.onChange.first;

    if (uploadInput.files != null && uploadInput.files!.isNotEmpty) {
      return uploadInput.files!;
    }

    return [];
  }

  static Future<String> createFileUrl(html.File file) async {
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    return reader.result as String;
  }
}

// 네이티브와 웹 모두에서 사용 가능한 이미지 항목 클래스
class ImageItem {
  final dynamic file; // File 또는 String(웹 URL)
  double position;
  bool isWeb;

  ImageItem({required this.file, required this.position, this.isWeb = false});
}

// 데스크톱과 웹에서 파일 드래그 앤 드롭을 처리하기 위한 클래스
