import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/event_details.dart';
import 'package:vkhsangeetseva/profile_page.dart';
import 'package:vkhsangeetseva/widgets/next_avl_slot.dart';

class SlotSelection extends StatefulWidget {
  final String title;

  const SlotSelection({super.key, required this.title});

  @override
  // ignore: library_private_types_in_public_api
  _SlotSelectionState createState() => _SlotSelectionState();
}

class _SlotSelectionState extends State<SlotSelection> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  final GlobalKey<NextAvlSlotState> _nextavlslotKey =
      GlobalKey<NextAvlSlotState>();
  DateTime _date = DateTime.now();
  TimeOfDay _timeStart = TimeOfDay.now();
  TimeOfDay _timeEnd = TimeOfDay.now();

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    // perform async operations here

    // check if profile is set
    await Utils().fetchUserBasics();
    UserBasics? basics = Utils().getUserBasics();
    if (basics == null) {
      Toaster().error("Invalid user");
      return;
    }
    PerformerProfile? profile =
        await SSUtils().getPerformerProfile(basics.mobile);
    if (profile == null) {
      await Widgets().showMessage(
          context, "Profile not set. Please set your profile first.");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(
            title: "Performer Profile",
            self: true,
          ),
        ),
      );
    }

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
          ),
        ),
      );
    }
  }

  DateTime _toDateTime(TimeOfDay time) {
    return DateTime(
      _date.year,
      _date.month,
      _date.day,
      time.hour,
      time.minute,
    );
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
                                              flex: 1,
                                              child: Text(
                                                "Date",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineSmall,
                                              )),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                                DateFormat("EEE, dd MMM yyyy")
                                                    .format(_date)),
                                          ),
                                          Expanded(
                                              flex: 1,
                                              child: IconButton(
                                                  onPressed: () async {
                                                    _date = await showDatePicker(
                                                            context: context,
                                                            locale:
                                                                const Locale(
                                                                    'en', 'GB'),
                                                            firstDate: _date,
                                                            lastDate: _date.add(
                                                                Duration(
                                                                    days:
                                                                        365))) ??
                                                        _date;
                                                    setState(() {});
                                                  },
                                                  icon: Icon(Icons
                                                      .calendar_month_outlined))),
                                        ],
                                      ),

                                      // start time row
                                      Row(children: [
                                        Expanded(
                                            flex: 2,
                                            child: Text(
                                              "Start Time",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall,
                                            )),
                                        Expanded(
                                            flex: 3,
                                            child: Text(
                                                _timeStart.format(context))),
                                        Expanded(
                                          flex: 1,
                                          child: IconButton(
                                              onPressed: () async {
                                                _timeStart =
                                                    await showTimePicker(
                                                          context: context,
                                                          initialTime:
                                                              _timeStart,
                                                        ) ??
                                                        _timeStart;

                                                setState(() {});
                                              },
                                              icon: Icon(Icons.access_time)),
                                        ),
                                      ]),

                                      // end time row
                                      Row(
                                        children: [
                                          Expanded(
                                              flex: 2,
                                              child: Text(
                                                "End Time",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineSmall,
                                              )),
                                          Expanded(
                                              flex: 3,
                                              child: Text(
                                                  _timeEnd.format(context))),
                                          Expanded(
                                            flex: 1,
                                            child: IconButton(
                                                onPressed: () async {
                                                  _timeEnd =
                                                      await showTimePicker(
                                                            context: context,
                                                            initialTime:
                                                                _timeEnd,
                                                          ) ??
                                                          _timeEnd;

                                                  setState(() {});
                                                },
                                                icon: Icon(Icons.access_time)),
                                          ),
                                        ],
                                      )
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
                                        child: Text("Select slot")),
                                  ),
                                ],
                              ),
                            )),
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
          LoadingOverlay(
            image: "assets/images/Logo/SangeetSeva.png",
          ),
      ],
    );
  }
}
