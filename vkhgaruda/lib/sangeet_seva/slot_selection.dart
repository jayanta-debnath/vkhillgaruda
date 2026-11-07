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
  _SlotSelectionState createState() => _SlotSelectionState();
}

class _SlotSelectionState extends State<SlotSelection> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  DateTime _date = DateTime.now().add(Duration(days: 1));
  TimeOfDay _timeStart = TimeOfDay.now();
  late TimeOfDay _timeEnd;

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

    _timeEnd = Utils().addMinutesToTimeOfDay(_timeStart, 60);

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _possibleDurations.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    // perform async operations here

    await _lock.synchronized(() async {
      // fetch form values

      // refresh all child widgets

      // perform sync operations here
    });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _onSelectSlot() async {
    // check if slot is in the past
    DateTime now = DateTime.now();
    if (_date.isBefore(now)) {
      Toaster().error("Cannot book slot in the past");
      return;
    }

    // validate if end time is greater than start time
    if (_timeEnd.compareTo(_timeStart) < 0) {
      Toaster().error("End time should be greater than start time");
      return;
    }

    // validate if end time is greater than start time by 30 mins
    int minutesSinceMidnight(TimeOfDay time) => time.hour * 60 + time.minute;
    final difference =
        (minutesSinceMidnight(_timeEnd) - minutesSinceMidnight(_timeStart))
            .abs();
    if (difference < 30) {
      Toaster().error("Event duration should be at least 30 mins");
      return;
    }

    // go to next page
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetails(
            title: widget.title,
            selectedDate: _date,
            eventStart: _toDateTime(_timeStart),
            eventEnd: _toDateTime(_timeEnd),
            profile: widget.profile,
          ),
        ),
      );
    }
  }

  DateTime _toDateTime(TimeOfDay time) {
    return DateTime(_date.year, _date.month, _date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: RefreshIndicator(
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Column(
                    children: [
                      // leave some space at top
                      SizedBox(height: 10),

                      Widgets().createTopLevelResponsiveContainer(context, [
                        // your widgets here
                        Widgets().createTopLevelCard(
                          context: context,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // select date and time
                                Column(
                                  children: [
                                    // date row
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
                                            _timeStart.format(context),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: IconButton(
                                            onPressed: () async {
                                              _timeStart = await showTimePicker(
                                                    context: context,
                                                    initialTime: _timeStart,
                                                  ) ??
                                                  _timeStart;
                                              _timeEnd = Utils()
                                                  .addMinutesToTimeOfDay(
                                                      _timeStart, 60);

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
                                              items: _possibleDurations
                                                  .map((item) {
                                                return DropdownMenuItem(
                                                  value: item,
                                                  child: Text(item),
                                                );
                                              }).toList(),
                                              value: "1 hr",
                                              isExpanded: true,
                                              onChanged: (value) =>
                                                  setState(() {
                                                    switch (value) {
                                                      case "30 mins":
                                                        _timeEnd = Utils()
                                                            .addMinutesToTimeOfDay(
                                                                _timeStart, 30);
                                                        break;

                                                      case "1 hr":
                                                        _timeEnd = Utils()
                                                            .addMinutesToTimeOfDay(
                                                                _timeStart, 60);
                                                        break;

                                                      case "1.5 hrs":
                                                        _timeEnd = Utils()
                                                            .addMinutesToTimeOfDay(
                                                                _timeStart, 90);
                                                        break;

                                                      case "2 hrs":
                                                        _timeEnd = Utils()
                                                            .addMinutesToTimeOfDay(
                                                                _timeStart,
                                                                120);
                                                        break;
                                                    }
                                                  })),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // button to go to next page
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await _onSelectSlot();
                                    },
                                    child: Text("Select slot"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),

                      // leave some space at bottom
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // circular progress indicator
        if (_isLoading)
          LoadingOverlay(image: "assets/images/Logo/SangeetSeva.png"),
      ],
    );
  }
}
