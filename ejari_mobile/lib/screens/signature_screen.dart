import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SignatureScreen extends StatefulWidget {
  final Function(List<Offset?> points) onSigned;

  const SignatureScreen({super.key, required this.onSigned});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التوقيع الإلكتروني ✍️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => setState(() => _points.clear()),
            tooltip: 'مسح',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.backgroundColor,
            child: const Text(
              'يرجى التوقيع في المربع أدناه بإصبعك للموافقة على العقد',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanUpdate: (details) {
                        RenderBox? renderBox =
                            context.findRenderObject() as RenderBox?;
                        if (renderBox != null) {
                          Offset localPosition =
                              renderBox.globalToLocal(details.globalPosition);
                          if (localPosition.dx >= 0 &&
                              localPosition.dx <= constraints.maxWidth &&
                              localPosition.dy >= 0 &&
                              localPosition.dy <= constraints.maxHeight) {
                            setState(() {
                              _points.add(localPosition);
                            });
                          }
                        }
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _points.add(null);
                        });
                      },
                      child: CustomPaint(
                        painter: SignaturePainter(_points),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _points.isEmpty
                    ? null
                    : () {
                        widget.onSigned(_points);
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('اعتماد التوقيع',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = AppTheme.textPrimary
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        // Ensure points are within bounds (extra safety)
        if (_isPointInBounds(points[i]!, size) &&
            _isPointInBounds(points[i + 1]!, size)) {
          canvas.drawLine(points[i]!, points[i + 1]!, paint);
        }
      }
    }
  }

  bool _isPointInBounds(Offset point, Size size) {
    return point.dx >= 0 &&
        point.dx <= size.width &&
        point.dy >= 0 &&
        point.dy <= size.height;
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) =>
      oldDelegate.points != points;
}
