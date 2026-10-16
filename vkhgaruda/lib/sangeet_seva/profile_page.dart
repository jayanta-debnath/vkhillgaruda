import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/sangeet_seva/profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<ProfilePageState> _keySummary = GlobalKey<ProfilePageState>();

class ProfilePageState extends State<ProfilePage> {
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
    await _keyProfile.currentState?.save();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(children: [
          Profile(
            key: _keyProfile,
            self: false,
          ),

          // circular progress indicator
          // if (_isLoading) Center(child: CircularProgressIndicator()),
        ]),
      ),
    );
  }
}
