import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:notoin_style/dropdown2.dart';
import 'package:notoin_style/main.dart';

class NotionTablePage extends StatefulWidget {
  const NotionTablePage({super.key});

  @override
  State<NotionTablePage> createState() => _NotionTablePageState();
}

class _NotionTablePageState extends State<NotionTablePage> {
  @override
  void dispose() {
    _textEditController.dispose();
    super.dispose();
  }

  // 독립적인 셀 편집을 위한 상태 변수들
  int? _editingRowIndex;
  String? _editingColumn;

  TextEditingController _textEditController = TextEditingController();
  int _numOfColumns = 0;
  int _numOfRows = 0;

  List<Map<String, dynamic>> _members = [];

  // 칼럼 헤더 편집 상태를 추가
  String? _editingHeaderColumn;
  TextEditingController _headerEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _members = members;
    _numOfColumns = _members.first.keys.length;
    _numOfRows = _members.length;
    wtf = _preProcessMemberData(_members);
  }

  Map<String, List<String>> wtf = {};

  // {
  //  'textFields' : {
  //   'name': ['정재훈', '김민승', '노영진' ...],
  //   'phoneNumber': ['010-8253-1379', '010-5068-1107', '010-4494-2588' ...],
  //   'email': ['jaehun330@gmail.com', 'jaemin1107@gmail.com', 'emzmfkdufws12@gmail.com' ...]
  // }

  // 'tagFields' :
  // {
  //   'role': ['Frontend', 'Backend', 'PM', 'DevOps' ...],
  //   'status': ['활동중', '비활동' ...],
  // }
  // }

  // 멤버 데이터 전처리
  Map<String, List<String>> _preProcessMemberData(
    List<Map<String, dynamic>> members,
  ) {
    Map<String, List<String>> processed = {
      'textFields': List<String>.empty(growable: true),
      'tagFields': List<String>.empty(growable: true),
    };

    if (members.isEmpty) return processed;

    // 첫 번째 멤버에서 모든 키 추출
    final Set<String> keysSet = members.first.keys.toSet();

    // 기본 텍스트 필드 키워드
    List<String> defaultTextFieldKeys = ['name', 'phoneNumber', 'email'];

    // 각 필드의 모든 값을 수집
    Map<String, Set<dynamic>> valueSets = {};

    for (var member in members) {
      for (var key in keysSet) {
        var value = member[key];
        if (!valueSets.containsKey(key)) {
          valueSets[key] = {};
        }
        valueSets[key]!.add(value);
      }
    }

    // 각 필드 분류
    valueSets.forEach((key, values) {
      // 기본 텍스트 필드이거나 긴 값이 포함된 경우 텍스트 필드로 분류
      if (defaultTextFieldKeys.contains(key.toLowerCase()) ||
          values.any((v) => v.toString().length > 8)) {
        processed['textFields']!.add(key);
      }
      // 고유 값이 적은 경우 태그 필드로 분류
      else if (values.length <= 5) {
        processed['tagFields']!.add(key);
      }
      // 나머지는 텍스트 필드로 처리
      else {
        processed['textFields']!.add(key);
      }
    });

    return processed;
  }

  // 동적 칼럼 생성
  List<DataColumn2> _createDataColumns() {
    List<DataColumn2> columns = [];

    // 텍스트 필드 칼럼 추가
    for (var field in wtf['textFields']!) {
      final GlobalKey columnKey = GlobalKey();
      ColumnSize cellSize = ColumnSize.S;

      if (_members.any((e) => e[field]!.length > 13)) {
        cellSize = ColumnSize.L;
      } else if (_members.any((e) => e[field]!.length > 8)) {
        cellSize = ColumnSize.M;
      }

      columns.add(
        DataColumn2(
          label:
              _editingHeaderColumn == field
                  ? Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        _saveHeaderEdit(field, 'textFields');
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.zero,
                      width: 120,
                      child: TextField(
                        controller: _headerEditController,
                        autofocus: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 14),
                        onSubmitted:
                            (value) => _saveHeaderEdit(field, 'textFields'),
                      ),
                    ),
                  )
                  : GestureDetector(
                    key: columnKey,
                    onTap:
                        () =>
                            _showColumnOptions(field, 'textFields', columnKey),
                    onDoubleTap: () => _startHeaderEdit(field),
                    child: Row(children: [Expanded(child: Text(field))]),
                  ),
          size: cellSize,
          tooltip: field,
        ),
      );
    }

    // 태그 필드 칼럼 추가
    for (var field in wtf['tagFields']!) {
      final GlobalKey columnKey = GlobalKey();
      columns.add(
        DataColumn2(
          label:
              _editingHeaderColumn == field
                  ? Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        _saveHeaderEdit(field, 'tagFields');
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.zero,
                      width: 120,
                      child: TextField(
                        controller: _headerEditController,
                        autofocus: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 14),
                        onSubmitted:
                            (value) => _saveHeaderEdit(field, 'tagFields'),
                      ),
                    ),
                  )
                  : GestureDetector(
                    key: columnKey,
                    onTap:
                        () => _showColumnOptions(field, 'tagFields', columnKey),
                    onDoubleTap: () => _startHeaderEdit(field),
                    child: Row(children: [Expanded(child: Text(field))]),
                  ),
          size: ColumnSize.S,
          tooltip: field,
        ),
      );
    }

    // 추가 버튼 칼럼
    columns.add(
      DataColumn2(
        label: IconButton(
          onPressed: _addColumn,
          icon: const Icon(Icons.add_sharp, size: 18),
        ),
        size: ColumnSize.L,
      ),
    );

    return columns;
  }

  // 동적 셀 생성
  List<DataCell> _createDataCells(Map<String, dynamic> member, int index) {
    List<DataCell> cells = [];

    // 텍스트 필드 셀 추가
    for (var field in wtf['textFields']!) {
      cells.add(
        DataCell(
          _editingRowIndex == index && _editingColumn == field
              ? _buildEditableTextField(
                context,
                _textEditController,
                _saveEditedCell,
              )
              : Text(member[field] ?? ''),
          onTap: () => _editCell(index, field, member[field] ?? ''),
        ),
      );
    }

    // 태그 필드 셀 추가
    for (var field in wtf['tagFields']!) {
      final value = member[field] ?? '';

      cells.add(
        DataCell(
          _editingRowIndex == index && _editingColumn == field
              ? field == 'role'
                  ? RoleDropdown(
                    initialValue: value,
                    onSelected: (String newValue) {
                      setState(() {
                        _members[_editingRowIndex!][field] = newValue;
                        _editingRowIndex = null;
                        _editingColumn = null;
                      });
                    },
                    isEditing: true,
                  )
                  : field == 'status'
                  ? StatusDropdown(
                    initialValue: value,
                    onSelected: (String newValue) {
                      setState(() {
                        _members[_editingRowIndex!][field] = newValue;
                        _editingRowIndex = null;
                        _editingColumn = null;
                      });
                    },
                    isEditing: true,
                  )
                  : _buildEditableTextField(
                    context,
                    _textEditController,
                    _saveEditedCell,
                  )
              : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTagColor(field, value, wtf),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(value, style: TextStyle(fontSize: 12)),
              ),
          onTap: () => _editCell(index, field, value),
        ),
      );
    }

    // 기본 셀
    cells.add(const DataCell(Text('')));
    return cells;
  }

  // 태그 배경색 가져오기
  Color _getTagColor(String field, String value, Map<String, dynamic> wtf) {
    if (wtf['tagFields']!.contains(field)) {
      switch (value) {
        case 'Frontend':
          return Colors.green.shade100;
        case 'Backend':
          return Colors.blue.shade100;
        case 'PM':
          return Colors.purple.shade100;
        case 'DevOps':
          return Colors.orange.shade100;
        case 'Designer':
          return Colors.pink.shade100;
        case 'QA':
          return Colors.brown.shade100;
        default:
          return Colors.grey.shade100;
      }
    } else if (field == 'status') {
      return value == '활동중' ? Colors.green.shade100 : Colors.grey.shade200;
    } else {
      return Colors.grey.shade100;
    }
  }

  void _addColumn() {
    final GlobalKey buttonKey = GlobalKey();
    TextEditingController fieldNameController = TextEditingController();
    bool isAdding = false;
    String fieldType = '';

    // 드롭다운 메뉴로 표시할 팝업 메뉴 버튼 설정
    showMenu<String>(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      context: context,
      position: RelativeRect.fromLTRB(100, 40, 0, 0), // 이 값은 적절히 조정해야 함
      items: [
        PopupMenuItem<String>(
          value: 'text',
          child: Row(children: [const Text('텍스트 필드 추가')]),
        ),
        PopupMenuItem<String>(
          value: 'tag',
          child: Row(children: [const Text('태그 필드 추가')]),
        ),
      ],
    ).then((value) {
      if (value != null) {
        // 필드 타입 저장
        fieldType = value;

        // 필드 이름 입력을 위한 overlay 표시
        final overlay = Overlay.of(context);
        OverlayEntry? entry;

        entry = OverlayEntry(
          builder:
              (context) => Positioned(
                // 위치는 적절히 조정
                right: 0,
                top: 40,
                child: Material(
                  elevation: 4.0,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    width: 300,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: fieldNameController,
                          decoration: const InputDecoration(
                            labelText: '필드 이름',
                            labelStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          autofocus: true,
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                if (fieldType == 'text') {
                                  wtf['textFields']!.add(value);
                                } else {
                                  wtf['tagFields']!.add(value);
                                }

                                // 모든 멤버에 빈 필드 추가
                                for (var member in _members) {
                                  member[value] = '';
                                }
                                // 컬럼 수 업데이트
                                _numOfColumns++;
                              });
                            }

                            // 오버레이 닫기
                            entry?.remove();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        );

        overlay.insert(entry);
      }
    });
  }

  // 칼럼 삭제 함수
  void _deleteColumn(String field, String fieldType) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('칼럼 삭제'),
            content: Text('\'$field\' 칼럼을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    // 해당 필드 타입에서만 필드 제거
                    wtf[fieldType]!.remove(field);

                    // 모든 멤버 데이터에서 해당 필드 제거
                    for (var member in _members) {
                      member.remove(field);
                    }

                    // 컬럼 수 업데이트
                    _numOfColumns--;
                  });
                  Navigator.pop(context);
                },
                child: Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  // 컬럼 헤더 편집 시작
  void _startHeaderEdit(String field) {
    setState(() {
      _editingHeaderColumn = field;
      _headerEditController.text = field;
    });
  }

  // 컬럼 헤더 편집 저장
  void _saveHeaderEdit(String oldName, String fieldType) {
    final newName = _headerEditController.text;

    if (newName.isNotEmpty && newName != oldName) {
      setState(() {
        // 필드 이름 변경
        int index = wtf[fieldType]!.indexOf(oldName);
        if (index != -1) {
          wtf[fieldType]![index] = newName;
        }

        // 모든 멤버 데이터 업데이트
        for (var member in _members) {
          member[newName] = member[oldName];
          member.remove(oldName);
        }
      });
    }

    setState(() {
      _editingHeaderColumn = null;
    });
  }

  void _saveEditedCell() {
    if (_editingRowIndex != null && _editingColumn != null) {
      setState(() {
        _members[_editingRowIndex!][_editingColumn!] = _textEditController.text;
        _editingRowIndex = null;
        _editingColumn = null;
      });
    }
  }

  void _editCell(int rowIndex, String column, dynamic value) {
    setState(() {
      _editingRowIndex = rowIndex;
      _editingColumn = column;
      _textEditController.text = value;
    });
  }

  Widget _buildEditableTextField(
    BuildContext context,
    TextEditingController controller,
    VoidCallback onSave,
  ) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) onSave();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        child: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14),
          onSubmitted: (_) => onSave(),
        ),
      ),
    );
  }

  // 칼럼 옵션 표시 메서드
  void _showColumnOptions(String field, String fieldType, GlobalKey columnKey) {
    final RenderBox? renderBox =
        columnKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final RelativeRect positionRect = RelativeRect.fromLTRB(
      position.dx,
      position.dy + size.height + 10,
      position.dx + size.width,
      position.dy + size.height + 10,
    );

    showMenu<String>(
      context: context,
      color: Colors.white,
      position: positionRect,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      elevation: 4,
      items: [
        PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 10),
              const Text('칼럼명 변경'),
              const SizedBox(width: 30),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 10),
                const Text('삭제하기'),
                const SizedBox(width: 30),
              ],
            ),
          ),
        ),
      ],
    ).then((value) {
      if (value == 'rename') {
        _startHeaderEdit(field);
      } else if (value == 'delete') {
        _deleteColumn(field, fieldType);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: DataTable2(
                  minWidth: 1200,
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  dividerThickness: 0.5,
                  dataRowHeight: 40,
                  headingRowHeight: 40,
                  border: TableBorder(
                    verticalInside: BorderSide(
                      width: 0.5,
                      color: Colors.grey.shade200,
                    ),
                    horizontalInside: BorderSide(
                      width: 0.5,
                      color: Colors.grey.shade200,
                    ),
                    bottom: BorderSide(width: 0.5, color: Colors.grey.shade300),
                  ),
                  columns: _createDataColumns(),
                  rows: List<DataRow>.generate(_members.length, (index) {
                    final member = _members[index];
                    return DataRow2(cells: _createDataCells(member, index));
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
