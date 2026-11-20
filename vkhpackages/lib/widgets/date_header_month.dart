import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateHeaderMonth extends StatefulWidget {
  final void Function(DateTime)? onMonthChanged;

  const DateHeaderMonth({super.key, this.onMonthChanged});

  @override
  State<DateHeaderMonth> createState() => _DateHeaderDateState();
}

class _DateHeaderDateState extends State<DateHeaderMonth> {
  DateTime _month = DateTime.now();

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // previous button
          IconButton(
            icon: Transform.rotate(
              angle: 3.14, // Rotate 180 degrees to point left
              child: Icon(
                Icons.play_arrow,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            onPressed: () {
              if (widget.onMonthChanged == null) {
                return;
              }

              setState(() {
                _month = DateTime(_month.year, _month.month - 1, _month.day);
              });

              widget.onMonthChanged!(_month);
            },
          ),

          // date
          Container(
            width: 150.0,
            alignment: Alignment.center,
            child: Text(
              DateFormat('MMM, yyyy').format(_month),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),

          // next button
          IconButton(
            icon: Icon(
              Icons.play_arrow,
              color: Theme.of(context).iconTheme.color,
            ), // Default points right
            onPressed: () {
              if (widget.onMonthChanged == null) {
                return;
              }

              if (_month.year == DateTime.now().year &&
                  _month.month == DateTime.now().month) {
                return;
              }

              setState(() {
                _month = DateTime(_month.year, _month.month + 1, _month.day);
              });

              widget.onMonthChanged!(_month);
            },
          ),
        ],
      ),
    );
  }
}
