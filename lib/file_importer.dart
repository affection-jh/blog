// 데스크톱과 웹에서 파일 드래그 앤 드롭을 처리하기 위한 클래스
import 'package:blog/editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:universal_html/html.dart' as html;

class FileDropWrapper extends StatelessWidget {
  final Widget child;
  final Function(dynamic file) onFileDropped;

  const FileDropWrapper({
    Key? key,
    required this.child,
    required this.onFileDropped,
  }) : super(key: key);

  // 웹에서 드래그 앤 드롭 이벤트를 처리하는 JavaScript 코드 설정
  void _setupWebDropzone(BuildContext context) {
    if (kIsWeb) {
      // HTML 드래그 앤 드롭 이벤트를 처리하는 JavaScript 함수 등록
      final dropzone = html.document.body;

      dropzone?.addEventListener('dragover', (event) {
        final e = event as html.MouseEvent;
        e.preventDefault();
        e.stopPropagation();
        html.document.body?.classes.add('drag-over');
      });

      dropzone?.addEventListener('dragleave', (event) {
        final e = event as html.MouseEvent;
        e.preventDefault();
        e.stopPropagation();
        html.document.body?.classes.remove('drag-over');
      });

      dropzone?.addEventListener('drop', (event) async {
        final e = event as html.MouseEvent;
        e.preventDefault();
        e.stopPropagation();
        html.document.body?.classes.remove('drag-over');

        // universal_html 패키지는 DragEvent를 직접 지원하지 않음
        // 대신 클라이언트 측에서 FileList를 직접 가져옴
        final transfer = e.dataTransfer;
        final htmlFiles = transfer?.files;

        if (htmlFiles != null && htmlFiles.isNotEmpty) {
          for (var i = 0; i < htmlFiles.length; i++) {
            final file = htmlFiles[i];
            if (file.type.startsWith('image/')) {
              final imageUrl = await WebImagePicker.createFileUrl(file);
              onFileDropped(imageUrl);
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 웹에서 드래그 앤 드롭 초기화
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupWebDropzone(context);
      });
      return child;
    }

    // 네이티브 플랫폼에서는 기존 방식 유지
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: DragTarget<List<String>>(
            builder:
                (context, candidateData, rejectedData) => Container(
                  color:
                      candidateData.isNotEmpty
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.transparent,
                  child: SizedBox.expand(),
                ),
            onWillAcceptWithDetails: (details) {
              return details.data.isNotEmpty;
            },
            onAcceptWithDetails: (details) async {
              for (var filePath in details.data) {
                try {
                  onFileDropped(filePath);
                } catch (e) {
                  print('드래그 앤 드롭 에러: $e');
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
