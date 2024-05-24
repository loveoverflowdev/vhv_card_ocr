
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'auth_session_config.dart';

class TextRecognizer {
  late final Future<Directory> _appDir;
  late final Uuid _uuid;

  TextRecognizer() {
    _uuid = const Uuid();
    _appDir = getApplicationDocumentsDirectory();
  }

  Future<String> processImage(File file) async {
    final domain = AuthSessionConfig.shared.getDomain();
    final uploadedImagePath = 
      await _uploadFile(file.path)
      .then(
        (data) => 'https://$domain/${data['path']}'
      );
    final ocrResult = await _callVhvOcr(imageUrl: uploadedImagePath);
    return ocrResult;
  }

  Future<Iterable<MapEntry<String, String>>> processMultiImages(List<String> filePaths) async {
    final outputZipPath = '${(await _appDir).path}/output${_uuid.v4()}.zip';

    await _zipFiles(filePaths, outputZipPath);

    final domain = AuthSessionConfig.shared.getDomain();

    final uploadedZipPath = 
      await _uploadFile(outputZipPath)
      .then(
        (data) => 'https://$domain/${data['path']}'
      );

    final ocrResult = await _callVhvOcrPassZip(zipUrl: uploadedZipPath);

    final outputZipFile = File(outputZipPath);
    if (outputZipFile.existsSync()) {
      outputZipFile.delete();
    }

    final entries = (ocrResult['message'] as Iterable).map((e) {
      final only = (e as Map).entries.first;
      return MapEntry<String, String>(only.key, only.value[0]);
    });

    return entries;
  }
}

Future<Map<String, dynamic>> _callVhvOcrPassZip({
  required String zipUrl,
}) async {
  final dio = await AuthSessionConfig.shared.getDio();
  const url = 'https://ai.vhv.vn/chatbot-vhv/ocr-vhv';
  final response = await dio.post(url, data: {
    "zipUrl": zipUrl,
    "token": "ai_team_vhv",
    // "numThreads": 4,
  });
  return response.data;
}

Future<String> _callVhvOcr({
  required String imageUrl,
}) async {
  final dio = await AuthSessionConfig.shared.getDio();
  const url = 'https://ai.vhv.vn/chatbot-vhv/ocr-vhv';
  final response = await dio.post(url, data: {
    "imageUrl": imageUrl,
    "token": "ai_team_vhv"
  });
  return response.data['message'][0];
}

Future<Map<String, dynamic>> _uploadFile(String filePath, {
  String? fileName,
  String? fieldName,
}) async {
  final authSessionConfig = AuthSessionConfig.shared;

  final csrfToken = await authSessionConfig.getSecurityToken();
  final site = authSessionConfig.getSite();
  final dio = authSessionConfig.getDio();
  final domain = authSessionConfig.getDomain();
  
  final MultipartFile file = await MultipartFile.fromFile(filePath, filename: fileName);
  Map<String, dynamic> params = {
    'site': site,
    'securityToken': csrfToken,
    fieldName ?? 'qqfile': file
  };

  String url = 'https://$domain/qqupload.php';

  final response = await (await dio).post(
    url,
    data: FormData.fromMap(params),
    onSendProgress: (int sent, int total) {
      debugPrint('sent: $sent, total: $total');
    },
    options: Options(
      headers: {'Content-Type': 'application/json'},
      responseType: ResponseType.json
    ),
  );

  debugPrint(response.data);

  return jsonDecode(response.data);
}

Future<void> _zipFiles(List<String> filePaths, String outputZipFilePath) async {
  // Create a ZipEncoder
  final encoder = ZipEncoder();

  // Create an archive to store the files
  final archive = Archive();

  // Add files to the archive
  for (var filePath in filePaths) {
    final file = File(filePath);
    if (await file.exists()) {
      final fileName = file.uri.pathSegments.last;
      final fileBytes = file.readAsBytesSync();
      final archiveFile = ArchiveFile(fileName, fileBytes.length, fileBytes);
      archive.addFile(archiveFile);
    }
  }

  // Encode the archive to zip format
  final zipBytes = encoder.encode(archive);

  // Write the zip file to disk
  final zipFile = File(outputZipFilePath);
  zipFile.writeAsBytesSync(zipBytes!);
}

// void main() {
//   final filesToZip = [
//     'path/to/file1.txt',
//     'path/to/file2.jpg',
//   ];
//   final outputZip = 'path/to/output.zip';

//   zipFiles(filesToZip, outputZip);
//   print('Files zipped successfully');
// }
