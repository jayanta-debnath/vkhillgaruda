import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'profile.dart';
import 'package:vkhgaruda/sangeet_seva/datatypes.dart';

class TabProfile extends StatefulWidget {
  final PerformerProfile? profile;

  const TabProfile({this.profile, super.key});

  @override
  State<TabProfile> createState() => TabProfileState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<TabProfileState> _keySummary = GlobalKey<TabProfileState>();

class TabProfileState extends State<TabProfile> {
  final Lock _lock = Lock();
  final GlobalKey<ProfileState> _keyProfile = GlobalKey<ProfileState>();

  @override
  void initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // dispose all controllers

    super.dispose();
  }

  Future<void> refresh() async {
    await _lock.synchronized(() async {
      // perform your work here
      _keyProfile.currentState?.refresh();

      setState(() {});
    });
  }

  Future<PerformerProfile?> save() async {
    return await _keyProfile.currentState?.save();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Profile(
          key: _keyProfile,
          oldUserDetails: widget.profile,
        ),
      ),
    );
  }
}
