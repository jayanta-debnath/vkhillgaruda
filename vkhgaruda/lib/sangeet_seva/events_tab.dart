import 'package:flutter/material.dart';
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
  final GlobalKey<ProfileState> _keyProfile = GlobalKey<ProfileState>();

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
    await _lock.synchronized(() async {
      // perform your work here
      setState(() {});
    });
  }

  Future<void> save() async {
    await _keyProfile.currentState?.save(goback: false);
  }

  Widget _createEventTile(int index) {
    return Placeholder();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // some space at top
            SizedBox(
              height: 10,
            ),

            ElevatedButton(onPressed: () {}, child: Text("+ Add new event")),
            SizedBox(
              height: 10,
            ),

            ListView.builder(
                itemCount: _events.length,
                itemBuilder: (BuildContext context, int index) =>
                    _createEventTile(index)),

            // leave some gap at bottom for scrolling
            SizedBox(
              height: 100,
            )
          ],
        ),
      ),
    );
  }
}
