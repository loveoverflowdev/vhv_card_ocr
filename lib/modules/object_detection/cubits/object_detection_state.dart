// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:image/image.dart' as img;

class ObjectDetectionState extends Equatable {
  final int currentRequestDurationMiliseconds;

  final ObjectDetectionStatus detectionStatus;
  final ModelLoadingStatus modelLoadingStatus;

  final int imageHeight;
  final int imageWidth;

  final List<Map<String, dynamic>> rawResults;
  final List<MapEntry<String, img.Image>> labeledImageResuls;

  final File? imageFile;
  final String? errorMessage;

  const ObjectDetectionState({
    this.currentRequestDurationMiliseconds = 0,
    this.detectionStatus = ObjectDetectionStatus.initial,
    this.modelLoadingStatus = ModelLoadingStatus.initial,
    this.imageHeight = 1,
    this.imageWidth = 1,
    this.rawResults = const [],
    this.labeledImageResuls = const [],
    this.imageFile,
    this.errorMessage,
  });

  @override
  List<Object?> get props {
    return [
      detectionStatus,
      modelLoadingStatus,
      imageHeight,
      imageWidth,
      rawResults,
      imageFile,
      errorMessage,
      labeledImageResuls,
      currentRequestDurationMiliseconds,
    ];
  }

  ObjectDetectionState loading() => copyWith(detectionStatus: ObjectDetectionStatus.loading, rawResults: [], errorMessage: '',);

  ObjectDetectionState copyWith({
    int? currentRequestDurationMiliseconds,
    ObjectDetectionStatus? detectionStatus,
    ModelLoadingStatus? modelLoadingStatus,
    int? imageHeight,
    int? imageWidth,
    List<Map<String, dynamic>>? rawResults,
    List<MapEntry<String, img.Image>>? labeledImageResuls,
    File? imageFile,
    String? errorMessage,
  }) {
    return ObjectDetectionState(
      currentRequestDurationMiliseconds: currentRequestDurationMiliseconds ?? this.currentRequestDurationMiliseconds,
      detectionStatus: detectionStatus ?? this.detectionStatus,
      modelLoadingStatus: modelLoadingStatus ?? this.modelLoadingStatus,
      imageHeight: imageHeight ?? this.imageHeight,
      imageWidth: imageWidth ?? this.imageWidth,
      rawResults: rawResults ?? this.rawResults,
      labeledImageResuls: labeledImageResuls ?? this.labeledImageResuls,
      imageFile: imageFile ?? this.imageFile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum ObjectDetectionStatus {
  initial,
  loading,
  success,
  error,
}

enum ModelLoadingStatus {
  initial,
  loading,
  loaded,
}
