import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vkhgaruda/sangeet_seva/tab_events.dart';
import 'package:vkhgaruda/sangeet_seva/tab_profile.dart';
import 'package:vkhgaruda/sangeet_seva/tab_settings.dart';
import 'package:vkhpackages/vkhpackages.dart';

class RecordPage extends StatefulWidget {
  final String title;
  final String? splashImage;
  final PerformerProfile? profile;

  const RecordPage(
      {super.key, required this.title, this.splashImage, this.profile});

  @override
  // ignore: library_private_types_in_public_api
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  // scalars
  bool _isAdmin = false;
  final GlobalKey<TabProfileState> _keyTabProfile =
      GlobalKey<TabProfileState>();
  final GlobalKey<TabEventsState> _keyTabEvents = GlobalKey<TabEventsState>();
  // final GlobalKey<TabSettingsState> _keyTabSettings =
  //     GlobalKey<TabSettingsState>();
  PerformerProfile? _profile;
  int _currentTabIndex = 0;

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    if (widget.profile != null) {
      _profile = widget.profile;
    } else {
      _profile = _keyTabProfile.currentState?.getPerformerProfile();
    }

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

    _keyTabProfile.currentState?.refresh();
    _keyTabEvents.currentState?.refresh();

    setState(() {});
  }

  Future<void> _save() async {
    await _keyTabProfile.currentState?.save();
    _profile = _keyTabProfile.currentState?.getPerformerProfile();
    if (_profile != null) {
      _keyTabEvents.currentState?.setProfile(_profile!);
      await _keyTabEvents.currentState?.refresh();
    }
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
                    await _save();
                  })
            ],
            bottom: TabBar(
              tabs: [
                Tab(text: 'Profile'),
                Tab(text: 'Events'),
                Tab(text: 'Settings'),
              ],
              onTap: (index) async {
                // Save the previous tab's data before switching
                if (_currentTabIndex == 0) {
                  await _save();
                }
                setState(() {
                  _currentTabIndex = index;
                });
              },
            ),
          ),
          body: TabBarView(
            children: [
              TabProfile(
                key: _keyTabProfile,
                profile: _profile,
              ),
              TabEvents(
                key: _keyTabEvents,
                profile: _profile,
              ),
              TabSettings(),
            ],
          ),
        ));
  }
}
