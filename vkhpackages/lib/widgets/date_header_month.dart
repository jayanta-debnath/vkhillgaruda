import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

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

  Future<void> _showMonthPickerDialog(BuildContext context) async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => _month = picked);
    }
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
              final newMonth = DateTime(
                _month.year,
                _month.month - 1,
                _month.day,
              );
              setState(() {
                _month = newMonth;
              });
              widget.onMonthChanged?.call(newMonth);
            },
          ),

          // date
          GestureDetector(
            onTap: () {
              _showMonthPickerDialog(context);
            },
            child: Container(
              width: 150.0,
              alignment: Alignment.center,
              child: Text(
                DateFormat('MMM, yyyy').format(_month),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          // next button
          IconButton(
            icon: Icon(
              Icons.play_arrow,
              color: Theme.of(context).iconTheme.color,
            ), // Default points right
            onPressed: () {
              final newMonth = DateTime(
                _month.year,
                _month.month + 1,
                _month.day,
              );
              setState(() {
                _month = newMonth;
              });
              widget.onMonthChanged?.call(newMonth);
            },
          ),
        ],
      ),
    );
  }
}
