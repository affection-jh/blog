import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../model/document.dart';
import '../model/editor_state.dart';

/// 블록 추가 버튼 위젯
class EditorPlusButton extends StatefulWidget {
  /// 에디터 상태
  final EditorState editorState;

  /// 버튼이 표시될 위치
  final double top;

  /// 커서의 Y 위치
  final double cursorY;

  /// 추가 버튼 위치 (왼쪽 또는 오른쪽)
  final bool showOnLeft;

  const EditorPlusButton({
    Key? key,
    required this.editorState,
    required this.top,
    required this.cursorY,
    this.showOnLeft = true,
  }) : super(key: key);

  @override
  _EditorPlusButtonState createState() => _EditorPlusButtonState();
}

class _EditorPlusButtonState extends State<EditorPlusButton>
    with SingleTickerProviderStateMixin {
  /// 애니메이션 컨트롤러
  late AnimationController _animationController;

  /// 애니메이션
  late Animation<double> _animation;

  /// 메뉴 표시 여부
  bool _showMenu = false;

  /// UUID 생성기
  final Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.showOnLeft ? 2 : null,
      right: widget.showOnLeft ? null : 2,
      top: widget.top,
      child: Row(
        children: [
          if (!widget.showOnLeft) _buildMenuItems(),

          _buildPlusButton(),

          if (widget.showOnLeft) _buildMenuItems(),
        ],
      ),
    );
  }

  /// 플러스 버튼 위젯
  Widget _buildPlusButton() {
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
          onTap: _toggleMenu,
          child: Center(
            child: Icon(
              _showMenu ? Icons.close : Icons.add,
              size: 15,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 메뉴 아이템 위젯
  Widget _buildMenuItems() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _animation,
          axis: Axis.horizontal,
          axisAlignment: widget.showOnLeft ? -1.0 : 1.0,
          child: child,
        );
      },
      child:
          _showMenu
              ? Container(
                padding: EdgeInsets.symmetric(horizontal: 4),
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
                child: Row(
                  children: [
                    _buildMenuItem(
                      Icons.text_fields,
                      '텍스트',
                      BlockType.paragraph,
                    ),
                    _buildMenuItem(Icons.title, '제목 1', BlockType.heading1),
                    _buildMenuItem(
                      Icons.format_list_bulleted,
                      '글머리 기호',
                      BlockType.bulletList,
                    ),
                    _buildMenuItem(
                      Icons.format_list_numbered,
                      '번호 매기기',
                      BlockType.numberedList,
                    ),
                    _buildMenuItem(
                      Icons.check_box_outlined,
                      '체크리스트',
                      BlockType.checkList,
                    ),
                    _buildMenuItem(
                      Icons.horizontal_rule,
                      '구분선',
                      BlockType.divider,
                    ),
                    _buildMenuItem(Icons.image, '이미지', BlockType.image),
                  ],
                ),
              )
              : SizedBox.shrink(),
    );
  }

  /// 메뉴 아이템 버튼
  Widget _buildMenuItem(IconData icon, String tooltip, BlockType blockType) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: () => _addBlock(blockType),
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  /// 메뉴 토글
  void _toggleMenu() {
    setState(() {
      _showMenu = !_showMenu;

      if (_showMenu) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  /// 블록 추가
  void _addBlock(BlockType blockType) {
    final newBlock = Block(id: _generateId(), type: blockType, content: '');

    // 에디터 상태의 addBlock 메서드를 사용하여 블록 추가
    widget.editorState.addBlock(newBlock);

    // 메뉴 닫기
    _toggleMenu();
  }

  /// 블록 ID 생성
  String _generateId() {
    return _uuid.v4();
  }
}
