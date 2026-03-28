import 'package:dio/dio.dart' as d;
import '../core/api.dart';

class FaceService {
  /// 上传人脸照片进行录入
  /// 返回是否成功
  static Future<bool> enrollFace(String imagePath) async {
    final formData = d.FormData.fromMap({
      'file': await d.MultipartFile.fromFile(imagePath, filename: 'face.jpg'),
    });
    final resp = await dio.post('/face/enroll', data: formData);
    return resp.statusCode == 200 && resp.data['success'] == true;
  }

  /// 上传人脸照片进行验证
  /// 返回 (是否匹配, 相似度分数)
  static Future<(bool matched, double similarity)> verifyFace(String imagePath) async {
    final formData = d.FormData.fromMap({
      'file': await d.MultipartFile.fromFile(imagePath, filename: 'face.jpg'),
    });
    final resp = await dio.post('/face/verify', data: formData);
    final data = resp.data;
    return (data['matched'] as bool, (data['similarity'] as num).toDouble());
  }
}
