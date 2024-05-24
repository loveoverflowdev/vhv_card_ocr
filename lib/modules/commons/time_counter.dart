import 'dart:async';
import 'package:flutter/material.dart';

class TimeCounter extends StatefulWidget {
  final int initialMilliseconds;
  final bool isLoading;
  final String title;

  const TimeCounter({
    super.key, this.isLoading = false, this.initialMilliseconds = 0, required this.title,
  });

  @override
  State<TimeCounter> createState() => _TimeCounterState();
}

class _TimeCounterState extends State<TimeCounter> {
  int _currentTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = widget.initialMilliseconds;

    if (widget.isLoading) {
       _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 1), (timer) {
      setState(() {
        _currentTime += 1;
      });
    });
  }

  @override
  void didUpdateWidget(covariant TimeCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading == false) {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = formatDuration(_currentTime);
    return PhysicalModel(
      borderRadius: BorderRadius.circular(4),
      color: Theme.of(context).cardColor,
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDuration(int milliseconds) {
    String threeDigits(int n) => n.toString().padLeft(3, "0");
    final minutes = (milliseconds / 60000)
        .floor(); // Convert milliseconds to minutes (discard remainder)
    final seconds = ((milliseconds % 60000) / 1000)
        .floor(); // Extract seconds from remaining milliseconds
    final millisecondsRemaining =
        milliseconds % 1000; // Extract remaining milliseconds
    return ['${minutes}m', '${seconds}s', '${threeDigits(millisecondsRemaining)}ms'].join(' : ');
  }
}
