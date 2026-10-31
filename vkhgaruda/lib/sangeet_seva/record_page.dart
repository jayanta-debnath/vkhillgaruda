import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vkhgaruda/sangeet_seva/tab_events.dart';
import 'package:vkhgaruda/sangeet_seva/tab_profile.dart';
import 'package:vkhgaruda/sangeet_seva/tab_settings.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhgaruda/sangeet_seva/datatypes.dart';

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
  final GlobalKey<TabSettingsState> _keyTabSettings =
      GlobalKey<TabSettingsState>();
  PerformerProfile? _profile;
  int _currentTabIndex = 0;

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    if (widget.profile != null) {
      _profile = widget.profile;
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
    // _keySettings.currentState?.refresh();

    setState(() {});
  }

  void _onProfileUpdateFromBelow(PerformerProfile? profile) {
    if (profile != null) {
      setState(() {
        _profile = profile;
      });
    }
  }

  Future<void> _save() async {
    _profile = await _keyTabProfile.currentState?.save();
    _keyTabEvents.currentState?.save();
    _keyTabSettings.currentState?.save();

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
                // Save the profile tab's data before switching
                if (_currentTabIndex == 0) {
                  _profile = await _keyTabProfile.currentState?.save();
                }
                _currentTabIndex = index;
                setState(() {});
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
              TabSettings(
                key: _keyTabSettings,
                profile: _profile,
                onProfileUpdate: _onProfileUpdateFromBelow,
              ),
            ],
          ),
        ));
  }
}
