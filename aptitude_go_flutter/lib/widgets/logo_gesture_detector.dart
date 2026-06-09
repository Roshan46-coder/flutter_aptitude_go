import 'dart:async';
import 'package:flutter/material.dart';

class LogoGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onTrigger;

  const LogoGestureDetector({
    super.key,
    required this.child,
    required this.onTrigger,
  });

  @override
  State<LogoGestureDetector> createState() => _LogoGestureDetectorState();
}

class _LogoGestureDetectorState extends State<LogoGestureDetector> {
  final List<String> _expectedSequence = ['UP', 'UP', 'DOWN', 'DOWN', 'RIGHT', 'RIGHT'];
  List<String> _currentSequence = [];
  Timer? _timer;
  Offset? _panStart;
  Offset? _panLast;

  void _addGesture(String direction) {
    if (_timer == null || !_timer!.isActive) {
      _currentSequence.clear();
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 5), () {
        _currentSequence.clear();
      });
    }

    _currentSequence.add(direction);
    
    // Check if prefix matches
    bool matches = true;
    for (int i = 0; i < _currentSequence.length; i++) {
      if (i >= _expectedSequence.length || _currentSequence[i] != _expectedSequence[i]) {
        matches = false;
        break;
      }
    }

    if (!matches) {
      _currentSequence.clear();
      _timer?.cancel();
    } else if (_currentSequence.length == _expectedSequence.length) {
      _currentSequence.clear();
      _timer?.cancel();
      widget.onTrigger();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        _panStart = details.globalPosition;
      },
      onPanUpdate: (details) {
        _panLast = details.globalPosition;
      },
      onPanEnd: (details) {
        if (_panStart == null || _panLast == null) return;
        final difference = _panLast! - _panStart!;
        final dx = difference.dx;
        final dy = difference.dy;
        
        const double threshold = 30.0;
        
        if (difference.distance > threshold) {
          if (dx.abs() > dy.abs()) {
            if (dx > 0) {
              _addGesture('RIGHT');
            } else {
              _addGesture('LEFT');
            }
          } else {
            if (dy > 0) {
              _addGesture('DOWN');
            } else {
              _addGesture('UP');
            }
          }
        }
        _panStart = null;
        _panLast = null;
      },
      child: widget.child,
    );
  }
}
