import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_vision/flutter_vision.dart';
// import 'package:vhv_card_ocr/modules/object_detection/cubits/cubits.dart';
import 'package:vhv_card_ocr/modules/object_detection/widgets/object_detection_view.dart';

class ObjectDetectionPage extends StatelessWidget {
  const ObjectDetectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trích xuất Thông tin Thẻ Đảng'),
      ),
      body: const ObjectDetectionView(),
    );
  }
}
