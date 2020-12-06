import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scan_document/image_cropper.dart';

class ImagesPostProcessing extends StatefulWidget {
  final List<File> images;

  const ImagesPostProcessing({Key key, this.images}) : super(key: key);
  @override
  _ImagesPostProcessingState createState() => _ImagesPostProcessingState();
}

class _ImagesPostProcessingState extends State<ImagesPostProcessing> {
  File selectedFile;
  Map<File, List<Offset>> allPoints = {};
  @override
  void initState() {
    super.initState();
    selectedFile = widget.images[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: ImageCropper(
              image: selectedFile,
              points: allPoints[selectedFile] ??
                  [
                    Offset(0, 0),
                    Offset(0, 100),
                    Offset(100, 100),
                    Offset(100, 0),
                  ],
              onPointsChanged: (points) {
                setState(() {
                  allPoints[selectedFile] = points;
                });
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.images.map((file) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFile = file;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: file == selectedFile
                          ? Border.all(color: Colors.white)
                          : null,
                    ),
                    padding: EdgeInsets.all(3),
                    margin: EdgeInsets.all(10),
                    child: Image.file(
                      file,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}
