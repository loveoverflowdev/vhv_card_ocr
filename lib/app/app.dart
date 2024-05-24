import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vision/flutter_vision.dart';

import '../modules/object_detection/cubits/cubits.dart';
import '../modules/object_detection/object_detection.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ObjectDetectionCubit(vision: FlutterVision()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter VHV Card OCR Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const ObjectDetectionPage(),
      ),
    );
  }
}
