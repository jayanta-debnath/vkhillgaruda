import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/record_page.dart';
import 'package:vkhgaruda/sangeet_seva/profile_list.dart';
import 'package:vkhgaruda/sangeet_seva/event_list.dart';
import 'package:vkhgaruda/sangeet_seva/sswelcome.dart';
import 'package:vkhpackages/vkhpackages.dart';

class SangeetSeva extends StatefulWidget {
  final String title;
  final String? splashImage;

  const SangeetSeva({super.key, required this.title, this.splashImage});

  @override
  // ignore: library_private_types_in_public_api
  _SangeetSevaState createState() => _SangeetSevaState();
}

class _SangeetSevaState extends State<SangeetSeva> {
  // global keys

  // scalars
  final Lock _lock = Lock();
  bool _isAdmin = false;
  bool _isLoading = true;

  // lists

  // controllers, listeners and focus nodes
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes
    for (var element in _listeners) {
      element.cancel();
    }

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // access control
    _isAdmin = await Utils().isAdmin();

    // perform async operations here

    await _lock.synchronized(() async {
      // fetch form values

      // refresh all child widgets

      // perform sync operations here
    });

    // perform any remaining async operations here

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              // registered users
              if (_isAdmin)
                IconButton(
                  icon: Icon(Icons.group),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileList(
                          title: 'Performer Profiles',
                          icon: widget.splashImage,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Column(
                    children: [
                      // leave some space at top
                      SizedBox(height: 10),

                      Column(children: [
                        // your widgets here

                        // welcome banner
                        Widgets().createTopLevelCard(
                            context: context, child: SSWelcome()),

                        Widgets().createTopLevelCard(
                            context: context,
                            child: Center(
                                child: Column(children: [
                              // new profile
                              if (_isAdmin)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Stack(children: [
                                    Widgets().createImageButton(
                                        context: context,
                                        image:
                                            "assets/images/SangeetSeva/AddRequest.png",
                                        imageOnRight: true,
                                        text: "Add new profile",
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => RecordPage(
                                                title: "Add new profile",
                                              ),
                                            ),
                                          );
                                        },
                                        fixedWidth: 250),
                                  ]),
                                ),

                              // view registered events
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Widgets().createImageButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EventList(
                                              title: "List of events",
                                              splashImage: widget.splashImage),
                                        ),
                                      );
                                    },
                                    text: "View registered events",
                                    image:
                                        "assets/images/SangeetSeva/RegisteredEvents.png",
                                    context: context,
                                    imageOnRight: true,
                                    fixedWidth: 250),
                              ),
                            ])))
                      ]),

                      // leave some space at bottom
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // circular progress indicator
        if (_isLoading)
          LoadingOverlay(
            image: widget.splashImage ??
                "assets/images/Logo/KrishnaLilaPark_circle.png",
          ),
      ],
    );
  }
}
