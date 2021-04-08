import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as i;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scan_document/image_cropper.dart';

class ImagesPostProcessing extends StatefulWidget {
  final List<File> images;

  const ImagesPostProcessing({Key key, this.images}) : super(key: key);
  @override
  _ImagesPostProcessingState createState() => _ImagesPostProcessingState();
}

class _ImagesPostProcessingState extends State<ImagesPostProcessing> {
  int index = 0;
  Map<File, List<Offset>> points = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Scan Document"),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () async {
              List<i.Image> images = [];
              widget.images.forEach(
                (file) {
                  i.Image image = i.decodeImage(file.readAsBytesSync());
                  if (image.exif.hasOrientation &&
                      image.exif.orientation != 1) {
                    switch (image.exif.orientation) {
                      case 6:
                        image = i.copyRotate(image, 90);
                        break;
                    }
                    image.exif.orientation = 1;
                  }
                  List<Offset> dots = points[file];
                  images.add(
                    i.copyCrop(
                      image,
                      (dots[0].dx * image.width).round(),
                      (dots[0].dy * image.height).round(),
                      ((dots[1].dx - dots[0].dx) * image.width).round(),
                      ((dots[1].dy - dots[0].dy) * image.height).round(),
                    ),
                  );
                },
              );
              File pdf = await _exportPDFFile(images);
              Navigator.pop(context, pdf);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: index,
              children: widget.images
                  .map(
                    (e) => ImageCropper(
                      key: Key(e.path),
                      file: e,
                      points: points[e] ??
                          [
                            Offset(0, 0),
                            Offset(1, 1),
                          ],
                      onPointsChanged: (p) {
                        setState(() {
                          points[e] = p;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.images.map((file) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      index = widget.images.indexOf(file);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: file == widget.images[index]
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

Future<String> getTemporaryPath(String fileName) async {
  return "${(await getTemporaryDirectory()).path}/$fileName";
}

Future<File> _exportPDFFile(List<i.Image> images) async {
  final pdf = pw.Document();
  images.forEach(
    (image) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                pw.RawImage(
                  width: image.width,
                  height: image.height,
                  bytes: image.getBytes(),
                ),
              ),
            );
          },
        ),
      );
    },
  );

  final file = File(await getTemporaryPath("generated.pdf"));
  Uint8List data = await pdf.save();
  return file.writeAsBytes(data);
}
