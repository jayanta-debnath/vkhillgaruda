import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/event_details.dart';
import 'package:vkhgaruda/sangeet_seva/slot_selection.dart';
import 'package:vkhgaruda/sangeet_seva/ssconst.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhgaruda/sangeet_seva/datatypes.dart';

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
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // access control

    await _lock.synchronized(() async {
      // your code here

      // read database and populate data
      if (widget.profile != null) {
        _events.clear();
        String dbpath =
            "${Const().dbrootSangeetSeva}/EventsByMobile/${widget.profile!.mobile}";

        Map<String, dynamic> json =
            await FB().getJson(path: dbpath, silent: true);

        // loop through dates
        for (Map json2Raw in json.values) {
          Map<String, dynamic> json2 = Map<String, dynamic>.from(json2Raw);

          // loop through time
          for (var json3Raw in json2.values) {
            Map<String, dynamic> json3 = Map<String, dynamic>.from(json3Raw);
            _events.add(EventRecord.fromJson(json3));
          }

          // sort the events
          _events.sort((a, b) {
            if (a.date.isBefore(b.date)) {
              return -1;
            } else if (a.date.isAfter(b.date)) {
              return 1;
            } else {
              return 0;
            }
          });
        }
      }

      // refresh all child widgets

      // listen for database events
    });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> save() async {
    return;
  }

  Widget _createEventTile(int index) {
    if (widget.profile == null) {
      return SizedBox();
    }

    ImageProvider image;
    if (widget.profile!.profilePicUrl == null ||
        widget.profile!.profilePicUrl!.isEmpty) {
      image = const AssetImage("assets/images/Logo/SangeetSeva.png");
    } else {
      image = NetworkImage(widget.profile!.profilePicUrl!);
    }

    // set color to grey out past events
    Color color = _events[index].eventEnd.isBefore(DateTime.now())
        ? Colors.grey
        : Colors.black;

    return Widgets().createTopLevelCard(
      context: context,
      child: ListTileCompact(
        leading: CircleAvatar(
          backgroundImage: image,
        ),
        title: Text(DateFormat("EEE, dd MMM yyyy").format(_events[index].date),
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(color: color)),
        subtitle: Text(
            "${DateFormat("HH:mm").format(_events[index].eventStart)} to ${DateFormat("HH:mm").format(_events[index].eventEnd)}",
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(color: color)),
        trailing: SSConst().statusIcon[_events[index].status],
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EventDetails(
                    title: "Concert Details",
                    eventStart: _events[index].eventStart,
                    eventEnd: _events[index].eventEnd,
                    doubleBack: false,
                    profile: widget.profile!))),
      ),
    );
  }

  void _onAddNewEvent() {
    if (widget.profile == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetails(
          title: "Concert registration",
          profile: widget.profile!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return (widget.profile != null)
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
