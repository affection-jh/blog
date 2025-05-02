import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../model/document.dart';
import '../model/editor_state.dart';

/// 이미지 관련 유틸리티 클래스
class ImageUtils {
  static final ImagePicker _imagePicker = ImagePicker();

  /// 갤러리에서 이미지 선택
  static Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;

      return image.path;
    } catch (e) {
      debugPrint('이미지 선택 오류: $e');
      return null;
    }
  }

  /// 카메라로 이미지 촬영
  static Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return null;

      return image.path;
    } catch (e) {
      debugPrint('카메라 이미지 촬영 오류: $e');
      return null;
    }
  }

  /// 다중 이미지 선택
  static Future<List<String>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      return images.map((image) => image.path).toList();
    } catch (e) {
      debugPrint('다중 이미지 선택 오류: $e');
      return [];
    }
  }

  /// 이미지 위젯 생성
  static Widget buildImageWidget(
    String? path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    if (path == null || path.isEmpty) {
      // 이미지가 없는 경우 플레이스홀더 표시
      return Container(
        width: width,
        height: height ?? 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(Icons.image, color: Colors.grey.shade600, size: 48),
        ),
      );
    }

    // 이미지 형식에 따라 다른 위젯 반환
    if (path.startsWith('http://') || path.startsWith('https://')) {
      // 네트워크 이미지
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame == null) {
            return _buildLoadingPlaceholder(width, height);
          }
          return child;
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder(width, height);
        },
      );
    } else {
      // 로컬 이미지
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder(width, height);
        },
      );
    }
  }

  /// 로딩 중 플레이스홀더
  static Widget _buildLoadingPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: CircularProgressIndicator(color: Colors.grey.shade600),
      ),
    );
  }

  /// 이미지 로드 실패 플레이스홀더
  static Widget _buildErrorPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, color: Colors.grey.shade600, size: 48),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 이미지 처리 유틸리티
  static Future<void> pickAndInsertImage(EditorState editorState) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final imagePath = await _saveImage(pickedFile);

        // 새 이미지 블록 생성
        final imageBlock = Block(
          id: Uuid().v4(),
          type: BlockType.image,
          content: '',
          imagePath: imagePath,
        );

        // 현재 블록 다음에 이미지 블록 삽입
        final currentIndex = editorState.currentBlockIndex;
        editorState.document.blocks.insert(currentIndex + 1, imageBlock);

        // 빈 단락 블록 추가 (이미지 다음에 콘텐츠 이어서 작성 가능하도록)
        final paragraphBlock = Block(
          id: Uuid().v4(),
          type: BlockType.paragraph,
          content: '',
        );

        editorState.document.blocks.insert(currentIndex + 2, paragraphBlock);

        // 상태 업데이트 및 새 단락으로 포커스 이동
        editorState.updateCurrentBlockIndex(currentIndex + 2);
        editorState.notifyListeners();
      }
    } catch (e) {
      print('이미지 추가 오류: $e');
    }
  }

  /// 이미지 파일 저장
  static Future<String> _saveImage(XFile pickedFile) async {
    try {
      // 앱 문서 디렉토리 가져오기
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/images');

      // 이미지 디렉토리 생성 (없는 경우)
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // 고유한 파일명 생성
      final fileExt = path.extension(pickedFile.path);
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final savedPath = '${imageDir.path}/$fileName';

      // 파일 복사
      final imageFile = File(pickedFile.path);
      await imageFile.copy(savedPath);

      return savedPath;
    } catch (e) {
      print('이미지 저장 오류: $e');
      return '';
    }
  }

  /// 이미지 크기 조정 위젯
  static Widget buildResizableImage(String imagePath, {double maxWidth = 500}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Image.file(File(imagePath), fit: BoxFit.contain),
    );
  }

  /// 이미지 삭제
  static Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('이미지 삭제 오류: $e');
      return false;
    }
  }
}
