import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class TabSettings extends StatefulWidget {
  final PerformerProfile? profile;

  const TabSettings({this.profile, super.key});

  @override
  State<TabSettings> createState() => TabSettingsState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<TabSettingsState> _keySummary = GlobalKey<TabSettingsState>();

class TabSettingsState extends State<TabSettings> {
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

      // refresh all child widgets

      // listen for database events
    });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> save() async {
    return;
  }

  @override
  Widget build(BuildContext context) {
    return (widget.profile != null)
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _events.length + 2,
                    itemBuilder: (BuildContext context, int index) {
                      // leave some space on top
                      if (index == 0) {
                        return SizedBox(
                          height: 10,
                        );
                      }

                      // leave some space at the bottom
                      if (index == _events.length + 1) {
                        return SizedBox(
                          height: 100,
                        );
                      }

                      // the actual list widgets
                    }),
          )
        : Center(child: Text("Profile not set "));
  }
}
