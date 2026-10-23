import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vkhgaruda/sangeet_seva/events_tab.dart';
import 'package:vkhgaruda/sangeet_seva/profile_tab.dart';
import 'package:vkhgaruda/sangeet_seva/settings_tab.dart';
import 'package:vkhpackages/vkhpackages.dart';

class RecordPage extends StatefulWidget {
  final String title;
  final String? splashImage;
  final PerformerProfile? profileData;

  const RecordPage(
      {super.key, required this.title, this.splashImage, this.profileData});

  @override
  // ignore: library_private_types_in_public_api
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  // scalars
  bool _isAdmin = false;
  final GlobalKey<ProfileTabState> _keyProfileTab =
      GlobalKey<ProfileTabState>();

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
    _isAdmin = await Utils().isAdmin();
    if (!_isAdmin) {
      if (mounted) {
        Toaster().error("Access Denied");
        Navigator.pop(context);
      }
    }

    _keyProfileTab.currentState?.refresh();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () async {
                    await _keyProfileTab.currentState?.save();
                  })
            ],
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Profile'),
                Tab(text: 'Events'),
                Tab(text: 'Settings'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              ProfileTab(
                key: _keyProfileTab,
                profileData: widget.profileData,
              ),
              EventsTab(
                profileData: widget.profileData,
              ),
              SettingsTab(),
            ],
          ),
        ));
  }
}
