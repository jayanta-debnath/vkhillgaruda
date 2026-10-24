import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/sangeet_seva/profile.dart';
import 'package:vkhpackages/vkhpackages.dart';

class TabEvents extends StatefulWidget {
  final PerformerProfile? profileData;

  const TabEvents({this.profileData, super.key});

  @override
  State<TabEvents> createState() => TabEventsState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<TabEventsState> _keySummary = GlobalKey<TabEventsState>();

class TabEventsState extends State<TabEvents> {
  final Lock _lock = Lock();
  bool _isLoading = false;

  // lists
  final List<EventRecord> _events = [];

  @override
  void initState() {
    super.initState();

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
      if (widget.profileData != null) {
        _events.clear();
        String dbpath =
            "${Const().dbrootSangeetSeva}/Events/${widget.profileData!.mobile}";

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

  Future<void> save() async {}

  Widget _createEventTile(int index) {
    if (widget.profileData == null) {
      return SizedBox();
    }

    ImageProvider image;
    if (widget.profileData!.profilePicUrl == null ||
        widget.profileData!.profilePicUrl!.isEmpty) {
      image = const AssetImage("assets/images/Logo/SangeetSeva.png");
    } else {
      image = NetworkImage(widget.profileData!.profilePicUrl!);
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

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                        onPressed: () {}, child: Text("+ Add new event")),
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
    );
  }
}
