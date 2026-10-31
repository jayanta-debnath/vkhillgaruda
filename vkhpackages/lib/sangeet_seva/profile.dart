import 'dart:convert';
import 'dart:typed_data';
import 'package:fast_image_resizer/fast_image_resizer.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class Profile extends StatefulWidget {
  final Function(PerformerProfile user)? onProfileSaved;
  final PerformerProfile? oldUserDetails;

  const Profile({super.key, this.onProfileSaved, this.oldUserDetails});

  @override
  State<Profile> createState() => ProfileState();
}

// hint: put the global key as a member of the calling class
// instantiate this class with a global key
// final GlobalKey<ProfileState> _keyProfile = GlobalKey<ProfileState>();

class ProfileState extends State<Profile> {
  // scalars
  final Lock _lock = Lock();
  final double _imagesize = 200;
  bool _isLoading = true;
  String _profilePicUrl = '';
  late String _salutation;
  bool _isAdmin = false;
  PerformerProfile? _profile;

  // lists
  List<SangeetExp> _exp = [];
  List<String> _youtubeLinks = [];
  List<String> _audioClips = [
    "",
    "",
    "",
  ]; // this is local file path before upload. after upload it becomes firestore url.

  // controllers
  final TextEditingController _mobileController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _credController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // set admin status
    Utils().isAdmin().then(
      (value) => setState(() {
        _isAdmin = value;
      }),
    );

    _salutation = SSConst().salutations[0];
    _profile = widget.oldUserDetails;

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _youtubeLinks.clear();
    _audioClips.clear();

    // clear all controllers and focus nodes
    _nameController.dispose();
    _mobileController.dispose();
    _formKey.currentState?.dispose();

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    await _lock.synchronized(() async {
      // perform your work here

      if (_profile != null) {
        _salutation = _profile!.salutation;
        _nameController.text = _profile!.name;
        _mobileController.text = _profile!.mobile;
        _profilePicUrl = _profile!.profilePicUrl ?? "";
        _credController.text = _profile!.credentials;
        _exp = _profile!.exps;
        _youtubeLinks = _profile!.youtubeUrls;
        _audioClips = _profile!.audioClipUrls;
      }

      // hack: facilitate browse button always for audio clips
      if (_audioClips.isEmpty || _audioClips.last.isNotEmpty) {
        _audioClips.add("");
      }
    });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _save({bool goback = true}) async {
    // validation of form
    if (!_formKey.currentState!.validate()) {
      Toaster().error('There are errors in the form');
      return;
    }

    // no abrupt returns after this point
    setState(() {
      _isLoading = true;
    });

    // Convert name to title case
    String name = _nameController.text;
    setState(() {
      _nameController.text = name
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          })
          .join(' ');

      _nameController.text = _nameController.text.trim();
    });

    // create user details object
    _profile = PerformerProfile(
      salutation: _salutation,
      name: _nameController.text,
      mobile: _mobileController.text,
      profilePicUrl: _profilePicUrl,
      exps: _exp,
      credentials: _credController.text,
      youtubeUrls: _youtubeLinks.where((link) => link.isNotEmpty).toList(),
      audioClipUrls: _audioClips.where((link) => link.isNotEmpty).toList(),
      referrals: [],
    );

    // write to database
    await Utils().setUserDetails(_profile!);

    // invoke the callback
    if (widget.onProfileSaved != null) {
      widget.onProfileSaved!(_profile!);
    }

    Toaster().info('Profile saved');

    setState(() {
      _isLoading = false;
    });

    if (mounted && goback == true) {
      Navigator.of(context).pop();
    }
  }

  Widget _createAudioClipTile(int index) {
    String title = _getFileNameFromUrl(_audioClips[index]);

    return Column(
      children: [
        if (index == 0 || _audioClips[index - 1].isNotEmpty)
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  softWrap: false,
                ),
              ),

              // Browse button
              SizedBox(width: 10),
              if (title == "No files selected")
                OutlinedButton(
                  child: Text("Browse"),
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker
                        .platform // make sure to have package FilePicker version 10.1.2
                        .pickFiles(type: FileType.audio, withData: true);
                    if (result == null) return;
                    PlatformFile file = result.files.first;

                    // upload to firestore
                    setState(() {
                      _isLoading = true;
                    });
                    UserBasics? basics = Utils().getUserBasics();
                    if (basics == null) {
                      Toaster().error('User not found');
                      return;
                    }
                    String ext = file.name.split('.').last;
                    String dstPath =
                        "${Const().dbrootSangeetSeva}/Users/${basics.mobile}/audio$index.$ext";
                    String url = await FS().uploadBytes(
                      dstPath: dstPath,
                      bytes: file.bytes!,
                    );

                    setState(() {
                      _audioClips[index] = url;

                      // hack for the browse button not to disappear
                      if (_audioClips.last.isNotEmpty) {
                        _audioClips.add("");
                      }

                      _isLoading = false;
                    });

                    if (widget.oldUserDetails != null) {
                      await _save(goback: false);
                    }
                  },
                ),

              // play button
              if (title != "No files selected")
                IconButton(
                  icon: Icon(Icons.play_arrow, size: 16),
                  onPressed: () {
                    if (_audioClips[index].isNotEmpty) {
                      launchUrl(Uri.parse(_audioClips[index]));
                    }
                  },
                ),

              // delete button
              if (title != "No files selected")
                IconButton(
                  icon: Icon(Icons.delete, size: 16),
                  onPressed: () async {
                    Widgets().showConfirmDialog(
                      context,
                      "Are you sure to delete the audio clip?",
                      "Delete",
                      () async {
                        String path = FS().getPathFromUrl(_audioClips[index]);
                        await FS().deleteFile(filePath: path);

                        setState(() {
                          _audioClips.removeAt(index);
                        });

                        if (widget.oldUserDetails != null) {
                          await _save(goback: false);
                        }
                      },
                    );
                  },
                ),
            ],
          ),
        if (index < _audioClips.length - 1) SizedBox(height: 10),
      ],
    );
  }

  Widget _createSangeetSadhanaTile(int index) {
    return ListTile(
      leading: Text(
        (index + 1).toString(),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      title: Text(
        "${_exp[index].category} - ${_exp[index].subcategory} (${_exp[index].yrs} years)",
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete, size: 16),
        onPressed: () async {
          Widgets().showConfirmDialog(
            context,
            "Are you sure to delete?",
            "Delete",
            () async {
              setState(() {
                _exp.removeAt(index);
              });

              if (widget.oldUserDetails != null) {
                await _save(goback: false);
              }
            },
          );
        },
      ),
    );
  }

  Widget _createYoutubeTile(int index) {
    return ListTile(
      leading: Text(
        (index + 1).toString(),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      title: GestureDetector(
        onTap: () {
          if (_youtubeLinks[index].isNotEmpty) {
            launchUrl(Uri.parse(_youtubeLinks[index]));
          }
        },
        child: Text(
          _youtubeLinks[index],
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete, size: 16),
        onPressed: () async {
          Widgets().showConfirmDialog(
            context,
            "Are you sure to delete?",
            "Delete",
            () async {
              setState(() {
                _youtubeLinks.removeAt(index);
              });

              if (widget.oldUserDetails != null) {
                await _save(goback: false);
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    if (!_isAdmin) {
      Toaster().error('You cannot change other\'s profile picture');
      return;
    }

    XFile? image;
    final ImagePicker picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a photo'),
                onTap: () async {
                  image = await picker.pickImage(source: ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
                onTap: () async {
                  image = await picker.pickImage(source: ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );

    String downloadUrl = '';
    if (image != null) {
      // compress the image
      final rawImage = await image!.readAsBytes();
      final ByteData? byteData = await resizeImage(
        Uint8List.view(rawImage.buffer),
        height: _imagesize.toInt(),
      );
      if (byteData == null) {
        Toaster().error('Error compressing image');
        return;
      }
      final bytes = byteData.buffer.asUint8List();

      setState(() {
        _isLoading = true;
      });

      // upload to firestore
      String path =
          "${Const().dbrootSangeetSeva}/Users/${_mobileController.text}/profile.png";
      final storageRef = FirebaseStorage.instance.ref();
      final fileRef = storageRef.child(path);

      try {
        await fileRef.putData(bytes);
        downloadUrl = await fileRef.getDownloadURL();
      } catch (e) {
        Toaster().error('Error uploading file: $e');
      }

      _profilePicUrl = downloadUrl;
      Toaster().info('Image uploaded successfully');
    } else {
      Toaster().error('No image selected');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showDialogSangeetExp(BuildContext context) async {
    String selectedExpertiseType = "Vocal";
    String selectedSkill = SSConst().vocalSkills[0];
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController othersController = TextEditingController();
    final TextEditingController yearsController = TextEditingController();

    await Widgets().showResponsiveDialog(
      context: context,
      title: 'Sangeet sadhana details',
      child: Form(
        key: formKey,
        child: Column(
          children: [
            // stateful widgets
            SizedBox(height: 10),
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  children: [
                    // radio for vocal/instrumental
                    RadioRow(
                      items: ["Vocal", "Instrumental"],
                      onChanged: (String value) {
                        setState(() {
                          selectedExpertiseType = value;
                          selectedSkill =
                              value == "Vocal"
                                  ? SSConst().vocalSkills[0]
                                  : SSConst().instrumentSkills[0];
                        });
                      },
                    ),

                    // dropdown for skills
                    SizedBox(height: 10),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedSkill,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedSkill = newValue!;
                        });
                      },
                      items:
                          selectedExpertiseType == "Vocal"
                              ? SSConst().vocalSkills
                                  .map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  })
                                  .toList()
                              : SSConst().instrumentSkills
                                  .map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  })
                                  .toList(),
                    ),

                    // hidden box for others
                    if (selectedSkill == "Others")
                      TextFormField(
                        controller: othersController,
                        decoration: InputDecoration(
                          labelText: 'Please specify',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Provide valid input';
                          }
                          return null;
                        },
                      ),
                  ],
                );
              },
            ),

            // Stateless widgets
            // exp in years
            SizedBox(height: 10),
            TextFormField(
              controller: yearsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Years of sadhana"),
              validator: (value) {
                if (value == null || value.isEmpty || int.parse(value) < 0) {
                  return 'Provide valid input';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          child: Text('Add'),
          onPressed: () {
            // validate
            if (!formKey.currentState!.validate()) {
              return;
            }

            // Handle the add logic here
            SangeetExp exp = SangeetExp(
              category: selectedExpertiseType,
              subcategory:
                  selectedSkill == "Others"
                      ? othersController.text
                      : selectedSkill,
              yrs: int.parse(yearsController.text),
            );
            setState(() {
              _exp.add(exp);
            });

            // clear all local lists

            // clear all local controllers and focus nodes

            // close the dialog
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Future<void> _showDialogYoutube(BuildContext context) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController youtubeController = TextEditingController();
    final FocusNode youtubeFocusNode = FocusNode();

    // Request focus after the dialog is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      youtubeFocusNode.requestFocus();
    });

    await Widgets().showResponsiveDialog(
      context: context,
      title: 'Youtube links',
      child: Form(
        key: formKey,
        child: Column(
          children: [
            SizedBox(height: 10),
            TextFormField(
              controller: youtubeController,
              focusNode: youtubeFocusNode,
              decoration: InputDecoration(
                labelText: "link to your performance",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Provide valid input';
                }

                if (!RegExp(
                  r'^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.?be)\/.+$',
                ).hasMatch(value)) {
                  return 'Please enter a valid youtube link';
                }

                // check if the link is already present
                if (_youtubeLinks.contains(value)) {
                  return 'This link is already added';
                }

                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          child: Text('Add'),
          onPressed: () {
            // validate
            if (!formKey.currentState!.validate()) {
              return;
            }

            // Handle the add logic here
            setState(() {
              _youtubeLinks.add(youtubeController.text);
            });

            // clear all local lists

            // clear all local controllers and focus nodes

            // close the dialog
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  String _getFileNameFromUrl(String url) {
    if (url.isEmpty) return "No files selected";

    if (url.substring(0, 8) == "https://") {
      Uri uri = Uri.parse(url);
      return uri.pathSegments.last.split('/').last;
    } else {
      return "Local: ${url.split('/').last}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : Form(
          key: _formKey,
          child: Column(
            children: [
              // leave some space at top
              SizedBox(height: 10),

              // picture
              SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: _imagesize,
                  height: _imagesize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  child:
                      _profilePicUrl.isEmpty
                          ? TextButton(
                            onPressed: _pickAndUploadImage,
                            child: Text("Upload"),
                          )
                          : ClipRRect(
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Image.network(
                                _profilePicUrl,
                                fit: BoxFit.cover,
                                width: _imagesize,
                                height: _imagesize,
                              ),
                            ),
                          ),
                ),
              ),

              // salutation
              SizedBox(height: 10),
              Widgets().createTopLevelCard(
                context: context,
                title: "Basic details",
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Salutation',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.0,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _salutation,
                            onChanged: (String? newValue) {
                              setState(() {
                                _salutation = newValue!;
                              });
                            },
                            items:
                                SSConst().salutations
                                    .map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    })
                                    .toList(),
                          ),
                        ),
                      ),

                      // name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Name cannot be empty';
                          }
                          if (value.length < 3) {
                            return 'Please enter full name';
                          }
                          return null;
                        },
                      ),

                      // mobile
                      TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(labelText: 'Mobile'),
                        readOnly: _isAdmin ? false : true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mobile number cannot be empty';
                          }
                          if (value.length != 10) {
                            return 'Please enter 10 digit mobile number';
                          }
                          return null;
                        },
                      ),

                      // Sangeet credentials
                      TextFormField(
                        controller: _credController,
                        decoration: const InputDecoration(
                          labelText: 'Sangeet academic details',
                          hintText: "e.g. MA in music",
                        ),
                        validator: (value) {
                          // if (value == null || value.isEmpty) {
                          //   return 'Field cannot be empty';
                          // }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // sangeet exp details
              Widgets().createTopLevelCard(
                context: context,
                title: "Sangeet sadhana details",
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...List.generate(_exp.length, (index) {
                            return _createSangeetSadhanaTile(index);
                          }),
                        ],
                      ),
                    ),

                    // button for sangeet exp
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () async {
                        await _showDialogSangeetExp(context);

                        if (widget.oldUserDetails != null) {
                          await _save(goback: false);
                        }
                      },
                      child: Text(
                        _exp.isEmpty
                            ? "Add sangeet sadhana details"
                            : "Add more ...",
                      ),
                    ),
                  ],
                ),
              ),

              // youtube links
              if (_isAdmin)
                Widgets().createTopLevelCard(
                  context: context,
                  title: "Performance details",
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...List.generate(_youtubeLinks.length, (index) {
                                return _createYoutubeTile(index);
                              }),
                            ],
                          ),
                        ),

                        // button for adding youtube link
                        SizedBox(height: 20),
                        TextButton(
                          onPressed: () async {
                            await _showDialogYoutube(context);

                            if (widget.oldUserDetails != null) {
                              await _save(goback: false);
                            }
                          },
                          child: Text(
                            _youtubeLinks.isEmpty
                                ? "Add youtube link"
                                : "Add more youtube links",
                          ),
                        ),

                        // upload audio clip
                        SizedBox(height: 20),
                        Text(
                          (_youtubeLinks.isEmpty && _audioClips.isEmpty)
                              ? "Upload audio clip of your performance"
                              : "Upload audio clip (optional)",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 10),
                        ...List.generate(_audioClips.length, (index) {
                          return _createAudioClipTile(index);
                        }),
                      ],
                    ),
                  ),
                ),

              // leave some space at bottom
              SizedBox(height: 100),
            ],
          ),
        );
  }
}
