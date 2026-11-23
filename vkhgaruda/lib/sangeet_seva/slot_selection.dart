import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/event_details.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhgaruda/sangeet_seva/datatypes.dart';

class SlotSelection extends StatefulWidget {
  final String title;
  final PerformerProfile profile;

  const SlotSelection({super.key, required this.title, required this.profile});

  @override
  // ignore: library_private_types_in_public_api
  SlotSelectionState createState() => SlotSelectionState();
}

class SlotSelectionState extends State<SlotSelection> {
  // scalars
  DateTime _date = DateTime.now().add(Duration(days: 1));
  TimeOfDay _startTime = TimeOfDay.now();
  late TimeOfDay _endTime;

  // lists
  final List<String> _possibleDurations = [
    "30 min",
    "1 hr",
    "1.5 hrs",
    "2 hrs"
  ];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    _endTime = Utils().addMinutesToTimeOfDay(_startTime, 60);
  }

  @override
  dispose() {
    // clear all lists
    _possibleDurations.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  SlotSelectionType? onSelectSlot() {
    // check if slot is in the past
    DateTime now = DateTime.now();
    if (_date.isBefore(now)) {
      Toaster().error("Cannot book slot in the past");
      return null;
    }

    // validate if end time is greater than start time
    if (_endTime.compareTo(_startTime) < 0) {
      Toaster().error("End time should be greater than start time");
      return null;
    }

    // validate if end time is greater than start time by 30 mins
    int minutesSinceMidnight(TimeOfDay time) => time.hour * 60 + time.minute;
    final difference =
        (minutesSinceMidnight(_endTime) - minutesSinceMidnight(_startTime))
            .abs();
    if (difference < 30) {
      Toaster().error("Concert duration should be at least 30 mins");
      return null;
    }

    // after validation success, return the object with correct data
    return SlotSelectionType(
        date: _date,
        startTime: _toDateTime(_startTime),
        endTime: _toDateTime(_endTime));
  }

  DateTime _toDateTime(TimeOfDay time) {
    return DateTime(_date.year, _date.month, _date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      children: [
        // your widgets here
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                "Date",
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                DateFormat(
                  "EEE, dd MMM yyyy",
                ).format(_date),
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                onPressed: () async {
                  _date = await showDatePicker(
                        context: context,
                        locale: const Locale(
                          'en',
                          'GB',
                        ),
                        firstDate: _date,
                        lastDate: _date.add(
                          Duration(days: 365),
                        ),
                      ) ??
                      _date;
                  setState(() {});
                },
                icon: Icon(
                  Icons.calendar_month_outlined,
                ),
              ),
            ),
          ],
        ),

        // start time row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                "Time",
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _startTime.format(context),
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                onPressed: () async {
                  _startTime = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      ) ??
                      _startTime;
                  _endTime = Utils().addMinutesToTimeOfDay(_startTime, 60);

                  setState(() {});
                },
                icon: Icon(Icons.access_time),
              ),
            ),
          ],
        ),

        // duration
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                "Duration",
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              flex: 4,
              child: DropdownButton(
                  items: _possibleDurations.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  value: "1 hr",
                  isExpanded: true,
                  onChanged: (value) => setState(() {
                        switch (value) {
                          case "30 mins":
                            _endTime =
                                Utils().addMinutesToTimeOfDay(_startTime, 30);
                            break;

                          case "1 hr":
                            _endTime =
                                Utils().addMinutesToTimeOfDay(_startTime, 60);
                            break;

                          case "1.5 hrs":
                            _endTime =
                                Utils().addMinutesToTimeOfDay(_startTime, 90);
                            break;

                          case "2 hrs":
                            _endTime =
                                Utils().addMinutesToTimeOfDay(_startTime, 120);
                            break;
                        }
                      })),
            ),
          ],
        ),
      ],
    ));
  }
}

class SlotSelectionType {
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;

  SlotSelectionType({
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  // Factory constructor to create a SlotSelectionType from JSON
  factory SlotSelectionType.fromJson(Map<String, dynamic> json) {
    return SlotSelectionType(
      date: json['date'] as DateTime,
      startTime: json['startTime'] as DateTime,
      endTime: json['endTime'] as DateTime,
    );
  }

  // Method to convert SlotSelectionType to JSON
  Map<String, dynamic> toJson() {
    return {'date': date, 'startTime': startTime, 'endTime': endTime};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotSelectionType &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => Object.hash(date, startTime, endTime);
}
