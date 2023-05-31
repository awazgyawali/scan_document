import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as i;

enum DragState {
  CORNER,
  INSIDE,
  OUTSIDE,
}

class ImageCropper extends StatefulWidget {
  final XFile file;
  final List<Offset> points;
  final Function(List<Offset>)? onPointsChanged;
  const ImageCropper({
    Key? key,
    required this.file,
    required this.points,
    this.onPointsChanged,
  }) : super(key: key);

  @override
  _ImageCropperState createState() => _ImageCropperState();
}

class PathPainter extends CustomPainter {
  final List<Offset> points;
  Paint dotPainter = Paint()..color = Colors.white;
  Paint linePainter = Paint()
    ..color = Colors.white
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  PathPainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path();
    Offset point1 = points[0];
    Offset point2 = points[1];
    path.moveTo(point1.dx * size.width, point1.dy * size.height);
    path.lineTo(point2.dx * size.width, point1.dy * size.height);
    path.lineTo(point2.dx * size.width, point2.dy * size.height);
    path.lineTo(point1.dx * size.width, point2.dy * size.height);
    path.lineTo(point1.dx * size.width, point1.dy * size.height);

    // canvas.drawCircle(point, 5, dotPainter);
    // path.lineTo(points.first.dx, points.first.dy);

    canvas.drawPath(path, linePainter);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ImageCropperState extends State<ImageCropper> {
  late int _movingIndex;
  DragState? dragState;
  i.Image? transformedImage;

  double get height =>
      (transformedImage!.width / transformedImage!.height) * width;

  List<Offset> get points => [
        Offset(widget.points[0].dx * width, widget.points[0].dy * height),
        Offset(widget.points[1].dx * width, widget.points[0].dy * height),
        Offset(widget.points[1].dx * width, widget.points[1].dy * height),
        Offset(widget.points[0].dx * width, widget.points[1].dy * height),
      ];

  double get width => MediaQuery.of(context).size.width;

  @override
  Widget build(BuildContext context) {
    if (transformedImage == null)
      return Center(child: CircularProgressIndicator());
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onPanStart: (details) {
              _isNear(details.localPosition);
            },
            onPanUpdate: (details) {
              if (dragState == DragState.CORNER) {
                List<Offset> points = widget.points;
                Offset currentFinger = details.localPosition;
                currentFinger = Offset(
                  currentFinger.dx.clamp(0.0, double.infinity),
                  currentFinger.dy.clamp(0.0, double.infinity),
                );
                switch (_movingIndex) {
                  case -1:
                    return;
                  case 0:
                    points[_movingIndex] = Offset(
                      currentFinger.dx / width,
                      currentFinger.dy / height,
                    );
                    widget.onPointsChanged!(points);
                    break;
                  case 1:
                    points[0] = Offset(points[0].dx, currentFinger.dy / height);
                    points[1] = Offset(currentFinger.dx / width, points[1].dy);
                    widget.onPointsChanged!(points);
                    break;
                  case 2:
                    points[1] = Offset(
                        currentFinger.dx / width, currentFinger.dy / height);
                    widget.onPointsChanged!(points);
                    break;
                  case 3:
                    points[0] = Offset(currentFinger.dx / width, points[0].dy);
                    points[1] = Offset(points[1].dx, currentFinger.dy / height);
                    widget.onPointsChanged!(points);
                    break;
                  default:
                }
              } else if (dragState == DragState.INSIDE) {
                Offset delta = details.delta;

                List<Offset> proposedPoints = widget.points.map((e) {
                  Offset revisedPoint = Offset(
                    e.dx * width,
                    e.dy * height,
                  ).translate(
                    delta.dx,
                    delta.dy,
                  );
                  return Offset(
                    (revisedPoint.dx / width).clamp(0.0, double.infinity),
                    (revisedPoint.dy / height).clamp(0.0, double.infinity),
                  );
                }).toList();
                widget.onPointsChanged!(proposedPoints);
              }
            },
            onPanEnd: (_) {
              _movingIndex = -1;
            },
            child: CustomPaint(
              foregroundPainter: PathPainter(widget.points),
              child: Image.memory(
                transformedImage!.getBytes(),
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  initState() {
    super.initState();
    widget.file.readAsBytes().then((value) {
      setState(() {
        transformedImage = i.decodeImage(value);
      });
    });
  }

  double _distance(Offset a, Offset b) {
    return sqrt(pow(b.dy - a.dy, 2) + pow(b.dx - a.dx, 2));
  }

  _isNear(Offset touchPoint) {
    _movingIndex = -1;
    // Check corner
    for (Offset point in points) {
      double distance = _distance(point, touchPoint);
      if (distance <= 20) {
        dragState = DragState.CORNER;
        _movingIndex = points.indexOf(point);
        return;
      }
    }

    // Check inside
    if (touchPoint.dx > points[0].dx &&
        touchPoint.dx < points[1].dx &&
        touchPoint.dy > points[0].dy &&
        touchPoint.dy < points[2].dy) {
      dragState = DragState.INSIDE;
      return;
    }
    dragState = DragState.OUTSIDE;
  }
}
