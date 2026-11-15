import 'package:vkhpackages/vkhpackages.dart';
import 'package:vkhgaruda/sangeet_seva/datatypes.dart';

class SSUtils {
  static final SSUtils _instance = SSUtils._internal();

  factory SSUtils() {
    return _instance;
  }

  SSUtils._internal() {
    // init
  }

  Future<PerformerProfile?> getPerformerProfile(String mobile) async {
    var userDetailsRaw = await FB().getValue(
      path: "${Const().dbrootSangeetSeva}/Users/$mobile",
    );

    if (userDetailsRaw == null || userDetailsRaw.isEmpty) {
      return null;
    }

    return Utils().convertRawToDatatype(
      userDetailsRaw,
      PerformerProfile.fromJson,
    );
  }

  Future<int> getNextUserId() async {
    Map? users = await FB().getValue(
      path: "${Const().dbrootSangeetSeva}/Users",
    );

    if (users == null) {
      return 1;
    } else {
      return users.length + 1;
    }
  }

  Future<void> setUserDetails(PerformerProfile details) async {
    if (details.mobile.isNotEmpty) {
      String dbpath = "${Const().dbrootSangeetSeva}/Users/${details.mobile}";
      await FB().setJson(path: dbpath, json: details.toJson());
    }
  }
}
