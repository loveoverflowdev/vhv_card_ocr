
// import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;


// class ImageListView extends StatelessWidget {
//   final List<img.Image> imageList;

//   const ImageListView({super.key, required this.imageList});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Image List'),
//       ),
//       body: ListView.builder(
//         itemCount: imageList.length,
//         itemBuilder: (context, index) {
//           final image = imageList[index];
//           return ListTile(
//             title: Image.memory(img.encodePng(image)),
//           );
//         }),
//     );
//   }
// }
