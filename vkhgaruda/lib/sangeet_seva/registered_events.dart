import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/event_details.dart';
import 'package:vkhgaruda/sangeet_seva/ssutils.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhgaruda/sangeet_seva/datatypes.dart';

class RegisteredEvents extends StatefulWidget {
  final String title;
  final String? splashImage;

  const RegisteredEvents({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _RegisteredEventsState createState() => _RegisteredEventsState();
}

class _RegisteredEventsState extends State<RegisteredEvents> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  DateTime _lastCallbackInvoked = DateTime.now();
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _endDate;

  // lists
  final List<EventRecord> _events = [];
  final Map<String, PerformerProfile> _mainPerformers = {};
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    _endDate = DateTime(_startDate.year, _startDate.month + 1, 0);

    FB().listenForChange(
        "${Const().dbrootSangeetSeva}/BookedEvents",
        FBCallbacks(
          // add
          add: (data) async {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();
            }

            // process the received data
            // assuming only one data is received
            String eventPath = data[0]['path'];
            var eventRaw = await FB().getJson(path: eventPath);
            EventRecord event =
                Utils().convertRawToDatatype(eventRaw, EventRecord.fromJson);
            PerformerProfile? mainPerformer =
                await SSUtils().getPerformerProfile(event.eventRequesterMobile);

            setState(() {
              _events.add(event);

              if (mainPerformer != null) {
                _mainPerformers[mainPerformer.mobile] = mainPerformer;
              }
            });
          },

          // edit
          edit: () {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              refresh();
            }
          },

          // delete
          delete: (data) async {
            if (_lastCallbackInvoked.isBefore(DateTime.now()
                .subtract(Duration(seconds: Const().fbListenerDelay)))) {
              _lastCallbackInvoked = DateTime.now();

              // process the received data
              // assuming only one data is received
              String eventPath = data[0]['path'];
              var eventRaw = await FB().getJson(path: eventPath);

              setState(() {
                EventRecord event = Utils()
                    .convertRawToDatatype(eventRaw, EventRecord.fromJson);

                Widgets().showMessage(context, "Delete event not implemented");
              });
            }
          },

          // get listeners
          getListeners: (listeners) {
            _listeners = listeners;
          },
        ));

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _events.clear();
    _mainPerformers.clear();

    // clear all controllers and focus nodes
    for (var element in _listeners) {
      element.cancel();
    }

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    await _lock.synchronized(() async {
      // populate events list
      _events.clear();
      _mainPerformers.clear();
      String dbpath = "${Const().dbrootSangeetSeva}/BookedEvents";
      Map<String, dynamic> kvs = await FB().getValuesByDateRange(
          path: dbpath, startDate: _startDate, endDate: _endDate);
      if (kvs.isNotEmpty) {
        for (var kv in kvs.entries) {
          List eventLinksRaw = kv.value;
          for (var eventLinkRaw in eventLinksRaw) {
            var eventRaw = await FB().getValue(path: eventLinkRaw['path']);
            EventRecord event =
                Utils().convertRawToDatatype(eventRaw, EventRecord.fromJson);

            _events.add(event);

            PerformerProfile? mainPerformer =
                await SSUtils().getPerformerProfile(event.eventRequesterMobile);
            if (mainPerformer != null) {
              _mainPerformers[mainPerformer.mobile] = mainPerformer;
            }
          }
        }
      }

      // sort events by date
      _events.sort((a, b) {
        if (a.date.isBefore(b.date)) {
          return -1;
        } else if (a.date.isAfter(b.date)) {
          return 1;
        } else {
          return 0;
        }
      });
    });

    // perform any remaining async operations here

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createEventCard(index) {
    String title = DateFormat("dd MMM, yyyy").format(_events[index].date);
    title +=
        " (${Time().convertDateTimeTo12hrFormat(_events[index].eventStart)} - ${Time().convertDateTimeTo12hrFormat(_events[index].eventEnd)})";
    String mobile = _events[index].eventRequesterMobile;
    if (_mainPerformers[mobile] == null) {
      Toaster().error("Could not find user");
      return const SizedBox();
    }
    String performer = _mainPerformers[mobile]!.name;
    String profilePicUrl = _mainPerformers[mobile]!.profilePicUrl ?? "";

    Icon statusIcon = Icon(Icons.help_outline, color: Colors.orange);
    if (_events[index].status == "Approved") {
      statusIcon = Icon(Icons.check_circle, color: Colors.green);
    } else if (_events[index].status == "Rejected") {
      statusIcon = Icon(Icons.cancel_outlined, color: Colors.red);
    }

    // set the text color to gray if event is in the past
    Color textColor = Colors.black;
    if (_events[index].eventEnd.isBefore(DateTime.now())) {
      textColor = Colors.grey;
    }

    return Card(
        child: ListTile(
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .headlineSmall!
            .copyWith(color: textColor),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: CircleAvatar(
            backgroundImage:
                (profilePicUrl.isEmpty ? null : NetworkImage(profilePicUrl))),
      ),
      subtitle: Row(
        children: [
          Icon(Icons.person, size: 16, color: textColor),
          Text(
            performer,
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(color: textColor),
          ),
          SizedBox(width: 10),
          Icon(Icons.phone, size: 16, color: textColor),
          Text(
            mobile,
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(color: textColor),
          ),
        ],
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: statusIcon,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
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

                      // month header
                      DateHeaderMonth(),

                      // list of events
                      Widgets().createTopLevelResponsiveContainer(context, [
                        // your widgets here
                        ...List.generate(_events.length, (index) {
                          return GestureDetector(
                            onTap: () async {
                              PerformerProfile? profile = await SSUtils()
                                  .getPerformerProfile(
                                      _events[index].eventRequesterMobile);

                              if (profile != null) {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return EventDetails(
                                    title: "Request Details",
                                    oldEvent: _events[index],
                                    selectedDate: _events[index].eventStart,
                                    profile: profile,
                                    doubleBack: false,
                                  );
                                }));
                              }
                            },
                            child: _createEventCard(index),
                          );
                        }),
                      ]),

                      // empty message
                      if (_events.isEmpty)
                        Center(
                          child: Text("No events found"),
                        ),

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
            image: widget.splashImage ??
                "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
