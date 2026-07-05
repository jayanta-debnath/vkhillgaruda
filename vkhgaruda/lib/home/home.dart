import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/deepotsava/deepotsava.dart';
import 'package:vkhgaruda/harinaam/harinaam.dart';
import 'package:vkhgaruda/home/landing.dart';
import 'package:vkhgaruda/home/settings.dart';
import 'package:vkhgaruda/nitya_seva/nitya_seva.dart';
import 'package:vkhgaruda/sangeet_seva/sangeet_seva.dart';
import 'package:vkhgaruda/widgets/launcher_tile.dart';
import 'package:vkhgaruda/widgets/welcome.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({super.key, required this.title});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;
  bool _isAdmin = false;
  String _username = "";
  DateTime _logDate = DateTime.now();

  // lists

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    _uploadProfileSettings();
    Utils().checkForNewVersion(context, "garuda");

    _initLogger();

    refresh();
  }

  @override
  dispose() {
    // clear all lists

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    await _lock.synchronized(() async {
      _isAdmin = await Utils().isAdmin();

      // perform async operations here
      UserBasics? basic = await Utils().fetchOrGetUserBasics();
      if (basic != null) {
        setState(() {
          _username = basic.name;
        });
      }

      // fetch form values

      // refresh all child widgets

      // perform sync operations here
    });

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createUploadLogDialogContents() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Select date",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        DateHeader(
          callbacks: DateHeaderCallbacks(onChange: (date) => _logDate = date),
        ),
      ],
    );
  }

  Future<void> _initLogger() async {
    final info = await PackageInfo.fromPlatform();
    await Logger().init(info.appName);
    Logger().info(msg: "User logged in");
  }

  Future<void> _logout() async {
    await LS().delete("userbasics");
    Utils().resetUserBasics();

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return const Landing(title: "Hare Krishna");
    }));
  }

  Future<void> _publishLogs() async {
    setState(() {
      _isLoading = true;
    });

    List<LogEntry> logs = await Logger().getLogs(_logDate);
    List<Map<String, dynamic>> logsJson = logs.map((e) => e.toJson()).toList();

    UserBasics? basics = await Utils().fetchOrGetUserBasics();

    Map<String, dynamic> data = {
      'username': basics?.name ?? "Unknown",
      'date': Utils().convertTimestampToDbKey(_logDate),
      'logs': logsJson
    };

    String key = Utils().convertTimestampToDbKey(DateTime.now());
    String dbpath = "${Const().dbrootGaruda}/Logs/$key";

    if (logsJson.isNotEmpty) await FB().setJson(path: dbpath, json: data);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showPublishLogDialog() async {
    _logDate = DateTime.now();

    await Widgets().showResponsiveDialog(
        context: context,
        title: "Upload logs",
        child: _createUploadLogDialogContents(),
        actions: [
          TextButton(
              child: Text("Upload"),
              onPressed: () async {
                await _publishLogs();

                if (mounted) {
                  Navigator.of(context).pop();
                }
              })
        ]);
  }

  Future<void> _uploadProfileSettings() async {
    String? uploaded = await LS().read("userbasicsUploaded");
    if (uploaded != null && uploaded == "true") {
      return; // already uploaded
    }

    UserBasics? user = await Utils().fetchOrGetUserBasics();
    if (user != null) {
      String dbpath =
          "${Const().dbrootGaruda}/Settings/UserProfileSettings/${user.mobile}";
      await FB().setJson(path: dbpath, json: {
        'name': user.name,
      });
      await LS().write("userbasicsUploaded", "true");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeGaruda,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(title: Text(widget.title), actions: [
              // settings
              if (_isAdmin)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return const Settings(
                        title: "Settings",
                      );
                    }));
                  },
                ),

              // logout button
              if (_username.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.exit_to_app),
                  onPressed: () async {
                    Widgets().showConfirmDialog(context,
                        "Are you sure to log out?", "Log out", _logout);
                  },
                ),

              // publish logs
              IconButton(
                icon: Icon(Icons.publish),
                onPressed: () async {
                  await _showPublishLogDialog();
                },
              ),
            ]),
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

                        // your widgets here
                        //welcome message
                        Welcome(),

                        // SizedBox(height: 50),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Nitya Seva
                              LauncherTile(
                                  image:
                                      'assets/images/LauncherIcons/NityaSeva.png',
                                  title: "Nitya\nSeva",
                                  callback:
                                      LauncherTileCallback(onClick: () async {
                                    bool perm = await Utils()
                                        .checkPermission("Nitya Seva");
                                    if (perm) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const NityaSeva(
                                                    title: "Nitya Seva")),
                                      );
                                    } else {
                                      Toaster().error("Access Denied");
                                    }
                                  })),

                              // Harinaam Mantapa
                              LauncherTile(
                                  image:
                                      'assets/images/LauncherIcons/Harinaam.png',
                                  title: "Harinaam\nMantapa",
                                  callback:
                                      LauncherTileCallback(onClick: () async {
                                    bool perm = await Utils()
                                        .checkPermission("Harinaam Mantapa");
                                    if (perm) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const Harinaam(
                                                  title: "Harinaam Mantapa",
                                                  splashImage:
                                                      'assets/images/LauncherIcons/Harinaam.png',
                                                )),
                                      );
                                    } else {
                                      Toaster().error("Access Denied");
                                    }
                                  })),

                              // Sangeet Seva
                              LauncherTile(
                                  image: 'assets/images/Logo/SangeetSeva.png',
                                  title: "Sangeet\nSeva",
                                  callback:
                                      LauncherTileCallback(onClick: () async {
                                    bool perm = await Utils()
                                        .checkPermission("Sangeet Seva");
                                    if (perm) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const SangeetSeva(
                                                  title: "Sangeet Seva",
                                                  splashImage:
                                                      'assets/images/Logo/SangeetSeva.png',
                                                )),
                                      );
                                    } else {
                                      Toaster().error("Access Denied");
                                    }
                                  })),

                              // Deepotsava
                              LauncherTile(
                                  image:
                                      'assets/images/LauncherIcons/Deepotsava.png',
                                  title: "Karthika\nDeepotsava",
                                  callback:
                                      LauncherTileCallback(onClick: () async {
                                    bool perm = await Utils()
                                        .checkPermission("Karthika Deepotsava");
                                    if (perm) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => Deepotsava()),
                                      );
                                    } else {
                                      Toaster().error("Access Denied");
                                    }
                                  })),
                            ],
                          ),
                        ),
                        SizedBox(height: 100),

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
              image: "assets/images/VKHillDieties/Garuda-circular.png",
            ),
        ],
      ),
    );
  }
}
