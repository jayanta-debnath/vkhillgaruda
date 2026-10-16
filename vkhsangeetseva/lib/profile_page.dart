import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class ProfilePage extends StatefulWidget {
  final String title;
  final String? icon;
  final bool? self;
  final Function(PerformerProfile user)? onProfileSaved;
  final String? friendMobile;
  final String? fcmToken;
  final String? splashImage;

  const ProfilePage(
      {super.key,
      required this.self,
      required this.title,
      this.onProfileSaved,
      this.icon,
      this.friendMobile,
      this.fcmToken,
      this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // scalars
  final GlobalKey<ProfileState> _keyProfile = GlobalKey<ProfileState>();
  bool _isLoading = true;

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    await _keyProfile.currentState?.refresh();

    // perform async operations here

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              _keyProfile.currentState?.save();
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(children: [
              Profile(
                key: _keyProfile,
                self: widget.self,
              ),

              // circular progress indicator
              // if (_isLoading) Center(child: CircularProgressIndicator()),
            ]),
          ),
        ),
      ),
    );
  }
}
