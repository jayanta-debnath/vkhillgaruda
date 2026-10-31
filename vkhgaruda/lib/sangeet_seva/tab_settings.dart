import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/datatypes.dart';
import 'package:vkhpackages/vkhpackages.dart';

class TabSettings extends StatefulWidget {
  final PerformerProfile? profile;

  const TabSettings({this.profile, super.key});

  @override
  State<TabSettings> createState() => TabSettingsState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<TabSettingsState> _keySummary = GlobalKey<TabSettingsState>();

class TabSettingsState extends State<TabSettings> {
  final Lock _lock = Lock();
  bool _isLoading = false;
  int _rating = 0;

  // lists

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
    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // your code here

      // read database and populate data
      if (widget.profile != null) {
        String dbpath =
            "${Const().dbrootSangeetSeva}/Users/${widget.profile!.mobile}";

        var data = await FB().getJson(path: dbpath, silent: false);
        PerformerProfile profile =
            Utils().convertRawToDatatype(data, PerformerProfile.fromJson);
        _rating = profile.rating ?? 0;
      }

      // refresh all child widgets

      // listen for database events
    });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> save() async {
    String dbpath =
        "${Const().dbrootSangeetSeva}/Users/${widget.profile!.mobile}/rating";

    await FB().setValue(path: dbpath, value: _rating);
  }

  @override
  Widget build(BuildContext context) {
    return (widget.profile != null)
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // user id
                      Row(
                        children: [
                          Expanded(flex: 1, child: Text("User ID:")),
                          Expanded(flex: 4, child: Text("00001"))
                        ],
                      ),

                      // rating
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(flex: 1, child: Text("Rating:")),
                          Expanded(
                              flex: 4,
                              child: RatingBar.builder(
                                initialRating: 0,
                                minRating: 1,
                                allowHalfRating: false,
                                itemCount: 5,
                                itemSize: 32,
                                itemBuilder: (context, index) =>
                                    const Icon(Icons.star, color: Colors.amber),
                                onRatingUpdate: (rating) {
                                  _rating = rating.toInt();
                                  save();
                                },
                              ))
                        ],
                      )
                    ],
                  ),
          )
        : Center(child: Text("Profile not set "));
  }
}
