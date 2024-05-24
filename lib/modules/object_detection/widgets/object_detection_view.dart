import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vhv_card_ocr/modules/object_detection/cubits/cubits.dart';

import '../../text_recognition/text_recognition.dart';

class ObjectDetectionView extends StatelessWidget {
  const ObjectDetectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ObjectDetectionCubit, ObjectDetectionState>(
      listenWhen: (previous, current) =>
          previous.labeledImageResuls != current.labeledImageResuls,
      listener: (context, state) async {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ImageListView(imageList: state.labeledImageResuls.map((e) => e.value).toList(), ),
        //   ),
        // );

        final imageFile = context.read<ObjectDetectionCubit>().state.imageFile;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TextRecognitionPage(
              coverImageFile: imageFile,
              labeledImageResults: state.labeledImageResuls,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
            buildWhen: (previous, current) =>
                previous.modelLoadingStatus != current.modelLoadingStatus,
            builder: (context, state) {
              return Visibility(
                visible: state.modelLoadingStatus == ModelLoadingStatus.loading,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
          BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
            buildWhen: (previous, current) =>
                previous.modelLoadingStatus != current.modelLoadingStatus,
            builder: (context, state) {
              return Visibility(
                visible: state.detectionStatus == ObjectDetectionStatus.loading,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
          //
          BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
            buildWhen: (previous, current) =>
                previous.imageFile != current.imageFile,
            builder: (context, state) {
              if (state.imageFile == null) {
                return const Center(
                  child:  Icon(Icons.upload, size: 100, color: Colors.grey,),
                );
              }
              return Image.file(state.imageFile!);
            },
          ),
          //
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () =>
                      context.read<ObjectDetectionCubit>().pickImage(),
                  child: const Text('Chọn ảnh'),
                ),
                const SizedBox(width: 8),
                BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
                  builder: (context, state) {
                    if (state.detectionStatus == ObjectDetectionStatus.loading) {
                      return const SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator());
                    }
                    return ElevatedButton(
                      onPressed: () =>
                          context.read<ObjectDetectionCubit>().detectObject(),
                      child: const Text('Quét ảnh'),
                    );
                  },
                )
              ],
            ),
          ),
          //
          // BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
          //   buildWhen: (previous, current) =>
          //       previous.rawResults != current.rawResults,
          //   builder: (context, state) {
          //     final list = [
          //       ...displayBoxesAroundRecognizedObjects(
          //         screenSize: size,
          //         results: state.rawResults,
          //         imageWidth: state.imageWidth.toDouble(),
          //         imageHeight: state.imageHeight.toDouble(),
          //       ),
          //     ];

          //     return Stack(
          //       fit: StackFit.expand,
          //       children: list,
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  List<Widget> displayBoxesAroundRecognizedObjects({
    required Size screenSize,
    required List<dynamic> results,
    required double imageWidth,
    required double imageHeight,
  }) {
    if (results.isEmpty) return [];

    double factorX = screenSize.width / (imageWidth);
    double imgRatio = imageWidth / imageHeight;
    double newWidth = imageWidth * factorX;
    double newHeight = newWidth / imgRatio;
    double factorY = newHeight / (imageHeight);

    double pady = (screenSize.height - newHeight) / 2;

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return results.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY + pady,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}

// class PolygonPainter extends CustomPainter {
//   final List<Map<String, double>> points;

//   PolygonPainter({required this.points});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color.fromARGB(129, 255, 2, 124)
//       ..strokeWidth = 2
//       ..style = PaintingStyle.fill;

//     final path = Path();
//     if (points.isNotEmpty) {
//       path.moveTo(points[0]['x']!, points[0]['y']!);
//       for (var i = 1; i < points.length; i++) {
//         path.lineTo(points[i]['x']!, points[i]['y']!);
//       }
//       path.close();
//     }

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return false;
//   }
// }
