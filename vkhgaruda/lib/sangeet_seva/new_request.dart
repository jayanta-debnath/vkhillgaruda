import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vkhgaruda/sangeet_seva/add_event.dart';
import 'package:vkhgaruda/sangeet_seva/add_profile.dart';
import 'package:vkhgaruda/sangeet_seva/add_settings.dart';

class NewRequest extends StatefulWidget {
  final String title;
  final String? splashImage;

  const NewRequest({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _NewRequestState createState() => _NewRequestState();
}

class _NewRequestState extends State<NewRequest> {
  // scalars

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists and maps

    // dispose all controllers and focus nodes

    // listeners

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {});

    // access control

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Profile'),
                Tab(text: 'Event'),
                Tab(text: 'Settings'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              ProfilePage(),
              EventPage(),
              SettingsPage(),
            ],
          ),
        ));
  }
}
