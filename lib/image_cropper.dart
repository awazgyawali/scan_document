import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

class ImageCropper extends StatefulWidget {
  final File image;
  final List<Offset> points;
  final Function(List<Offset>) onPointsChanged;
  const ImageCropper({
    Key key,
    @required this.image,
    @required this.points,
    this.onPointsChanged,
  }) : super(key: key);

  @override
  _ImageCropperState createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  int _movingIndex;

  _isNear(Offset touchPoint) {
    widget.points.forEach((point) {
      double distance = _distance(point, touchPoint);
      if (distance <= 10) {
        _movingIndex = widget.points.indexOf(point);
      }
    });
    return false;
  }

  double _distance(Offset a, Offset b) {
    return sqrt(pow(b.dy - a.dy, 2) + pow(b.dx - a.dx, 2));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onPanStart: (details) {
            _isNear(details.localPosition);
          },
          onPanUpdate: (details) {
            List<Offset> points = widget.points;
            points[_movingIndex] = Offset(
              details.localPosition.dx,
              details.localPosition.dy,
            );
            widget.onPointsChanged(points);
          },
          onPanEnd: (_) {
            _movingIndex = -1;
          },
          child: CustomPaint(
            foregroundPainter: PathPainter(widget.points),
            child: Image.file(
              widget.image,
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class PathPainter extends CustomPainter {
  PathPainter(this.points);
  final List<Offset> points;
  Paint dotPainter = Paint()..color = Colors.white;
  Paint linePainter = Paint()
    ..color = Colors.white
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path();
    points.forEach((point) {
      if (point == points.first)
        path.moveTo(point.dx, point.dy);
      else
        path.lineTo(point.dx, point.dy);
      canvas.drawCircle(point, 5, dotPainter);
    });
    path.lineTo(points.first.dx, points.first.dy);

    canvas.drawPath(path, linePainter);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
