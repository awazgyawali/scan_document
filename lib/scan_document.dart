import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:scan_document/images_post_processing.dart';

Future<File?> scanDocument(BuildContext context) async {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => _ScanDocument(),
    ),
  );
}

class _ScanDocument extends StatefulWidget {
  @override
  _ScanDocumentState createState() => _ScanDocumentState();
}

class _ScanDocumentState extends State<_ScanDocument> {
  CameraController? _cameraController;

  List<File> capturedImages = [];
  @override
  void initState() {
    initAsync();
    super.initState();
  }

  initAsync() async {
    List<CameraDescription> cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await _cameraController!.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null)
      return Scaffold(
        appBar: AppBar(
          title: Text("Scan Document"),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    double xScale = _cameraController!.value.aspectRatio / deviceRatio;
    final yScale = 1.0;

    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      xScale = 1.0;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan Document"),
      ),
      body: Stack(
        children: [
          AspectRatio(
            aspectRatio: deviceRatio,
            child: Container(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(xScale, yScale, 1),
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
          Align(
            alignment: Alignment(0, 1),
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (capturedImages.length > 0)
                      Stack(
                        children: [
                          Container(
                            height: 60,
                            width: 60,
                            child: Image.file(
                              capturedImages.last,
                              fit: BoxFit.cover,
                            ),
                          ),
                          FractionalTranslation(
                            translation: Offset(-.5, -.5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).accentColor,
                                shape: BoxShape.circle,
                              ),
                              padding: EdgeInsets.all(6),
                              child: Text(
                                capturedImages.length.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    Spacer(),
                    GestureDetector(
                      onTap: () async {
                        XFile file = await _cameraController!.takePicture();
                        setState(() {
                          capturedImages.add(File(file.path));
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          height: 50,
                          width: 50,
                        ),
                      ),
                    ),
                    Spacer(),
                    if (capturedImages.length > 0)
                      FlatButton(
                        child: Text("Continue"),
                        textColor: Colors.white,
                        onPressed: () async {
                          File? pdf = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ImagesPostProcessing(images: capturedImages),
                            ),
                          );
                          if (pdf != null) Navigator.pop(context, pdf);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
