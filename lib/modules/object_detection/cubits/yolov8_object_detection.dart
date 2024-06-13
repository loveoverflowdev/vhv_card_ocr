import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class BoundingBox {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double cx;
  final double cy;
  final double w;
  final double h;
  final double cnf;
  final int cls;
  final String clsName;

  BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.cnf,
    required this.cls,
    required this.clsName,
  });

  @override
  String toString() {
    return 'BoundingBox('
           'x1: $x1, y1: $y1, x2: $x2, y2: $y2, '
           'cx: $cx, cy: $cy, w: $w, h: $h, '
           'cnf: $cnf, cls: $cls, clsName: $clsName)';
  }

}

class Yolov8ObjectDetection {
  late final Future<Interpreter> _interpreter;
  late final Future<List<String>> _labels;

  Yolov8ObjectDetection({
    required String modelPath,
    required String labelPath,
  }) {
    _interpreter = _loadModel(modelPath);
    _labels = _loadLabels(labelPath);
  }

  void close() async {
    (await _interpreter).close();
  }

  Future<Interpreter> _loadModel(String modelPath) async {
    log('Loading interpreter options...');
    final interpreterOptions = InterpreterOptions();

    // Use XNNPACK Delegate
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }

    // Use Metal Delegate
    if (Platform.isIOS) {
      interpreterOptions.addDelegate(GpuDelegate());
    }

    log('Loading interpreter...');
    return Interpreter.fromAsset(modelPath, options: interpreterOptions);
  }

  Future<List<String>> _loadLabels(String labelPath) async {
    log('Loading labels...');
    final labelsRaw = await rootBundle.loadString(labelPath);
    return labelsRaw.split('\n');
  }

  Future<List<BoundingBox>?> analyseImage(img.Image image) async {
    log('Analysing image...');
    final interpreter = await _interpreter;

    final inputSensor = interpreter.getInputTensor(0);
    final outputSensor = interpreter.getOutputTensor(0);

    // 
    final outputBatchSize = outputSensor.shape[0];

    //
    final inputWidth = inputSensor.shape[1];
    final inputHeight = inputSensor.shape[2];

    final numChannels = outputSensor.shape[1];
    final numberElements = outputSensor.shape[2];

    final imageInput = img.copyResize(
      image,
      width: inputWidth,
      height: inputHeight,
      maintainAspect: true,
    );

    final imageMatrix = List.generate(
      imageInput.height,
      (y) => List.generate(
        imageInput.width,
        (x) {
          final pixel = imageInput.getPixel(x, y);
          return [pixel.rNormalized, pixel.gNormalized, pixel.bNormalized];
        },
      ),
    );

    // [1, 14, 13125]
    final output = List<num>
      .filled(outputBatchSize * numChannels * numberElements, 0)
      .reshape([outputBatchSize, numChannels, numberElements]);

    interpreter.run([imageMatrix], output);

    final labels = await _labels;

    final outputMatrix = (output.first as List<dynamic>).map((e) => e as List<dynamic>).toList();

    return bestBox(
      array: outputMatrix.flatten(), 
      numElements: numberElements, 
      numChannel: numChannels, 
      confidenceThreshold: 0.5, 
      labels: labels,
    );

    // drawBoundingBoxes(imageInput, bestBoxes ?? []);

    // return img.encodeJpg(imageInput);
  }

  // void drawBoundingBoxes(img.Image image, List<BoundingBox> boxes) {
  //   for (var box in boxes) {
  //     // Convert normalized coordinates back to the image size
  //     int x1 = (box.x1 * image.width).toInt();
  //     int y1 = (box.y1 * image.height).toInt();
  //     int x2 = (box.x2 * image.width).toInt();
  //     int y2 = (box.y2 * image.height).toInt();

  //     // Draw the rectangle on the image
  //     img.drawRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: img.ColorRgb8(255, 0, 0)); // Red color
  //   }
  // }
}

List<BoundingBox>? bestBox({
  required List<double> array,
  required int numElements,
  required int numChannel,
  required double confidenceThreshold,
  required List<String> labels,
}) {
  List<BoundingBox> boundingBoxes = [];

  for (int c = 0; c < numElements; c++) {
    double maxConf = -1.0;
    int maxIdx = -1;
    int j = 4;
    int arrayIdx = c + numElements * j;
    while (j < numChannel) {
      if (array[arrayIdx] > maxConf) {
        maxConf = array[arrayIdx];
        maxIdx = j - 4;
      }
      j++;
      arrayIdx += numElements;
    }

    if (maxConf > confidenceThreshold) {
      String clsName = labels[maxIdx];
      double cx = array[c]; // 0
      double cy = array[c + numElements]; // 1
      double w = array[c + numElements * 2];
      double h = array[c + numElements * 3];
      double x1 = cx - (w / 2);
      double y1 = cy - (h / 2);
      double x2 = cx + (w / 2);
      double y2 = cy + (h / 2);

      if (x1 < 0 || x1 > 1) continue;
      if (y1 < 0 || y1 > 1) continue;
      if (x2 < 0 || x2 > 1) continue;
      if (y2 < 0 || y2 > 1) continue;

      boundingBoxes.add(BoundingBox(
        x1: x1 ,
        y1: y1 ,
        x2: x2 ,
        y2: y2 ,
        cx: cx ,
        cy: cy ,
        w: w ,
        h: h ,
        cnf: maxConf,
        cls: maxIdx,
        clsName: clsName,
      ));
    }
  }

  if (boundingBoxes.isEmpty) return null;

  return applyNMS(boundingBoxes, 0.7);
}

List<BoundingBox> applyNMS(List<BoundingBox> boxes, double iouThreshold) {
  List<BoundingBox> sortedBoxes = List.from(boxes)..sort((a, b) => b.cnf.compareTo(a.cnf));
  List<BoundingBox> selectedBoxes = [];

  while (sortedBoxes.isNotEmpty) {
    BoundingBox first = sortedBoxes.first;
    selectedBoxes.add(first);
    sortedBoxes.removeAt(0);

    sortedBoxes.removeWhere((nextBox) => calculateIoU(first, nextBox) >= iouThreshold);
  }

  return selectedBoxes;
}

double calculateIoU(BoundingBox box1, BoundingBox box2) {
  num x1 = box1.x1 > box2.x1 ? box1.x1 : box2.x1;
  num y1 = box1.y1 > box2.y1 ? box1.y1 : box2.y1;
  num x2 = box1.x2 < box2.x2 ? box1.x2 : box2.x2;
  num y2 = box1.y2 < box2.y2 ? box1.y2 : box2.y2;

  num intersectionArea = (x2 - x1 > 0 ? x2 - x1 : 0) * (y2 - y1 > 0 ? y2 - y1 : 0);
  num box1Area = box1.w * box1.h;
  num box2Area = box2.w * box2.h;

  return intersectionArea / (box1Area + box2Area - intersectionArea);
}
