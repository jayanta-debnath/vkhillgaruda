import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';

class TabEvents extends StatefulWidget {
  final PerformerProfile? profile;

  const TabEvents({this.profile, super.key});

  @override
  State<TabEvents> createState() => TabEventsState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<TabEventsState> _keySummary = GlobalKey<TabEventsState>();

class TabEventsState extends State<TabEvents> {
  final Lock _lock = Lock();
  bool _isLoading = false;
  PerformerProfile? _profile;

  // lists
  final List<EventRecord> _events = [];

  @override
  void initState() {
    super.initState();

    _profile = widget.profile;

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _events.clear();

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
        _events.clear();
        String dbpath =
            "${Const().dbrootSangeetSeva}/Events/${_profile!.mobile}";

        Map<String, dynamic> json = await FB().getJson(path: dbpath);

        // loop through dates
        for (Map json2Raw in json.values) {
          Map<String, dynamic> json2 = Map<String, dynamic>.from(json2Raw);

          // loop through time
          for (var json3Raw in json2.values) {
            Map<String, dynamic> json3 = Map<String, dynamic>.from(json3Raw);
            _events.add(EventRecord.fromJson(json3));
          }
        }
      }

      // refresh all child widgets

      // listen for database events
    });

    setState(() {
      _isLoading = false;
    });
  }

  void setProfile(PerformerProfile profile) {
    setState(() {
      _profile = profile;
    });
  }

  Widget _createEventTile(int index) {
    if (_profile == null) {
      return SizedBox();
    }

    ImageProvider image;
    if (_profile!.profilePicUrl == null || _profile!.profilePicUrl!.isEmpty) {
      image = const AssetImage("assets/images/Logo/SangeetSeva.png");
    } else {
      image = NetworkImage(_profile!.profilePicUrl!);
    }

    Icon statusIcon = Icon(Icons.help_outline, color: Colors.orange);
    if (_events[index].status == "Approved") {
      statusIcon = Icon(Icons.check_circle, color: Colors.green);
    } else if (_events[index].status == "Rejected") {
      statusIcon = Icon(Icons.cancel_outlined, color: Colors.red);
    }

    return Widgets().createTopLevelCard(
      context: context,
      child: ListTileCompact(
        leading: CircleAvatar(
          backgroundImage: image,
        ),
        title: Text(DateFormat("EEE, dd MMM yyyy").format(_events[index].date)),
        subtitle: Text(
            "${DateFormat("HH:mm").format(_events[index].eventStart)} to ${DateFormat("HH:mm").format(_events[index].eventEnd)}"),
        trailing: statusIcon,
      ),
    );
  }

  void _onAddNewEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SlotSelection(
                title: "Event Registration",
                profile: _profile!,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return (_profile != null)
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _events.length + 3,
                    itemBuilder: (BuildContext context, int index) {
                      // leave some space on top
                      if (index == 0) {
                        return SizedBox(
                          height: 10,
                        );
                      }

                      // the button
                      if (index == 1) {
                        return Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                              onPressed: _onAddNewEvent,
                              child: Text("+ Add new event")),
                        );
                      }

                      // leave some space at the bottom
                      if (index == _events.length + 2) {
                        return SizedBox(
                          height: 100,
                        );
                      }

                      // the actual list widgets
                      return _createEventTile(index - 2);
                    }),
          )
        : Center(child: Text("Profile not set "));
  }
}
