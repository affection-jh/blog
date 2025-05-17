import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:notoin_style/dropdown2.dart';

class NotionTablePage extends StatefulWidget {
  const NotionTablePage({super.key});

  @override
  State<NotionTablePage> createState() => _NotionTablePageState();
}

class _NotionTablePageState extends State<NotionTablePage> {
  int numOfRows = 1;
  int numOfColumns = 1;
  int numOfTagFields = 1;
  int numOfTextFields = 1;

  final List<Map<String, dynamic>> _members = [
    {
      'name': '김민승',
      'role': 'Frontend',
      'phoneNumber': '010-5068-1107',
      'github': 'jaemin104',
      'status': '활동중',
      'email': 'jaemin1107@gmail.com',
    },
    {
      'name': '노영진',
      'role': 'Backend',
      'phoneNumber': '010-4494-2588',
      'github': 'youngjin',
      'status': '활동중',
      'email': 'emzmfkdufws12@gmail.com',
    },
    {
      'name': '신영빈',
      'role': 'Frontend',
      'phoneNumber': '010-5841-0128',
      'github': 'youngbin03',
      'status': '활동중',
      'email': 'shyoungbin0128@gmail.com',
    },
    {
      'name': '정재훈',
      'role': 'Frontend',
      'phoneNumber': '010-8253-1379',
      'github': 'affection.jh',
      'status': '활동중',
      'email': 'jaehun330@gmail.com',
    },
  ];

  @override
  void dispose() {
    _textEditController.dispose();
    super.dispose();
  }

  // 독립적인 셀 편집을 위한 상태 변수들
  int? _editingRowIndex;
  String? _editingColumn;

  TextEditingController _textEditController = TextEditingController();

  Map<String, dynamic> _textFields = {};

  // {
  //  name: ['정재훈', '김민승', '노영진' ...],
  // 'phoneNumber': ['010-8253-1379', '010-5068-1107', '010-4494-2588' ...],
  // 'email': ['jaehun330@gmail.com', 'jaemin1107@gmail.com', 'emzmfkdufws12@gmail.com' ...]
  // }

  Map<String, dynamic> _tagFields = {};

  // {
  //  role: ['Frontend', 'Backend', 'PM', 'DevOps' ...],
  // 'status': ['활동중', '비활동' ...],
  // }

  // 멤버 데이터 전처리
  Map<String, dynamic> _preProcessMemberData(
    List<Map<String, dynamic>> members,
  ) {
    Map<String, dynamic> processed = {
      'textFields': <String>[],
      'tagFields': <String>[],
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
        processed['textFields'].add(key);
      }
      // 고유 값이 적은 경우 태그 필드로 분류
      else if (values.length <= 5) {
        processed['tagFields'].add(key);
      }
      // 나머지는 텍스트 필드로 처리
      else {
        processed['textFields'].add(key);
      }
    });

    return processed;
  }

  // 동적 칼럼 생성
  List<DataColumn2> _createDataColumns() {
    List<DataColumn2> columns = [];

    // 텍스트 필드 칼럼 추가
    for (var field in _textFields.values) {
      ColumnSize cellSize =
          field.any((e) => e.length > 13) ? ColumnSize.L : ColumnSize.M;
      columns.add(
        DataColumn2(
          label: Text(field.keys.first),
          size: cellSize,
          tooltip: field.values.first.first,
        ),
      );
    }

    // 태그 필드 칼럼 추가
    for (var field in _tagFields.keys) {
      columns.add(
        DataColumn2(label: Text(field), size: ColumnSize.S, tooltip: field),
      );
    }
    // 추가 버튼 칼럼
    columns.add(
      DataColumn2(
        label: IconButton(
          onPressed: _addColumn,
          icon: const Icon(Icons.add_sharp, size: 18),
        ),
        size: ColumnSize.S,
      ),
    );

    return columns;
  }

  // 동적 셀 생성
  List<DataCell> _createDataCells(Map<String, dynamic> member, int index) {
    List<DataCell> cells = [];

    // 텍스트 필드 셀 추가
    for (var field in _textFields.keys) {
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
    for (var field in _tagFields.keys) {
      final value = member[field] ?? '';

      cells.add(
        DataCell(
          _editingRowIndex == index && _editingColumn == 'status'
              ? StatusDropdown(
                initialValue: _tagFields[field]?.first ?? '',
                onSelected: (String value) {
                  setState(() {
                    _members[_editingRowIndex!]['status'] = value;
                    _editingRowIndex = null;
                    _editingColumn = null;
                  });
                },
                isEditing:
                    _editingRowIndex == index && _editingColumn == 'status',
              )
              : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTagColor('status', member['status'], _tagFields),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(member['status'], style: TextStyle(fontSize: 12)),
              ),
          onTap: () => _editCell(index, 'status', member['status']),
        ),
      );
    }

    // 기본 셀
    cells.add(const DataCell(Text('')));
    return cells;
  }

  // 태그 배경색 가져오기
  Color _getTagColor(
    String field,
    String value,
    Map<String, dynamic> tagFields,
  ) {
    if (field == 'role') {
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
    // 새 필드 추가 로직
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('새 필드 추가'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: '필드 이름'),
                  controller: _textEditController,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          String newField = _textEditController.text;
                          if (newField.isNotEmpty) {
                            _textFields[newField] = [];
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('텍스트 필드'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          String newField = _textEditController.text;
                          if (newField.isNotEmpty) {
                            _tagFields[newField] = [];
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('태그 필드'),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _editCell(int rowIndex, String column, dynamic value) {
    setState(() {
      _editingRowIndex = rowIndex;
      _editingColumn = column;
      _textEditController.text = value;
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
                  columns: [
                    DataColumn2(
                      label: const Text('이름'),
                      size: ColumnSize.M,
                      tooltip: '멤버 이름',
                    ),
                    DataColumn2(
                      label: const Text('역할'),
                      size: ColumnSize.S,
                      tooltip: '역할',
                    ),
                    DataColumn2(
                      label: const Text('전화번호'),
                      size: ColumnSize.L,
                      tooltip: '연락처',
                    ),
                    DataColumn2(
                      label: const Text('GitHub'),
                      size: ColumnSize.M,
                      tooltip: 'GitHub 계정',
                    ),
                    DataColumn2(
                      label: const Text('상태'),
                      size: ColumnSize.S,
                      tooltip: '활동 상태',
                    ),
                    DataColumn2(
                      label: const Text('이메일'),
                      size: ColumnSize.M,
                      tooltip: '이메일 주소',
                    ),
                    DataColumn2(
                      label: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.add_sharp, size: 18),
                      ),
                      size: ColumnSize.M,
                    ),
                  ],
                  rows: List<DataRow>.generate(_members.length, (index) {
                    final member = _members[index];

                    return DataRow2(
                      cells: [
                        // 이름 셀
                        DataCell(
                          MouseRegion(
                            child:
                                _editingRowIndex == index &&
                                        _editingColumn == 'name'
                                    ? _buildEditableTextField(
                                      context,
                                      _textEditController,
                                      _saveEditedCell,
                                    )
                                    : Text(member['name']),
                          ),
                          onTap: () => _editCell(index, 'name', member['name']),
                        ),

                        // 역할 셀
                        DataCell(
                          _editingRowIndex == index && _editingColumn == 'role'
                              ? RoleDropdown(
                                initialValue: _tagFields['role']?.first ?? '',
                                onSelected: (String value) {
                                  setState(() {
                                    _members[_editingRowIndex!]['role'] = value;
                                    _editingRowIndex = null;
                                    _editingColumn = null;
                                  });
                                },
                                isEditing:
                                    _editingRowIndex == index &&
                                    _editingColumn == 'role',
                              )
                              : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      member['role'] == 'Frontend'
                                          ? Colors.green.shade100
                                          : member['role'] == 'Backend'
                                          ? Colors.blue.shade100
                                          : member['role'] == 'PM'
                                          ? Colors.purple.shade100
                                          : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  member['role'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          onTap: () => _editCell(index, 'role', member['role']),
                        ),

                        // 전화번호 셀
                        DataCell(
                          _editingRowIndex == index &&
                                  _editingColumn == 'phoneNumber'
                              ? _buildEditableTextField(
                                context,
                                _textEditController,
                                _saveEditedCell,
                              )
                              : Text(member['phoneNumber']),
                          onTap:
                              () => _editCell(
                                index,
                                'phoneNumber',
                                member['phoneNumber'],
                              ),
                        ),

                        // Github 셀
                        DataCell(
                          _editingRowIndex == index &&
                                  _editingColumn == 'github'
                              ? _buildEditableTextField(
                                context,
                                _textEditController,
                                _saveEditedCell,
                              )
                              : Text(member['github']),
                          onTap:
                              () =>
                                  _editCell(index, 'github', member['github']),
                        ),

                        // 상태 셀
                        DataCell(
                          _editingRowIndex == index &&
                                  _editingColumn == 'status'
                              ? StatusDropdown(
                                initialValue: _tagFields['status']?.first ?? '',
                                onSelected: (String value) {
                                  setState(() {
                                    _members[_editingRowIndex!]['status'] =
                                        value;
                                    _editingRowIndex = null;
                                    _editingColumn = null;
                                  });
                                },
                                isEditing:
                                    _editingRowIndex == index &&
                                    _editingColumn == 'status',
                              )
                              : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getTagColor(
                                    'status',
                                    member['status'],
                                    _tagFields,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  member['status'],
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                          onTap:
                              () =>
                                  _editCell(index, 'status', member['status']),
                        ),

                        // 이메일 셀
                        DataCell(
                          _editingRowIndex == index && _editingColumn == 'email'
                              ? _buildEditableTextField(
                                context,
                                _textEditController,
                                _saveEditedCell,
                              )
                              : Text(member['email']),
                          onTap:
                              () => _editCell(index, 'email', member['email']),
                        ),

                        // 빈 셀
                        const DataCell(Text('')),
                      ],
                    );
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
