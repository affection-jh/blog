// 역할 드롭다운 위젯
import 'package:flutter/material.dart';

class RoleDropdown extends StatefulWidget {
  final String initialValue;
  final Function(String) onSelected;
  final bool isEditing;

  const RoleDropdown({
    Key? key,
    required this.initialValue,
    required this.onSelected,
    required this.isEditing,
  }) : super(key: key);

  @override
  State<RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends State<RoleDropdown> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 위젯이 처음 생성될 때 드롭다운 자동 열기
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openDropdown();
      });
    }
  }

  void _openDropdown() {
    GestureDetector? detector;
    void searchForGestureDetector(BuildContext? element) {
      element?.visitChildElements((element) {
        if (element.widget is GestureDetector) {
          detector = element.widget as GestureDetector?;
          return;
        } else {
          searchForGestureDetector(element);
        }
      });
    }

    searchForGestureDetector(_key.currentContext);
    detector?.onTap?.call();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Frontend':
        return Colors.green.shade700;
      case 'Backend':
        return Colors.blue.shade700;
      case 'PM':
        return Colors.purple.shade700;
      case 'DevOps':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      child: PopupMenuButton<String>(
        key: _key,
        initialValue: widget.initialValue,
        onSelected: widget.onSelected,
        offset: const Offset(0, 40),
        elevation: 3,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        itemBuilder:
            (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'Frontend',
                height: 36,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Frontend',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'Backend',
                height: 36,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Backend',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'PM',
                height: 36,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PM',
                    style: TextStyle(
                      color: Colors.purple.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'DevOps',
                height: 36,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DevOps',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initialValue,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _getRoleColor(widget.initialValue),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// 상태 드롭다운 위젯
class StatusDropdown extends StatefulWidget {
  final String initialValue;
  final Function(String) onSelected;
  final bool isEditing;

  const StatusDropdown({
    Key? key,
    required this.initialValue,
    required this.onSelected,
    required this.isEditing,
  }) : super(key: key);

  @override
  State<StatusDropdown> createState() => _StatusDropdownState();
}

class _StatusDropdownState extends State<StatusDropdown> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 위젯이 처음 생성될 때 드롭다운 자동 열기
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openDropdown();
      });
    }
  }

  void _openDropdown() {
    GestureDetector? detector;
    void searchForGestureDetector(BuildContext? element) {
      element?.visitChildElements((element) {
        if (element.widget is GestureDetector) {
          detector = element.widget as GestureDetector?;
          return;
        } else {
          searchForGestureDetector(element);
        }
      });
    }

    searchForGestureDetector(_key.currentContext);
    detector?.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      child: PopupMenuButton<String>(
        key: _key,
        initialValue: widget.initialValue,
        onSelected: widget.onSelected,
        offset: const Offset(0, 40),
        elevation: 3,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        itemBuilder:
            (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: '활동중',
                height: 36,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '활동중',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: '비활동',
                height: 36,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '비활동',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initialValue,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color:
                      widget.initialValue == '활동중'
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
