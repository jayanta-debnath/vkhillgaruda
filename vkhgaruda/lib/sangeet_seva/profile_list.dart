import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';
import 'package:vkhgaruda/sangeet_seva/record_page.dart';
import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhgaruda/sangeet_seva/datatypes.dart';

class ProfileList extends StatefulWidget {
  final String title;
  final String? icon;

  const ProfileList({super.key, required this.title, this.icon});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileListState createState() => _ProfileListState();
}

class _ProfileListState extends State<ProfileList> {
  // scalars
  final Lock _lock = Lock();
  bool _isLoading = true;

  // lists
  final List<PerformerProfile> _performers = [];

  // controllers, listeners and focus nodes

  @override
  initState() {
    super.initState();

    refresh();
  }

  @override
  dispose() {
    // clear all lists
    _performers.clear();

    // clear all controllers and focus nodes

    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _isLoading = true;
    });

    await _lock.synchronized(() async {
      // perform async operations here

      // performers
      _performers.clear();
      List<dynamic> usersRawList = await FB().getList(
        path: "${Const().dbrootSangeetSeva}/Users",
      );
      for (var userRaw in usersRawList) {
        Map<String, dynamic> userJson = Map<String, dynamic>.from(userRaw);
        PerformerProfile user = PerformerProfile.fromJson(userJson);
        _performers.add(user);
      }
    });

    setState(() {
      _isLoading = false;
    });
  }

  Widget _createPerformerCard(int index) {
    var member = _performers[index];
    return ListTile(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RecordPage(
                      title: _performers[index].name,
                      profile: _performers[index],
                    )));
      },
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: CircleAvatar(
          backgroundImage:
              (member.profilePicUrl == null || member.profilePicUrl!.isEmpty
                  ? null
                  : NetworkImage(member.profilePicUrl!)),
        ),
      ),
      title: Text("${member.salutation} ${member.name}"),
      subtitle: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 16,
                ),
                SizedBox(width: 5),
                Text(member.mobile),
              ],
            ),
            SizedBox(width: 10),
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 16,
                ),
                SizedBox(width: 5),
                Text(member.credentials),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: themeGaruda,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: [
                IconButton(
                  icon: Icon(Icons.add),
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
                )
              ],
            ),
            body: RefreshIndicator(
                onRefresh: refresh,
                child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(children: [
                          // leave some space at top
                          SizedBox(height: 10),

                          // performers list

                          // existing profiles
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _performers.length,
                            itemBuilder: (context, index) {
                              return Card(child: _createPerformerCard(index));
                            },
                          ),

                          // empty message
                          if (_performers.isEmpty)
                            Center(
                              child: Text("No profiles found"),
                            ),

                          // leave some space at bottom
                          SizedBox(height: 100),
                        ])))),
          ),

          // circular progress indicator
          if (_isLoading) LoadingOverlay(image: widget.icon)
        ],
      ),
    );
  }
}
