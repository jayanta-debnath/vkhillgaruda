import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:vkhgaruda/nitya_seva/laddu/datatypes.dart';
import 'package:vkhgaruda/nitya_seva/laddu/utils.dart';
import 'package:synchronized/synchronized.dart';

class Summary extends StatefulWidget {
  final Map<String, dynamic> sessionData;

  const Summary({super.key, required this.sessionData});

  @override
  State<Summary> createState() => _SummaryState();
}

// hint: templateKey.currentState!.refresh();
// ignore: non_constant_identifier_names, library_private_types_in_public_api
final GlobalKey<_SummaryState> SummaryKey = GlobalKey<_SummaryState>();

class _SummaryState extends State<Summary> {
  final _lockInit = Lock();

  // theme ticketColors
  final Color colorPrimary =
      ColorScheme.fromSeed(seedColor: const Color(0xFF3B4043)).primary;

  // ignore: non_constant_identifier_names
  int total_procured = 0;
  // ignore: non_constant_identifier_names
  int total_carry = 0;
  // ignore: non_constant_identifier_names
  int total_served = 0;

  LadduReturn? lr;

  List<String> barLabels = [];
  List<int> barValues = [];
  List<PieChartSectionData> pieSections = [];
  List<Widget> pieLegends = [];

  String sessionTitle = '';

  Future<void> _futureInit() async {
    await _lockInit.synchronized(() async {
      List<LadduStock> stocks = readLadduStocks(widget.sessionData);
      List<LadduServe> serves = readLadduServes(widget.sessionData);

      // set laddu return status
      lr = readLadduReturnStatus(widget.sessionData);

      // formulate session title for summary widget

      sessionTitle = await CalculateSessionTitle(widget.sessionData);

      total_procured = 0;
      total_carry = 0;
      for (var stock in stocks) {
        total_procured += stock.count;
        total_carry += stock.carry ?? 0;
      }

      pieSections = [];
      pieLegends = [];
      List<String> labels = [];
      List<int> values = [];

      total_served = 0;
      for (var serve in serves) {
        total_served += CalculateTotalLadduPacksServed(serve);

        // calculate pie chart values for Pushpanjali Seva
        for (var element in serve.packsPushpanjali) {
          String purpose = "Seva ${element.keys.first}";
          int count = element.values.first;
          if (count > 0) {
            if (labels.contains(purpose)) {
              int index = labels.indexOf(purpose);
              values[index] += count;
            } else {
              labels.add(purpose);
              values.add(count);
            }
          }
        }

        // calculate pie chart values for other Seva
        for (var element in serve.packsOtherSeva) {
          String purpose = element.keys.first;
          int count = element.values.first;
          if (count > 0) {
            if (labels.contains(purpose)) {
              int index = labels.indexOf(purpose);
              values[index] += count;
            } else {
              labels.add(purpose);
              values.add(count);
            }
          }
        }

        // calculate pie chart values for misc
        for (var element in serve.packsMisc) {
          String purpose = element.keys.first;
          int count = element.values.first;
          if (count > 0) {
            if (labels.contains(purpose)) {
              int index = labels.indexOf(purpose);
              values[index] += count;
            } else {
              labels.add(purpose);
              values.add(count);
            }
          }
        }
      }

      // populate bar chart data
      barLabels = labels;
      barValues = values;
      _sortBarLabelsAndValues(barLabels, barValues);

      // move the seva elements first
      pieLegends.sort((a, b) {
        String textA = ((a as Row).children[2] as Text).data ?? '';
        String textB = ((b as Row).children[2] as Text).data ?? '';
        return textB.compareTo(textA);
      });

      // sort again based on seva amount
      pieLegends.sort((a, b) {
        String textA = ((a as Row).children[2] as Text).data ?? '';
        String textB = ((b as Row).children[2] as Text).data ?? '';
        if (textA.startsWith("Seva") && textB.startsWith("Seva")) {
          int amountA = int.parse(textA.split(' ')[1]);
          int amountB = int.parse(textB.split(' ')[1]);
          return amountA.compareTo(amountB);
        } else {
          return 0;
        }
      });
    });
  }

  Future<void> refresh() async {
    await _futureInit();
    setState(() {});
  }

  void _sortBarLabelsAndValues(List<String> labels, List<int> values) {
    // Step 1: Combine labels and values into a list of tuples
    List<MapEntry<String, int>> combinedList = [];
    for (int i = 0; i < labels.length; i++) {
      combinedList.add(MapEntry(labels[i], values[i]));
    }

    // Step 2: Define the custom comparator function
    int customComparator(MapEntry<String, int> a, MapEntry<String, int> b) {
      bool aIsSeva = a.key.startsWith('Seva');
      bool bIsSeva = b.key.startsWith('Seva');

      if (aIsSeva && bIsSeva) {
        // Extract numeric part after 'Seva' and compare numerically
        int aNum = int.parse(a.key.substring(4));
        int bNum = int.parse(b.key.substring(4));
        return aNum.compareTo(bNum);
      } else if (aIsSeva) {
        return -1; // 'Seva' labels come before others
      } else if (bIsSeva) {
        return 1; // 'Seva' labels come before others
      } else {
        return a.key.compareTo(b.key); // Standard string comparison
      }
    }

    // Step 3: Sort the combined list using the custom comparator
    combinedList.sort(customComparator);

    // Step 4: Separate the sorted tuples back into barLabels and barValues
    for (int i = 0; i < combinedList.length; i++) {
      labels[i] = combinedList[i].key;
      values[i] = combinedList[i].value;
    }
  }

  void restock(int procured) {
    total_procured += procured;
    setState(() {});
  }

  Widget _getLoading(BuildContext context) {
    return Column(
      children: [
        _getSessionTitle(),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text("Total laddu packs procured = ..."),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text("Total laddu packs served = ..."),
          ),
        ),
      ],
    );
  }

  Widget _getSessionTitle() {
    return Align(
      alignment: Alignment.center,
      child: Text(
        sessionTitle,
        style: TextStyle(
          fontSize: 16.0, // Increase the font size
          fontWeight: FontWeight.bold, // Make the text bold
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _futureInit(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            // child: CircularProgressIndicator(),
            child: _getLoading(context),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Column(
            children: [
              _getSessionTitle(),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Total laddu packs procured = $total_procured"),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Carried from previous session = $total_carry"),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Total laddu packs served = $total_served"),
                ),
              ),

              // write return count if session closed
              if (lr != null && lr!.count >= 0) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Total laddu packs returned = ${lr!.count}"),
                  ),
                ),

                // calculate missing if any
                if ((total_procured + total_carry) !=
                    (total_served + lr!.count)) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Untracked laddu packs = ${(((total_procured + total_carry) - (total_served + lr!.count)))}",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],

              // padding before pie chart
              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              //   child: _getBarChart(context),
              // ),
            ],
          );
        }
      },
    );
  }
}
