import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/sangeet_seva/profile.dart';
import 'package:vkhpackages/vkhpackages.dart';

class EventsTab extends StatefulWidget {
  final PerformerProfile? profileData;

  const EventsTab({this.profileData, super.key});

  @override
  State<EventsTab> createState() => EventsTabState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<EventsTabState> _keySummary = GlobalKey<EventsTabState>();

class EventsTabState extends State<EventsTab> {
  final Lock _lock = Lock();
  bool _isLoading = false;

  // lists
  final List<EventRecord> _events = [];

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _events.clear();

    // dispose all controllers

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // your code here

      // read database and populate data
      String dbdate = DateFormat("yyyy-MM-dd").format(DateTime.now());
      String dbpath = "${Const().dbrootGaruda}/Deepotsava/Sales/$dbdate";

      // refresh all child widgets

      // listen for database events
    });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> save() async {}

  Widget _createEventTile(int index) {
    return Placeholder();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _events.length + 3,
              itemBuilder: (BuildContext context, int index) {
                // leave some space on top
                if (index == 0) {
                  return SizedBox(
                    height: 10,
                  );
                }

                // the button
                if (index == 1) {
                  return Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                        onPressed: () {}, child: Text("+ Add new event")),
                  );
                }

                // leave some space at the bottom
                if (index == _events.length + 2) {
                  return SizedBox(
                    height: 100,
                  );
                }

                // the actual list widgets
                _createEventTile(index + 2);
              }),
    );
  }
}
