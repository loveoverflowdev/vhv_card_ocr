// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

// import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:vhv_card_ocr/gen/assets.gen.dart';

import 'object_detection_state.dart';
import 'yolov8_object_detection.dart';

class ObjectDetectionCubit extends Cubit<ObjectDetectionState> {
  late final Yolov8ObjectDetection _objectDetection;

  ObjectDetectionCubit() : super(const ObjectDetectionState()) {
    _objectDetection = Yolov8ObjectDetection(
      modelPath: Assets.models.cornerFloat16, 
      labelPath: Assets.models.cornerFloat16Labels,
    );
  }

  Future<void> detectObject() async {
    if (state.imageFile == null) {
      return;
    }

    emit(state.loading());

    debugPrint('DECODING IMAGE ...');

    final img.Image? image = await state.imageFile!
      .readAsBytes()
      .then((value) => img.decodeImage(value));

    if (image == null) {
      return emit(state.copyWith(
        detectionStatus: ObjectDetectionStatus.error,
        errorMessage: 'Failed to decode image after picking.'
      ));
    }

    final imageHeight = image.height;
    final imageWidth = image.width;

    debugPrint('DETECTING OBJECT ...');

    final stopwatch = Stopwatch()..start();

    final boxes = await _objectDetection.analyseImage(image);

    try {
      final List<Map<String, dynamic>> results = [];

      final labeledImageResults = cropImage(image, detectedBoxes: boxes ?? []);

      debugPrint('DETECTING OBJECT DONE !');

      emit(state.copyWith(
        detectionStatus: ObjectDetectionStatus.success,
        rawResults: results,
        imageHeight: imageHeight,
        imageWidth: imageWidth,
        labeledImageResuls: 
          labeledImageResults,
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
      emit(state.copyWith(imageFile: File(photo.path)));
    }
  }

  List<MapEntry<String, img.Image>> cropImage(
    img.Image image, {
    required List<BoundingBox> detectedBoxes,
  }) {

    final List<MapEntry<String, img.Image>> croppedImageList = [];

    for (final box in detectedBoxes) {
      if (box.clsName == 'sex') {
        continue;
      }

      final x = box.x1 * image.width;
      final y = box.y1 * image.height;
      final width = box.w * image.width;
      final height = box.h * image.height;

      if (width == 0 || height == 0) continue;
      final widthPad = width * 0.05;
      final heightPad = height * 0.05;
      final croppedImage =
          img.copyCrop(
            image, x: (x - widthPad).round(), 
            y: (y - heightPad).round(), 
            width: (width + widthPad).round(), 
            height: (height + heightPad).round(),
          );

      croppedImageList.add(MapEntry(box.clsName, croppedImage));
    }

    return croppedImageList;
  }
}
