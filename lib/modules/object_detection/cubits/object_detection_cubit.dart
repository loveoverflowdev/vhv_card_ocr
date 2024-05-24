// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vision/flutter_vision.dart';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vhv_card_ocr/gen/assets.gen.dart';
import 'package:image/image.dart' as img;

import 'object_detection_state.dart';

class ObjectDetectionCubit extends Cubit<ObjectDetectionState> {
  final FlutterVision _vision;
  late final Future<String> _appDirPath;
  late final Uuid _uuid;
  late final List<VoidCallback> _removeFileTasks;

  String _vietsubLabel(String label) {
    switch (label) {
      case 'id': return 'Mã số';
      case 'name': return 'Tên';
      case 'birdthday': return 'Ngày sinh';
      case 'birdplace': return 'Nơi sinh';
      case 'dayIn': return 'Ngày vào';
      case 'dayOri': return 'Chính thức ngày';
      case 'rePlace': return 'Nơi cấp';
      case 'reDay': return 'Ngày cấp';
      case 'image': return 'Ảnh';
      case 'sex': return 'Giới tính';
      default: return label;
    }
  }

  ObjectDetectionCubit({
    required FlutterVision vision,
  }) : _vision = vision, super(const ObjectDetectionState()) {
    loadYoloModel(labelsFilePath: Assets.models.vhvObjectLabels, modelPath: Assets.models.vhvYolov8,modelVersion: 'yolov8');

    _getAppPath();

    _uuid = const Uuid();
    _removeFileTasks = [];
  }

  void _getAppPath() async {
    _appDirPath = getApplicationDocumentsDirectory().then((value) => value.path);
  }

  // Future<String> _createUniqueFilePath({
  //   final String suffix = '',
  // }) async {
  //   return '${await _appDirPath}/${_uuid.v4()}$suffix';
  // }

  void loadYoloModel({
    required String labelsFilePath,
    required String modelPath,
    String modelVersion = 'yolov5',
    bool quantization = false,
    int numThreads = 4,
    bool useGpu = true,
  }) {
    
    _vision.loadYoloModel(
      labels: labelsFilePath,
      modelPath: modelPath,
      modelVersion: modelVersion,
      quantization: quantization,
      numThreads: numThreads,
      useGpu: useGpu,
    );
  }

  @override
  Future<void> close() async {
    for (var task in _removeFileTasks) {
      task();
    }
    await _vision.closeTesseractModel();
    await _vision.closeYoloModel();
    return super.close();
  }

  Future<void> detectObject() async {
    emit(state.loading());

    debugPrint('DECODING IMAGE ...');

    Uint8List bytes = await state.imageFile!.readAsBytes();
    final image = await decodeImageFromList(bytes);

    final imageHeight = image.height;
    final imageWidth = image.width;

    debugPrint('DETECTING OBJECT ...');

    final stopwatch = Stopwatch()..start();

    try {
      final results = await _vision.yoloOnImage(
          bytesList: bytes,
          imageHeight: image.height,
          imageWidth: image.width,
          iouThreshold: 0.8,
          confThreshold: 0.4,
          classThreshold: 0.5,
      );

      final labeledImageResults = cropImage(bytes, objectDetectionResults: results);

      

      debugPrint('DETECTING OBJECT DONE !');

      emit(state.copyWith(
        detectionStatus: ObjectDetectionStatus.success,
        rawResults: results,
        imageHeight: imageHeight,
        imageWidth: imageWidth,
        labeledImageResuls: 
          labeledImageResults.map((e) => MapEntry(_vietsubLabel(e.key), e.value)).toList(),
      ));
    } on Exception catch (error) {

      debugPrint('DETECTING OBJECT ERROR: $error.');

      emit(
        state.copyWith(detectionStatus: ObjectDetectionStatus.error, 
        errorMessage: error.toString(),
    ));
    }

    stopwatch.stop();
    
    final currentRequestDurationMiliseconds = stopwatch.elapsedMilliseconds;
    emit(state.copyWith(currentRequestDurationMiliseconds: currentRequestDurationMiliseconds));
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Capture a photo
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);

    if (photo != null) {
      // final decodedPhoto = img.decodeImage(await photo.readAsBytes())!;
      // final resizedPhoto = img.copyResize(decodedPhoto, height: 1920, width: decodedPhoto.width * 1920 ~/ decodedPhoto.height);
      // final resizedPhotoFile = await File(await _createUniqueFilePath(suffix: '.png')).writeAsBytes(img.encodePng(resizedPhoto));

      // emit(state.copyWith(imageFile: resizedPhotoFile));

      // _removeFileTasks.add(() { resizedPhotoFile.delete(); });

      emit(state.copyWith(imageFile: File(photo.path)));
    }

    
  }

  List<MapEntry<String, img.Image>> cropImage(
  Uint8List src, {
    required List<Map<String, dynamic>> objectDetectionResults,
  }) {
    final img.Image srcImage = img.decodeImage(src)!;

    final List<MapEntry<String, img.Image>> croppedImageList = [];

    for (final result in objectDetectionResults) {
      if (result['tag'] == 'sex') continue;

      final x = result["box"][0].round();
      final y = result["box"][1].round();
      final width = (result["box"][2] - result["box"][0]).round();
      final height = (result["box"][3] - result["box"][1]).round();

      if (width == 0 || height == 0) continue;
      final widthPad = (width * 0.05).round();
      final heightPad = (height * 0.05).round();
      final croppedImage =
          img.copyCrop(srcImage, x: x - widthPad, y: y - heightPad, width: width + widthPad, height: height + heightPad);

      croppedImageList.add(MapEntry(result['tag'], croppedImage));
      // left: result["box"][0] * factorX,
      // top: result["box"][1] * factorY + pady,
      // width: (result["box"][2] - result["box"][0]) * factorX,
      // height: (result["box"][3] - result["box"][1]) * factorY,
      //
    }

    return croppedImageList;
  }
}
