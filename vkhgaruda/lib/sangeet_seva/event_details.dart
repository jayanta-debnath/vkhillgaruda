import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vkhgaruda/sangeet_seva/record_page.dart';
import 'package:vkhgaruda/sangeet_seva/slot_selection.dart';
import 'package:vkhgaruda/sangeet_seva/ssconst.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhgaruda/sangeet_seva/datatypes.dart';

class EventDetails extends StatefulWidget {
  final String title;
  final String? icon;
  final DateTime? selectedDate;
  final EventRecord? oldEvent;
  final bool? readOnly;
  final DateTime? eventStart;
  final DateTime? eventEnd;
  final PerformerProfile profile;
  final bool? doubleBack;

  const EventDetails(
      {super.key,
      required this.title,
      this.icon,
      this.selectedDate,
      this.oldEvent,
      this.readOnly,
      this.eventStart,
      this.eventEnd,
      required this.profile,
      this.doubleBack});

  @override
  // ignore: library_private_types_in_public_api
  _EventDetailsState createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  // scalars
  bool _isLoading = true;
  PerformerProfile? _mainPerformer;
  late DateTime _eventStart;
  late DateTime _eventEnd;
  String _eventStatus = "Pending";
  String _note = "";
  bool _isAdmin = false;
  final GlobalKey<SlotSelectionState> _keySlotSelection =
      GlobalKey<SlotSelectionState>();

  // lists
  final List<PerformerProfileMini> _performers = [];
  int _guests = 0;
  final List<String> _songs = [];

  // controllers, listeners and focus nodes
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _raagaController = TextEditingController();
  final TextEditingController _taalaController = TextEditingController();
  final TextEditingController _notePerformerController =
      TextEditingController();
  final TextEditingController _noteTempleController = TextEditingController();
  List<StreamSubscription<DatabaseEvent>> _listeners = [];

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

    _mainPerformer = widget.profile;

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
    _notePerformerController.dispose();
    _noteTempleController.dispose();

    // listeners
    for (var listener in _listeners) {
      listener.cancel();
    }

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    // perform async operations here

    _isAdmin = await Utils().isAdmin();

    // fetch user details
    String mobile = _mainPerformer!.mobile;
    FB()
        .pathExists(
      "${Const().dbrootSangeetSeva}/Users/$mobile",
    )
        .then((userExists) async {
      Map<String, dynamic> userdetailsJson = {};
      if (userExists) {
        userdetailsJson = await FB().getJson(
          path: "${Const().dbrootSangeetSeva}/Users/$mobile",
        );
      } else {
        Toaster().error("User not found");
      }

      if (userdetailsJson.isNotEmpty) {
        _mainPerformer = PerformerProfile.fromJson(userdetailsJson);
      }
    });

    // prompt to select slot
    if (widget.oldEvent == null && mounted && _mainPerformer != null) {
      await _showSlotSelectionDialog(context);
    }

    // preferred event time
    _eventStart = widget.eventStart ?? _eventStart;
    _eventEnd = widget.eventEnd ?? _eventEnd;
    if (widget.readOnly == null || widget.readOnly == false) {
      // edit event
      if (widget.oldEvent != null) {
        _eventStart = widget.oldEvent!.eventStart;
        _eventEnd = widget.oldEvent!.eventEnd;
        _eventStatus = widget.oldEvent!.status;
      }
    }

    // read the event details
    EventRecord? performanceRequest;
    if (widget.oldEvent != null) {
      String dbdate = DateFormat("yyyy-MM-dd").format(widget.oldEvent!.date);
      String slotName = DateFormat("HH_mm").format(widget.oldEvent!.eventStart);
      String dbpath =
          "${Const().dbrootSangeetSeva}/EventsByMobile/$mobile/$dbdate/$slotName";
      FB().getJson(path: dbpath).then(
        (Map<String, dynamic> data) {
          if (data.isEmpty && !mounted) {
            return;
          }

          performanceRequest = Utils().convertRawToDatatype(
            data,
            EventRecord.fromJson,
          );

          setState(() {
            _eventStatus = performanceRequest!.status;

            // performers
            if (widget.oldEvent != null) {
              _performers.clear();
              _songs.clear();
              if (widget.oldEvent != null) {
                // populate the lists
                _performers.addAll(performanceRequest!.performers);
                _guests = performanceRequest!.guests;
                _songs.addAll(performanceRequest!.songs);
                _notePerformerController.text =
                    performanceRequest!.notePerformer;
              }
            }

            PerformerProfileMini self = PerformerProfileMini(
              salutation: _mainPerformer!.salutation == "Others"
                  ? ""
                  : _mainPerformer!.salutation,
              name: _mainPerformer!.name,
              specialization: "Vocalist",
            );
            if (_performers.isEmpty) {
              _performers.add(self);
            }
          });
        },
      );

      _addListeners(dbpath);
    }

    // refresh all child widgets

    // perform sync operations here

    setState(() {
      _isLoading = false;
    });
  }

  void _addListeners(String dbpath) {
    for (var listener in _listeners) {
      listener.cancel();
    }
    FB().listenForChange(
      dbpath,
      FBCallbacks(
        // add
        add: (data) {
          refresh();
        },

        // edit
        edit: () {
          refresh();
        },

        // delete
        delete: (data) async {
          refresh();
        },

        // get listeners
        getListeners: (listeners) {
          _listeners = listeners;
        },
      ),
    );
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
        trailing: _isAdmin
            ? Widgets().createContextMenu(
                items: ["Edit", "Delete"],
                onPressed: (String action) async {
                  switch (action) {
                    case "Edit":
                      await _showAddSongDialog(context: context, index: index);
                      if (widget.oldEvent != null) {
                        _onSubmit(goback: false);
                      }
                      break;
                    case "Delete":
                      Widgets().showConfirmDialog(
                        context,
                        "Are you sure to delete the song?",
                        "Delete",
                        () async {
                          setState(() {
                            _songs.removeAt(index);
                          });
                          if (widget.oldEvent != null) {
                            _onSubmit(goback: false);
                          }
                        },
                      );
                      break;
                  }
                },
              )
            : null);
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
        trailing: _isAdmin
            ? Widgets().createContextMenu(
                items: ["Edit", "Remove"],
                onPressed: (String action) async {
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
                        context,
                        "Are you sure to remove performer?",
                        "Remove",
                        () async {
                          setState(() {
                            _performers.removeAt(index);
                          });
                          if (widget.oldEvent != null) {
                            _onSubmit(goback: false);
                          }
                        },
                      );
                      break;
                  }
                },
              )
            : null);
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

    // populate the data structure
    EventRecord performanceRequest = EventRecord(
      date: _eventStart,
      eventStart: _eventStart,
      eventEnd: _eventEnd,
      eventRequesterMobile: _mainPerformer!.mobile,
      performers: _performers,
      guests: _guests,
      songs: _songs,
      notePerformer: _notePerformerController.text,
      status: "Pending",
    );

    // save to firebase
    String mobile = "";
    String dbdate = DateFormat("yyyy-MM-dd").format(performanceRequest.date);
    String slotName = DateFormat("HH_mm").format(performanceRequest.eventStart);

    mobile = _mainPerformer!.mobile;
    FB()
        .setJson(
      path:
          "${Const().dbrootSangeetSeva}/EventsByMobile/$mobile/$dbdate/$slotName",
      json: performanceRequest.toJson(),
    )
        .then(
      (value) {
        FB().addToList(
            listpath: "${Const().dbrootSangeetSeva}/EventsByDate/$dbdate",
            data: {
              "path":
                  "${Const().dbrootSangeetSeva}/EventsByMobile/$mobile/$dbdate/$slotName"
            });
      },
    );

    // show success message
    Toaster().info("Saved");

    // go to homepage
    if (goback && mounted) {
      Navigator.pop(context);
      if (widget.doubleBack ?? false) {
        Navigator.pop(context);
      }
    }
  }

  // action = Approved or Rejected
  Future<void> _performAction(String action) async {
    String dbdate = DateFormat("yyyy-MM-dd").format(_eventStart);
    String slotName = DateFormat("HH_mm").format(_eventStart);
    String eventPath =
        "${Const().dbrootSangeetSeva}/EventsByMobile/${_mainPerformer!.mobile}/$dbdate/$slotName";

    // check if event is already submitted
    bool pathExists = await FB().pathExists(eventPath);
    if (!pathExists) {
      await _onSubmit();
    }

    if (_eventStatus == "Approved") {
      // event is already booked

      if (action == "Approved") {
        Toaster().info("Concert is already approved");
        return;
      } else {
        // reject an approved event

        _eventStatus = action;

        if (await FB().pathExists(eventPath)) {
          // change status of event
          _eventStatus = "Rejected";
          _note = _noteTempleController.text;
          await FB().setValue(path: "$eventPath/status", value: _eventStatus);
          await FB().setValue(path: "$eventPath/noteTemple", value: _note);
        }
      }
    } else {
      // event is pending approval or rejected

      _eventStatus = action;

      // set the availability flag in Event
      var eventRaw = await FB().getValue(path: eventPath);
      EventRecord event =
          Utils().convertRawToDatatype(eventRaw, EventRecord.fromJson);
      event.status = action;
      event.noteTemple = _noteTempleController.text;
      eventRaw = event.toJson();
      await FB().setValue(path: eventPath, value: eventRaw);
    }

    Toaster().info("Status updated");
  }

  // action = Pending, Approved, Rejected
  void _showActionDialog(String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Change event to $action"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Are you sure?"),
                SizedBox(height: 10),
                Text("Note from temple:",
                    style: themeGaruda.textTheme.headlineSmall),
                TextField(
                  maxLines: 2,
                  controller: _noteTempleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Mark $action"),
              onPressed: () async {
                Navigator.pop(context);
                await _performAction(action);
              },
            ),
          ],
        );
      },
    );
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
            controller: _notePerformerController,
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
      ],
    );
  }

  Future<void> _showAddSongDialog({
    required BuildContext context,
    int? index,
  }) async {
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
                  if (RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
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
    PerformerProfileMini? oldUser,
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
                    initialValue: salutation.isNotEmpty
                        ? salutation
                        : SSConst().salutations.first,
                    items: SSConst().salutations.map((salutation) {
                      return DropdownMenuItem<String>(
                        value: salutation,
                        child: Text(salutation),
                      );
                    }).toList(),
                    onChanged:
                        performerNameController.text == _mainPerformer?.name &&
                                salutation == _mainPerformer?.salutation
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
                        performerNameController.text == _mainPerformer?.name &&
                                salutation == _mainPerformer?.salutation
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
                          _performers.any(
                            (performer) => performer.name == value,
                          )) {
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
                      initialValue: specialization,
                      items: ["Vocalist", ...SSConst().instrumentSkills].map((
                        specialization,
                      ) {
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
                        decoration: InputDecoration(
                          labelText: "Other specialization",
                        ),
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

            PerformerProfileMini user = PerformerProfileMini(
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

  Future<void> _showSlotSelectionDialog(BuildContext context) {
    return Widgets().showResponsiveDialog(
        context: context,
        actions: [
          ElevatedButton(
            child: Text("OK"),
            onPressed: () {
              SlotSelectionType? slotSelection =
                  _keySlotSelection.currentState?.onSelectSlot();
              setState(() {
                if (slotSelection != null) {
                  _eventStart = slotSelection.startTime;
                  _eventEnd = slotSelection.endTime;
                }
              });
              Navigator.pop(context);
            },
          )
        ],
        skipCancel: true,
        title: "Select slot for concert",
        child: SlotSelection(
            key: _keySlotSelection,
            title: "Select slot for concert",
            profile: _mainPerformer!));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              // save button
              if (_isAdmin &&
                  (widget.readOnly == null || widget.readOnly == false))
                IconButton(
                    icon: Icon(Icons.save), onPressed: () => _onSubmit()),
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

                    // date and time
                    OutlinedButton(
                        onPressed: () => _showSlotSelectionDialog(context),
                        child: Column(
                          children: [
                            Text(
                              DateFormat(
                                "EEE, dd MMM, yyyy",
                              ).format(_eventStart),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              "${Time().convertDateTimeTo12hrFormat(_eventStart)} - ${Time().convertDateTimeTo12hrFormat(_eventEnd)}",
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        )),

                    // approval status
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 1, child: Center(child: Text("Status:"))),
                          Expanded(
                            flex: 2,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _eventStatus,
                              items: ["Pending", "Approved", "Rejected"]
                                  .map((item) {
                                return DropdownMenuItem(
                                  value: item,
                                  child: Center(child: Text(item)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _showActionDialog(value);
                                }
                              },
                            ),
                          ),
                          Expanded(
                              flex: 1,
                              child: SSConst().statusIcon[_eventStatus] ??
                                  Container())
                        ],
                      ),
                    ),
                    // Container(
                    //   padding: EdgeInsets.symmetric(
                    //     vertical: 1,
                    //     horizontal: 5,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color: _eventStatus == "Approved"
                    //         ? Colors.green
                    //         : (_eventStatus == "Rejected"
                    //             ? Colors.red
                    //             : Colors.orange),
                    //     borderRadius: BorderRadius.circular(12),
                    //     border: Border.all(width: 1, color: Colors.grey),
                    //   ),
                    //   child: Text(
                    //     "Status: $_eventStatus",
                    //     style: TextStyle(
                    //       color: Colors.white,
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    // ),

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
                    if (_mainPerformer != null)
                      Widgets().createTopLevelCard(
                        context: context,
                        title: "Concert requester",
                        child: ListTileCompact(
                            leading: CircleAvatar(
                              backgroundImage:
                                  _mainPerformer!.profilePicUrl!.isEmpty
                                      ? null
                                      : NetworkImage(
                                          _mainPerformer!.profilePicUrl ?? "",
                                        ),
                            ),
                            title: Text(
                              "${_mainPerformer!.salutation == "Others" ? "" : _mainPerformer!.salutation} ${_mainPerformer!.name}",
                            ),
                            subtitle: Widgets().createResponsiveRow(context, [
                              Icon(Icons.phone, size: 16),
                              Text(_mainPerformer!.mobile),
                              SizedBox(width: 4),
                              Icon(Icons.workspace_premium, size: 16),
                              Text(_mainPerformer!.credentials),
                            ]),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => RecordPage(
                                            title: "Profile",
                                            profile: _mainPerformer,
                                          )));
                            }),
                      ),

                    // Performers
                    Widgets().createTopLevelCard(
                      context: context,
                      title: "Performers",
                      child: Column(
                        children: [
                          Column(
                            children: [
                              ...List.generate(_performers.length, (index) {
                                return _createPerfomerTile(index);
                              }),
                            ],
                          ),

                          // button - add performer team
                          if (widget.readOnly == null ||
                              widget.readOnly == false)
                            TextButton(
                                onPressed: () async {
                                  await _showAddPerformerDialog(
                                      context: context);

                                  if (widget.oldEvent != null) {
                                    _onSubmit(goback: false);
                                  }
                                },
                                child: _isAdmin
                                    ? Text(
                                        _performers.isEmpty
                                            ? "Add performer"
                                            : "Add more performers",
                                      )
                                    : Container()),
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
                          if (_songs.length < 10 &&
                              (widget.readOnly == null ||
                                  widget.readOnly == false))
                            TextButton(
                                onPressed: () async {
                                  await _showAddSongDialog(context: context);
                                  if (widget.oldEvent != null) {
                                    _onSubmit(goback: false);
                                  }
                                },
                                child: _isAdmin
                                    ? Text(
                                        _songs.isEmpty
                                            ? "Add song for event"
                                            : "Add more songs",
                                      )
                                    : Container()),
                        ],
                      ),
                    ),

                    // performer note
                    Widgets().createTopLevelCard(
                      context: context,
                      title: "Note from performer",
                      child: Column(
                        children: [
                          if (_notePerformerController.text.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(_notePerformerController.text),
                            ),
                          TextButton(
                            onPressed: () async {
                              await _showAddNoteDialog(context);
                              if (widget.oldEvent != null) {
                                _onSubmit(goback: false);
                              }
                            },
                            child: _isAdmin
                                ? Text(
                                    _notePerformerController.text.isEmpty
                                        ? "Add some notes"
                                        : "Edit notes",
                                  )
                                : Container(),
                          ),
                        ],
                      ),
                    ),

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
