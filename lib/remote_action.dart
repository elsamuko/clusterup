import 'package:intl/intl.dart';

typedef Filter = RemoteActionStatus Function(String stdout);

enum RemoteActionStatus { Unknown, Success, Warning, Error }

class RemoteAction {
  String name;
  String description;
  List<String> commands = [];
  Filter filter;
  RemoteActionStatus status = RemoteActionStatus.Unknown;
  String filtered;
  RemoteAction(this.name);

  static Set<RemoteAction> allActions() {
    return Set.from([
      RemoteAction.getDiskFreeAction(),
      RemoteAction.getUptimeAction(),
    ]);
  }

  @override
  bool operator ==(dynamic other) {
    return this.name == other.name;
  }

  @override
  int get hashCode => name.hashCode;

  factory RemoteAction.getActionFor(String name) {
    switch (name) {
      case "df":
        return RemoteAction.getDiskFreeAction();
        break;
      case "uptime":
        return RemoteAction.getUptimeAction();
        break;
      default:
        return RemoteAction("");
    }
  }

  RemoteAction.getDiskFreeAction() {
    name = "df";
    description = "checks free disk space on /";
    commands.add("df /");
    filter = (stdout) {
      RegExp regExp = new RegExp("(\\d+)%");
      RegExpMatch match = regExp.firstMatch(stdout);

      if (match.groupCount != 1) return RemoteActionStatus.Unknown;

      filtered = match[1];

      int percent = int.tryParse(filtered);

      if (percent == null) {
        status = RemoteActionStatus.Unknown;
        return status;
      }

      if (percent < 50) status = RemoteActionStatus.Success;

      if (percent < 80) status = RemoteActionStatus.Warning;

      if (percent >= 80) status = RemoteActionStatus.Error;

      return status;
    };
  }
  RemoteAction.getUptimeAction() {
    name = "uptime";
    description = "checks uptime";
    commands.add("uptime -s");
    filter = (stdout) {
      DateFormat format = DateFormat("yyyy-MM-dd hh:mm:ss");
      DateTime started = format.parse(stdout);
      filtered = started.toString();
      status = RemoteActionStatus.Success;
      return status;
    };
  }
}
