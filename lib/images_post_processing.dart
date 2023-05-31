import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as i;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:scan_document/image_cropper.dart';

class ImagesPostProcessing extends StatefulWidget {
  final List<XFile>? images;

  const ImagesPostProcessing({Key? key, this.images}) : super(key: key);
  @override
  _ImagesPostProcessingState createState() => _ImagesPostProcessingState();
}

class _ImagesPostProcessingState extends State<ImagesPostProcessing> {
  int index = 0;
  Map<XFile, List<Offset>> points = {};

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
              for (XFile file in widget.images!) {
                i.Image image = i.decodeImage(await file.readAsBytes())!;
                if (image.exif.imageIfd.hasOrientation &&
                    image.exif.imageIfd.Orientation != 1) {
                  switch (image.exif.imageIfd.Orientation) {
                    case 6:
                      image = i.copyRotate(image, 90);
                      break;
                  }
                  image.exif.imageIfd.Orientation = 1;
                }
                List<Offset> dots = points[file]!;
                images.add(
                  i.copyCrop(
                    image,
                    (dots[0].dx * image.width).round(),
                    (dots[0].dy * image.height).round(),
                    ((dots[1].dx - dots[0].dx) * image.width).round(),
                    ((dots[1].dy - dots[0].dy) * image.height).round(),
                  ),
                );
              }
              XFile pdf = await _exportPDFFile(images);
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
              children: widget.images!
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
              children: widget.images!.map((file) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      index = widget.images!.indexOf(file);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: file == widget.images![index]
                          ? Border.all(color: Colors.white)
                          : null,
                    ),
                    padding: EdgeInsets.all(3),
                    margin: EdgeInsets.all(10),
                    child: FutureBuilder<Uint8List>(
                      future: file.readAsBytes(),
                      builder: (context, snapshot) => snapshot.hasData
                          ? Image.memory(
                              snapshot.data!,
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            )
                          : Container(),
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

Future<XFile> _exportPDFFile(List<i.Image> images) async {
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

  return XFile.fromData(
    await pdf.save(),
    name: "generated.pdf",
  );
}
