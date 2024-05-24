import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:uuid/uuid.dart';
import 'package:vhv_card_ocr/modules/object_detection/cubits/cubits.dart';

import '../../shared/text_recognizer.dart';
import '../commons/time_counter.dart';

class TextRecognitionPage extends StatefulWidget {
  final File? coverImageFile;

  final List<MapEntry<String, img.Image>> labeledImageResults;

  const TextRecognitionPage({
    super.key,
    required this.labeledImageResults,
    this.coverImageFile,
  });

  @override
  State<TextRecognitionPage> createState() => _TextRecognitionPageState();
}

class _TextRecognitionPageState extends State<TextRecognitionPage> {
  late final TextRecognizer _textRecognizer;
  late List<MapEntry<String, img.Image>> _labeledImageResults;
  late String _imageDirPath;
  late Uuid _uuid;

  bool _isLoading = false;

  late Map<String, String> _labeledTextResults;

  @override
  void initState() {
    super.initState();
    _labeledImageResults = widget.labeledImageResults;
    _labeledTextResults = {};
    _textRecognizer = TextRecognizer();

    _uuid = const Uuid();

    _recognizeText();
  }

  Future<void> _initDirPath() async {
    final directory = await getApplicationDocumentsDirectory();
    _imageDirPath = directory.path;
  }

  // Widget _imagesWithKey(String key) {
  //   final List<Widget> children = [];

  //   for (final e in _labeledImageResults) {
  //     if (e.key == key) {
  //       children.add(Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 4.0),
  //         child: Image.memory(
  //           img.encodePng(e.value),
  //           fit: BoxFit.fitHeight,
  //         ),
  //       ));
  //     }
  //   }
  //   return SizedBox(
  //     height: 60,
  //     child: ListView(
  //       padding: const EdgeInsets.all(4),
  //       scrollDirection: Axis.horizontal,
  //       children: children,
  //     ),
  //   );
  // }

  // void _recognizeText() async {
  //   setState(() {
  //     _isLoading = true;
  //   });

  //   await _initDirPath();

  //   for (final result in _labeledImageResults) {
  //     final path = "$_imageDirPath/${_uuid.v4()}.png";
  //     final photo = result.value;
  //     final resizedPhoto = img.copyResize(photo,
  //         height: 48, width: photo.width * 48 ~/ photo.height);

  //     final imageFile = File(path);
  //     await imageFile.writeAsBytes(img.encodePng(resizedPhoto));

  //     // final decodedPhoto = img.decodeImage(await photo.readAsBytes())!;
  //     // final resizedPhoto = img.copyResize(decodedPhoto, height: 1920, width: decodedPhoto.width * 1920 ~/ decodedPhoto.height);
  //     // final resizedPhotoFile = await File(await _createUniqueFilePath(suffix: '.png')).writeAsBytes(img.encodePng(resizedPhoto));

  //     // emit(state.copyWith(imageFile: resizedPhotoFile));

  //     // _removeFileTasks.add(() { resizedPhotoFile.delete(); });

  //     final String recognizedText =
  //         await _textRecognizer.processImage(imageFile);

  //     if (_labeledTextResults.containsKey(result.key)) {
  //       _labeledTextResults[result.key] =
  //           '${_labeledTextResults[result.key]} $recognizedText';
  //     } else {
  //       _labeledTextResults[result.key] = recognizedText;
  //     }

  //     imageFile.delete();
  //   }

  //   setState(() {
  //     _isLoading = false;
  //   });
  // }

  int _labelWeight(String label) {
    switch (label) {
      case 'Mã số': return 1;
      case 'Tên': return 2;
      case 'Ngày sinh': return 3;
      case 'Nơi sinh': return 4;
      case 'Ngày vào': return 5;
      case 'Chính thức ngày': return 6;
      case 'Nơi cấp': return 6;
      case 'Ngày cấp': return 7;
      case 'Ảnh': return 8;
      case 'Giới tính': return 9;
      default: return 1000;
    }
  }

  int _labelCompare(String a, String b) {
    final weightA = _labelWeight(a);
    final weightB = _labelWeight(b);
    if (weightA == weightB) {
      return 0;
    }
    return weightA > weightB ? 1 : -1;
  }

  void _recognizeText() async {
    setState(() {
      _isLoading = true;
    });

    await _initDirPath();

    final imageFileEntries = <MapEntry<String, File>>[];

    for (final result in _labeledImageResults) {
      final path = "$_imageDirPath/${_uuid.v4()}.png";
      final photo = result.value;
      final resizedPhoto = img.copyResize(photo,
          height: 48, width: photo.width * 48 ~/ photo.height);

      final imageFile = File(path);
      await imageFile.writeAsBytes(img.encodePng(resizedPhoto));

      imageFileEntries.add(MapEntry(result.key, imageFile));

      // final String recognizedText =
      //     await _textRecognizer.processImage(imageFile);

      // if (_labeledTextResults.containsKey(result.key)) {
      //   _labeledTextResults[result.key] =
      //       '${_labeledTextResults[result.key]} $recognizedText';
      // } else {
      //   _labeledTextResults[result.key] = recognizedText;
      // }

      // imageFile.delete();
    }

    final ocrResults = await _textRecognizer.processMultiImages(imageFileEntries.map((e) => e.value.path).toList());

    for (final result in ocrResults) {
      for (final entry in imageFileEntries) {
        if (entry.value.path.contains(result.key)) {
          final key = entry.key;
          final value = result.value;

          if (_labeledTextResults.containsKey(key)) {
            _labeledTextResults[key] = '${_labeledTextResults[key]} ${value}';
          } else {
            _labeledTextResults[key] = value;
          }

          break;
        }
      }
    }

    for (var element in imageFileEntries) {
      element.value.delete();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final labeledTextResultList = _labeledTextResults.entries.toList();
    labeledTextResultList.sort((a, b) => _labelCompare(a.key, b.key));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BlocBuilder<ObjectDetectionCubit, ObjectDetectionState>(
                    buildWhen: (previous, current) => previous.currentRequestDurationMiliseconds != current.currentRequestDurationMiliseconds,
                    builder: (context, state) {
                      return TimeCounter(
                        title: 'Object Labeling',
                        isLoading: false,
                        initialMilliseconds: state.currentRequestDurationMiliseconds,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TimeCounter(
                    title: 'Request OCR API',
                    isLoading: _isLoading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Stack(
              children: [
                ListView.separated(
                  padding: const EdgeInsets.all(8),
                  shrinkWrap: true,
                  itemCount: labeledTextResultList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      if (widget.coverImageFile != null) {
                        final imageWidget = Image.file(widget.coverImageFile!);
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => PhotoPage(imageProvider: imageWidget.image,)));
                          },
                          child: imageWidget,
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }
                    final result = labeledTextResultList[index - 1];
                    final controllerFilled =
                        TextEditingController(text: result.value);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Flexible(
                        //   child: ListTile(
                        //     leading: Text(
                        //       '${result.key}:',
                        //       style: const TextStyle(
                        //         fontWeight: FontWeight.bold,
                        //         fontSize: 20,
                        //       ),
                        //     ),
                        //     title: Text(
                        //       result.value,
                        //       style: const TextStyle(
                        //         fontSize: 20,
                        //       ),
                        //     ),
                        //   ),
                        // ),

                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            controller: controllerFilled,
                            decoration: InputDecoration(
                              // prefixIcon: const Icon(Icons.search),
                              suffixIcon: _ClearButton(
                                controller: controllerFilled,
                              ),
                              labelText: result.key,
                              hintText: 'Input ...',
                              filled: true,
                            ),
                          ),
                        ),
                        // _imagesWithKey(result.key),
                      ],
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return const SizedBox(height: 16, child: Divider());
                  },
                ),
                Center(
                  child: Visibility(
                    visible: _isLoading,
                    child: const SizedBox(
                      height: 48,
                      width: 48,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({this.controller});

  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => controller?.clear(),
      );
}

class PhotoPage extends StatelessWidget {
  final ImageProvider<Object>? imageProvider;

  const PhotoPage({super.key, this.imageProvider,});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thẻ Đảng Viên'),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: imageProvider,
        ),
      ),
    );
  }
}
