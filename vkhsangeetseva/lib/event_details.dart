import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhsangeetseva/home.dart';
import 'package:vkhsangeetseva/profile_page.dart';

class EventDetails extends StatefulWidget {
  final String title;
  final String? icon;
  final DateTime selectedDate;
  final EventRecord? oldEvent;
  final bool? readOnly;
  final DateTime? eventStart;
  final DateTime? eventEnd;

  const EventDetails({
    super.key,
    required this.title,
    this.icon,
    required this.selectedDate,
    this.oldEvent,
    this.readOnly,
    this.eventStart,
    this.eventEnd,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EventDetailsState createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  // scalars
  bool _isLoading = true;
  PerformerProfile? _requester;
  final _minSongs = 3;
  late DateTime _eventStart;
  late DateTime _eventEnd;

  // lists
  final List<Performer> _performers = [];
  int _guests = 0;
  final List<String> _songs = [];

  // controllers, listeners and focus nodes
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _raagaController = TextEditingController();
  final TextEditingController _taalaController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  initState() {
    super.initState();

    // set the event start and end time
    if (widget.eventStart != null) {
      _eventStart = widget.eventStart!;
    } else if (widget.oldEvent != null) {
      _eventStart = widget.oldEvent!.eventStart;
    } else {
      _eventStart = DateTime.now();
    }

    if (widget.eventEnd != null) {
      _eventEnd = widget.eventEnd!;
    } else if (widget.oldEvent != null) {
      _eventEnd = widget.oldEvent!.eventEnd;
    } else {
      _eventEnd = DateTime.now();
    }

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _performers.clear();
    _songs.clear();

    // clear all controllers and focus nodes
    _titleController.dispose();
    _raagaController.dispose();
    _taalaController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here

    // fetch form values
    await Utils().fetchUserBasics();
    String mobile = Utils().getUserBasics()!.mobile;
    bool userExists = await FB().pathExists(
      "${Const().dbrootSangeetSeva}/Users/$mobile",
    );
    Map<String, dynamic> userdetailsJson = {};
    if (userExists) {
      userdetailsJson = await FB().getJson(
        path: "${Const().dbrootSangeetSeva}/Users/$mobile",
      );
    } else {
      Toaster().error("User not found");
    }

    // preferred event time
    _eventStart = widget.eventStart ?? _eventStart;
    _eventEnd = widget.eventEnd ?? _eventEnd;
    if (widget.readOnly == null || widget.readOnly == false) {
      // edit event
      if (widget.oldEvent != null) {
        _eventStart = widget.oldEvent!.eventStart;
        _eventEnd = widget.oldEvent!.eventEnd;
      }
    }

    // read the performance details
    EventRecord? performanceRequest;
    if (widget.oldEvent != null) {
      String dbdate = DateFormat("yyyy-MM-dd").format(widget.oldEvent!.date);
      String slotName = DateFormat("HH_mm").format(widget.oldEvent!.eventStart);
      String dbpath =
          "${Const().dbrootSangeetSeva}/Events/$mobile/$dbdate/$slotName";
      Map<String, dynamic> data = await FB().getJson(path: dbpath);
      performanceRequest =
          Utils().convertRawToDatatype(data, EventRecord.fromJson);
    }

    // refresh all child widgets

    // perform sync operations here

    setState(() {
      _isLoading = false;

      if (userdetailsJson.isEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ProfilePage(
                title: "Profile",
                self: true,
                onProfileSaved: (user) {
                  setState(() {
                    _requester = user;
                  });
                },
              );
            },
          ),
        );
      } else {
        _requester = PerformerProfile.fromJson(userdetailsJson);
      }

      // write fcm token if not set
      FirebaseMessaging.instance.getToken().then((fcmToken) {
        if (_requester != null &&
            (_requester!.fcmToken.isEmpty ||
                _requester!.fcmToken != (fcmToken ?? ""))) {
          String dbpath = "${Const().dbrootSangeetSeva}/Users/$mobile/fcmToken";
          FB().setValue(
              path: dbpath, value: fcmToken ?? ""); // no need to await
        }
      });

      // performers
      if (widget.oldEvent != null) {
        _performers.clear();
        _songs.clear();
        if (widget.oldEvent != null) {
          // populate the lists
          _performers.addAll(performanceRequest!.performers);
          _guests = performanceRequest.guests;
          _songs.addAll(performanceRequest.songs);
          _noteController.text = performanceRequest.notePerformer;
        }
      }
      Performer self = Performer(
          salutation:
              _requester!.salutation == "Others" ? "" : _requester!.salutation,
          name: _requester!.name,
          specialization: "Vocalist");
      if (_performers.isEmpty) {
        _performers.add(self);
      }
    });
  }

  Widget _createSongTile(int index) {
    var song = _songs[index];
    var songDetails = song.split(":");
    String title = songDetails[0];
    String raga = songDetails[1];
    String tala = songDetails[2];

    return ListTile(
      leading: Text(
        "${index + 1}",
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      title: Text(title),
      subtitle: (raga.isEmpty && tala.isEmpty)
          ? null
          : Row(
              children: [
                Text("raga: $raga"),
                SizedBox(width: 10),
                Text("tala: $tala"),
              ],
            ),
      trailing: widget.readOnly != null
          ? null
          : Widgets().createContextMenu(
              items: ["Edit", "Delete"],
              onPressed: (
                String action,
              ) async {
                switch (action) {
                  case "Edit":
                    await _showAddSongDialog(context: context, index: index);
                    if (widget.oldEvent != null) {
                      _onSubmit(goback: false);
                    }
                    break;
                  case "Delete":
                    Widgets().showConfirmDialog(
                        context, "Are you sure to delete the song?", "Delete",
                        () async {
                      setState(() {
                        _songs.removeAt(index);
                      });
                      if (widget.oldEvent != null) {
                        _onSubmit(goback: false);
                      }
                    });
                    break;
                }
              }),
    );
  }

  Widget _createPerfomerTile(int index) {
    var member = _performers[index];
    String salutation = member.salutation == "Others" ? "" : member.salutation;
    return ListTile(
      onTap: () {},
      title: Text("$salutation ${member.name}"),
      leading: Text(
        "${index + 1}",
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Row(
              children: [
                Icon(
                  member.specialization == "Vocalist"
                      ? Icons.mic
                      : Icons.music_note,
                  size: 16,
                ),
                SizedBox(width: 5),
                Text(member.specialization),
              ],
            ),
          ],
        ),
      ),
      trailing: widget.readOnly != null
          ? null
          : Widgets().createContextMenu(
              items: ["Edit", "Remove"],
              onPressed: (
                String action,
              ) async {
                switch (action) {
                  case "Edit":
                    await _showAddPerformerDialog(
                      context: context,
                      oldUser: member,
                    );
                    if (widget.oldEvent != null) {
                      _onSubmit(goback: false);
                    }
                    break;
                  case "Remove":
                    Widgets().showConfirmDialog(
                        context, "Are you sure to remove performer?", "Remove",
                        () async {
                      setState(() {
                        _performers.removeAt(index);
                      });
                      if (widget.oldEvent != null) {
                        _onSubmit(goback: false);
                      }
                    });
                    break;
                }
              }),
    );
  }

  Future<void> _deleteEvent() async {
    // validate if event is in the past
    DateTime today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);
    if (widget.oldEvent!.date.isBefore(today)) {
      Toaster().error("Can't delete past event");
      return;
    }

    // delete from events
    UserBasics? basics = Utils().getUserBasics();
    String mobile = "";
    String dbpath = "";
    if (basics == null) {
      Toaster().error("Cant access user data");
      return;
    } else {
      mobile = basics.mobile;
      String dbdate = DateFormat("yyyy-MM-dd").format(widget.selectedDate);
      String slotName = DateFormat("HH_mm").format(_eventStart);
      dbpath = "${Const().dbrootSangeetSeva}/Events/$mobile/$dbdate/$slotName";
      await FB().deleteValue(
        path: dbpath,
      );
    }

    // delete from pending requests
    List pendingEvents = await FB().getList(
      path: "${Const().dbrootSangeetSeva}/PendingRequests",
    );
    int indexP = pendingEvents.indexWhere(
      (element) => element['path'] == dbpath,
    );
    await FB().deleteFromList(
      listpath: "${Const().dbrootSangeetSeva}/PendingRequests",
      index: indexP,
    );

    // show success message
    Toaster().info("Event deleted successfully");

    // go to homepage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return HomePage(title: "Hare Krishna");
        },
      ),
    );
  }

  Future<void> _onSubmit({bool goback = true}) async {
    // validations for edit event
    if (widget.oldEvent != null) {
      // validate if event is already approved
      if (widget.oldEvent!.status == "Approved") {
        Toaster().error("Can't update approved event");
        return;
      }

      // validate if event is in the past
      DateTime today = DateTime.now();
      today = DateTime(today.year, today.month, today.day);
      if (widget.oldEvent!.date.isBefore(today)) {
        Toaster().error("Can't update past event");
        return;
      }
    }

    // validate number of performers
    if (_performers.isEmpty) {
      Toaster().error("Please enter at least 1 performer");
      return;
    }

    // validate list of songs
    if (_songs.length < _minSongs) {
      Toaster().error("Please enter at least $_minSongs songs");
      return;
    }

    // populate the data structure
    EventRecord performanceRequest = EventRecord(
      date: widget.selectedDate,
      eventStart: _eventStart,
      eventEnd: _eventEnd,
      eventRequesterMobile: _requester!.mobile,
      performers: _performers,
      guests: _guests,
      songs: _songs,
      notePerformer: _noteController.text,
      status: "Pending",
    );

    // save to firebase
    UserBasics? basics = Utils().getUserBasics();
    String mobile = "";
    String dbdate = DateFormat("yyyy-MM-dd").format(performanceRequest.date);
    String slotName = DateFormat("HH_mm").format(performanceRequest.eventStart);
    if (basics == null) {
      Toaster().error("Cant access user data");
      return;
    } else {
      mobile = basics.mobile;
      FB().setJson(
        path: "${Const().dbrootSangeetSeva}/Events/$mobile/$dbdate/$slotName",
        json: performanceRequest.toJson(),
      );
    }

    // update referrals
    String dbpath = "${Const().dbrootSangeetSeva}/Users/$mobile/referrals";
    List<dynamic> existingReferrals = await FB().getList(path: dbpath);
    final List<Performer> referrals = [];
    // Add performers to referrals, skipping the one whose name matches _requester!.name
    referrals.addAll(
      _performers.where((p) => p.name != _requester!.name),
    );
    for (var referral in referrals) {
      if (!existingReferrals.contains(referral)) {
        existingReferrals.add(referral);
      }
    }
    await FB()
        .setList(path: dbpath, list: referrals, toJson: (p) => p.toJson());

    // add to pending requests
    if (widget.oldEvent == null || widget.oldEvent!.status != "Pending") {
      FB().addToList(
        listpath: "${Const().dbrootSangeetSeva}/PendingRequests",
        data: {
          "path":
              "${Const().dbrootSangeetSeva}/Events/$mobile/$dbdate/$slotName",
        },
      );
    }

    // show success message
    if (widget.oldEvent == null) {
      if (mounted) {
        await Widgets().showMessage(
          context,
          "Your request has been submitted.\nYou will be notified once your request is approved",
        );
      }

      // notify coordinator
      String date = DateFormat("EEE, dd MM, yyyy").format(widget.selectedDate);
      String startTime = DateFormat("h:mm a").format(_eventStart);
      String endTime = DateFormat("h:mm a").format(_eventEnd);
      Utils().sendNotificationToTopic(
          topic: Const().fcmTopicSSCoordinators,
          title: "New event request",
          body: "Event request for $date [$startTime - $endTime]");
    } else {
      // edit
      Toaster().info("Saved");
    }

    // go to homepage
    if (goback) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return HomePage(title: "Hare Krishna");
          },
        ),
      );
    }
  }

  Future<void> _showAddGuestDialog({
    required BuildContext context,
  }) async {
    FocusNode focusNode = FocusNode();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    int guests = _guests;

    // Request focus after the dialog is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    await Widgets().showResponsiveDialog(
        context: context,
        title: "Number of guests",
        child: Form(
            key: formKey,
            child: TextFormField(
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              initialValue: guests.toString(),
              onChanged: (value) {
                guests = int.parse(value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter a valid number";
                }
                if (int.tryParse(value) == null) {
                  return "Please enter a valid number";
                }
                if (RegExp(
                  r'[!@#$%^&*(),.?":{}|<>]',
                ).hasMatch(value)) {
                  return "Special characters not allowed";
                }
                if (int.parse(value) < 0) {
                  return "Number of guests can't be negative";
                }
                return null;
              },
            )),
        actions: [
          // ok button
          ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                setState(() {
                  _guests = guests;
                });

                Navigator.pop(context);

                if (_guests + _performers.length > 10) {
                  Widgets().showMessage(context,
                      "Nominal charges for prasadam will apply for more than 10 members");
                }
              },
              child: Text("OK"))
        ]);
  }

  Future<void> _showAddNoteDialog(BuildContext context) async {
    FocusNode focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    await Widgets().showResponsiveDialog(
        context: context,
        title: "Add note for performer",
        child: Column(
          children: [
            TextField(
              focusNode: focusNode,
              maxLines: 3,
              controller: _noteController,
              decoration: InputDecoration(
                hintText: "Enter your note here",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: Text("Save"),
          ),
        ]);
  }

  Future<void> _showAddSongDialog(
      {required BuildContext context, int? index}) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    _titleController.clear();

    if (index != null) {
      var songDetails = _songs[index].split(":");
      _titleController.text = songDetails[0];
      _raagaController.text = songDetails[1];
      _taalaController.text = songDetails[2];
    }

    FocusNode focusNode = FocusNode();

    // Request focus after the dialog is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    await Widgets().showResponsiveDialog(
      context: context,
      title: "Add song for event",
      child: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // title
              TextFormField(
                controller: _titleController,
                focusNode: focusNode,
                onChanged: (value) {},
                decoration: InputDecoration(labelText: "Song title"),
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 3) {
                    return "Please enter a valid name";
                  }
                  if (RegExp(
                    r'[0-9!@#$%^&*(),.?":{}|<>]',
                  ).hasMatch(value)) {
                    return "Special characters are not allowed";
                  }
                  return null;
                },
              ),

              SizedBox(height: 10),
              Row(
                children: [
                  // Raga
                  Expanded(
                    child: TextFormField(
                      controller: _raagaController,
                      onChanged: (value) {},
                      decoration: InputDecoration(labelText: "Raga"),
                      validator: (value) {
                        if (value != null &&
                            RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                          return "Special characters are not allowed";
                        }
                        return null;
                      },
                    ),
                  ),

                  // Tala
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _taalaController,
                      onChanged: (value) {},
                      decoration: InputDecoration(labelText: "Tala"),
                      validator: (value) {
                        if (value != null &&
                            RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                          return "Special characters are not allowed";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) {
              return;
            }

            setState(() {
              if (index == null) {
                _songs.add(
                  "${_titleController.text}:${_raagaController.text}:${_taalaController.text}",
                );
              } else {
                // edit mode
                _songs[index] =
                    "${_titleController.text}:${_raagaController.text}:${_taalaController.text}";
              }
            });

            Navigator.pop(context);
          },
          child: Text(index == null ? "Add" : "Update"),
        ),
      ],
    );
  }

  Future<void> _showAddPerformerDialog({
    required BuildContext context,
    Performer? oldUser,
  }) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    String salutation = SSConst().salutations.first;
    TextEditingController performerNameController = TextEditingController();
    TextEditingController otherController = TextEditingController();
    String specialization = "Vocalist";
    String otherSpecialization = "";

    // edit mode
    if (oldUser != null) {
      salutation = oldUser.salutation;
      performerNameController.text = oldUser.name;
      specialization = oldUser.specialization;
    }

    FocusNode focusNode = FocusNode();
    // Request focus after the dialog is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    int salutationFlex = 4;
    await Widgets().showResponsiveDialog(
      context: context,
      title: oldUser == null ? "Add performer" : "Edit performer",
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Row(
              children: [
                // salutation
                Expanded(
                  flex: salutationFlex,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Salutation"),
                    value: salutation.isNotEmpty
                        ? salutation
                        : SSConst().salutations.first,
                    items: SSConst().salutations.map((salutation) {
                      return DropdownMenuItem<String>(
                        value: salutation,
                        child: Text(salutation),
                      );
                    }).toList(),
                    onChanged:
                        performerNameController.text == _requester?.name &&
                                salutation == _requester?.salutation
                            ? null
                            : (value) {
                                salutation = value!;
                              },
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          value.length < 3 ||
                          value.length > 30) {
                        return "Please enter a valid name";
                      }
                      if (RegExp(
                        r'[0-9!@#$%^&*(),.?":{}|<>]',
                      ).hasMatch(value)) {
                        return "Special characters are not allowed";
                      }
                      if (_performers.any((s) => s.name == value)) {
                        return "Member already exists";
                      }

                      return null;
                    },
                  ),
                ),

                SizedBox(width: 10), // Add some spacing between the widgets

                // name
                Expanded(
                  flex: 10 - salutationFlex, // Remaining space after salutation
                  child: TextFormField(
                    controller: performerNameController,
                    focusNode: focusNode,
                    readOnly:
                        performerNameController.text == _requester?.name &&
                                salutation == _requester?.salutation
                            ? true
                            : false,
                    decoration: InputDecoration(labelText: "Name"),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          value.length < 3 ||
                          value.length > 30) {
                        return "Please enter a valid name";
                      }
                      if (RegExp(
                        r'[0-9!@#$%^&*(),;.?":{}|<>]',
                      ).hasMatch(value)) {
                        return "Numbers and special characters are not allowed";
                      }
                      if (oldUser == null &&
                          _performers
                              .any((performer) => performer.name == value)) {
                        return "Performer already exists";
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),

            // specialization
            SizedBox(height: 10),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Specialization"),
                      value: specialization,
                      items: [
                        "Vocalist",
                        ...SSConst().instrumentSkills,
                      ].map((specialization) {
                        return DropdownMenuItem<String>(
                          value: specialization,
                          child: Text(specialization),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          specialization = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please select a specialization";
                        }
                        return null;
                      },
                    ),

                    // other specialization
                    if (specialization == "Other")
                      TextFormField(
                        controller: otherController,
                        decoration:
                            InputDecoration(labelText: "Other specialization"),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a specialization";
                          }
                          if (RegExp(
                            r'[0-9!@#$%^&*(),;.?":{}|<>]',
                          ).hasMatch(value)) {
                            return "Numbers and special characters are not allowed";
                          }
                          return null;
                        },
                        onChanged: (value) {
                          otherSpecialization = value;
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) {
              return;
            }

            Navigator.pop(context);

            Performer user = Performer(
              salutation: salutation,
              name: performerNameController.text,
              specialization: specialization == "Other"
                  ? otherSpecialization
                  : specialization,
            );

            setState(() {
              if (oldUser == null) {
                _performers.add(user);
              } else {
                int index = _performers.indexOf(oldUser);
                if (index != -1) {
                  _performers[index] = user;
                }
              }
            });
          },
          child: Text(oldUser == null ? "Add" : "Update"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              // delete button
              if (widget.oldEvent != null && widget.readOnly == null)
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    Widgets().showConfirmDialog(
                      context,
                      "Are you sure you want to delete this event?",
                      "Delete",
                      () async {
                        await _deleteEvent();
                      },
                    );
                  },
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: refresh,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // leave some space at top
                    SizedBox(height: 10),

                    // approval status
                    if (widget.oldEvent != null &&
                        widget.oldEvent!.status == "Approved")
                      Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 1, horizontal: 5),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.green.shade700, width: 2),
                        ),
                        child: Text(
                          "Approved",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // date
                    Text(
                      DateFormat(
                        "EEE, dd MMM, yyyy",
                      ).format(widget.selectedDate),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),

                    // event timing
                    Text(
                      "${Time().convertDateTimeTo12hrFormat(_eventStart)} - ${Time().convertDateTimeTo12hrFormat(_eventEnd)}",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),

                    // temple notes
                    SizedBox(height: 10),
                    if (widget.oldEvent != null &&
                        widget.oldEvent!.noteTemple.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: ListTile(
                          title: Text("Notes from temple"),
                          subtitle: Text(widget.oldEvent!.noteTemple),
                        ),
                      ),
                    SizedBox(height: 10),

                    // event requester
                    if (_requester != null)
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Event requester",
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(
                                  title: "Profile",
                                  self: true,
                                  onProfileSaved: (user) {
                                    setState(() {
                                      _requester = user;
                                    });
                                  },
                                  friendMobile: _requester!.mobile,
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              _requester!.profilePicUrl,
                            ),
                          ),
                          title: Text(
                            "${_requester!.salutation == "Others" ? "" : _requester!.salutation} ${_requester!.name}",
                          ),
                          subtitle: Widgets().createResponsiveRow(context, [
                            Icon(
                              Icons.phone,
                              size: 16,
                            ),
                            Text(_requester!.mobile),
                            SizedBox(width: 4),
                            Icon(
                              Icons.workspace_premium,
                              size: 16,
                            ),
                            Text(_requester!.credentials),
                          ]),
                        ),
                      ),

                    // Performers
                    Widgets().createTopLevelCard(
                      context: context,
                      title: "Performers",
                      child: Column(
                        children: [
                          Column(children: [
                            ...List.generate(_performers.length, (index) {
                              return _createPerfomerTile(index);
                            }),
                          ]),

                          // button - add performer team
                          if (widget.readOnly == null)
                            TextButton(
                              onPressed: () async {
                                await _showAddPerformerDialog(
                                  context: context,
                                );

                                if (widget.oldEvent != null) {
                                  _onSubmit(goback: false);
                                }
                              },
                              child: Text(
                                _performers.isEmpty
                                    ? "Add performer"
                                    : "Add more performers",
                              ),
                            ),

                          // button - add guest team
                          if (widget.readOnly == null && _guests == 0)
                            TextButton(
                              onPressed: () async {
                                await _showAddGuestDialog(
                                  context: context,
                                );
                                if (widget.oldEvent != null) {
                                  _onSubmit(goback: false);
                                }
                              },
                              child: Text("Add guests"),
                            ),
                        ],
                      ),
                    ),

                    // list of songs
                    Widgets().createTopLevelCard(
                      context: context,
                      title: "List of songs",
                      child: Column(
                        children: [
                          ...List.generate(_songs.length, (index) {
                            return _createSongTile(index);
                          }),

                          // button
                          if (_songs.length < 10 && widget.readOnly == null)
                            TextButton(
                              onPressed: () async {
                                await _showAddSongDialog(context: context);
                                if (widget.oldEvent != null) {
                                  _onSubmit(goback: false);
                                }
                              },
                              child: Text(
                                _songs.isEmpty
                                    ? "Add song for event"
                                    : "Add more songs",
                              ),
                            ),
                        ],
                      ),
                    ),

                    // performer note
                    Widgets().createTopLevelCard(
                      context: context,
                      title: "Note from performer",
                      child: Column(
                        children: [
                          if (_noteController.text.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _noteController.text,
                              ),
                            ),
                          TextButton(
                            onPressed: () async {
                              await _showAddNoteDialog(context);
                              if (widget.oldEvent != null) {
                                _onSubmit(goback: false);
                              }
                            },
                            child: Text(
                              _noteController.text.isEmpty
                                  ? "Add some notes"
                                  : "Edit notes",
                            ),
                          ),
                        ],
                      ),
                    ),

                    // submit button
                    SizedBox(height: 20),
                    if (widget.readOnly == null && widget.oldEvent == null)
                      ElevatedButton(
                          onPressed: _onSubmit, child: Text("Submit")),

                    // leave some space at bottom
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),

        // circular progress indicator
        if (_isLoading)
          LoadingOverlay(image: "assets/images/Logo/SangeetSeva.png"),
      ],
    );
  }
}
