import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/sangeet_seva/profile.dart';
import 'package:vkhpackages/vkhpackages.dart';

class ProfileTab extends StatefulWidget {
  final PerformerProfile? profileData;

  const ProfileTab({this.profileData, super.key});

  @override
  State<ProfileTab> createState() => ProfileTabState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<ProfileTabState> _keySummary = GlobalKey<ProfileTabState>();

class ProfileTabState extends State<ProfileTab> {
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
      setState(() {});
    });
  }

  Future<void> save() async {
    await _keyProfile.currentState?.save(goback: false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Profile(
          key: _keyProfile,
          self: false,
          oldUserDetails: widget.profileData,
        ),
      ),
    );
  }
}
