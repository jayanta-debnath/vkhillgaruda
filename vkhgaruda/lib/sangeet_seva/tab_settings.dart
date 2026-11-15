import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/datatypes.dart';
import 'package:vkhpackages/vkhpackages.dart';

class TabSettings extends StatefulWidget {
  final PerformerProfile? profile;
  final Function(PerformerProfile?) onProfileUpdate;

  const TabSettings({super.key, this.profile, required this.onProfileUpdate});

  @override
  State<TabSettings> createState() => TabSettingsState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<TabSettingsState> _keySummary = GlobalKey<TabSettingsState>();

class TabSettingsState extends State<TabSettings> {
  final Lock _lock = Lock();
  bool _isLoading = false;
  PerformerProfile? _profile;

  // lists

  @override
  void initState() {
    super.initState();

    _profile = widget.profile;

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
      if (_profile != null) {
        String dbpath =
            "${Const().dbrootSangeetSeva}/Users/${_profile!.mobile}";

        var data = await FB().getJson(path: dbpath, silent: false);
        PerformerProfile profile =
            Utils().convertRawToDatatype(data, PerformerProfile.fromJson);
        _profile!.rating = profile.rating ?? 0;
      }

      // refresh all child widgets

      // listen for database events
    });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> save() async {
    if (_profile != null) {
      String dbpath =
          "${Const().dbrootSangeetSeva}/Users/${widget.profile!.mobile}/rating";

      await FB().setValue(path: dbpath, value: _profile!.rating);

      widget.onProfileUpdate(_profile);
    }
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
                          Expanded(
                              flex: 1,
                              child: Text(
                                "User ID:",
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              )),
                          Expanded(
                              flex: 4,
                              child: Text(
                                _profile?.id.toString().padLeft(4, '0') ?? "-",
                              ))
                        ],
                      ),

                      // rating
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Expanded(
                              flex: 1,
                              child: Text(
                                "Rating:",
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              )),
                          Expanded(
                              flex: 4,
                              child: RatingBar.builder(
                                initialRating: (_profile == null)
                                    ? 0
                                    : _profile!.rating!.toDouble(),
                                minRating: 1,
                                allowHalfRating: false,
                                itemCount: 5,
                                itemSize: 32,
                                itemBuilder: (context, index) =>
                                    const Icon(Icons.star, color: Colors.amber),
                                onRatingUpdate: (rating) {
                                  if (_profile != null) {
                                    _profile!.rating = rating.toInt();
                                    save();
                                  }
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
