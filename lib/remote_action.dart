import 'package:intl/intl.dart';

typedef Filter = RemoteActionStatus Function(List<String> lines);

enum RemoteActionStatus { Unknown, Success, Warning, Error }

class RemoteAction {
  String name;
  String description;
  List<String> commands = [];
  Filter filter;
  RemoteActionStatus status = RemoteActionStatus.Unknown;
  String filtered = "";

  RemoteAction(this.name);

  void reset() {
    filtered = "";
    status = RemoteActionStatus.Unknown;
  }

  static Set<RemoteAction> allActions() {
    return Set.from([
      RemoteAction.getDiskFreeAction(),
      RemoteAction.getUptimeAction(),
      RemoteAction.getAptUpdatesAvailableAction(),
      RemoteAction.getLsbDescriptionAction(),
      RemoteAction.getUnameAction(),
    ]);
  }

  static Set<RemoteAction> getActionsFor(List<String> names) {
    Set<RemoteAction> actions = Set<RemoteAction>();
    names.forEach((String name) {
      RemoteAction action = RemoteAction.getActionFor(name);
      if (action != null) {
        actions.add(action);
      }
    });
    return actions;
  }

  @override
  bool operator ==(dynamic other) {
    return this.name == other.name;
  }

  @override
  int get hashCode => name.hashCode;

  String toJson() {
    return name;
  }

  factory RemoteAction.getActionFor(String name) {
    switch (name) {
      case "df":
        return RemoteAction.getDiskFreeAction();
        break;
      case "uptime":
        return RemoteAction.getUptimeAction();
        break;
      case "apt.updates":
        return RemoteAction.getAptUpdatesAvailableAction();
        break;
      case "lsb_release":
        return RemoteAction.getLsbDescriptionAction();
        break;
      case "uname":
        return RemoteAction.getUnameAction();
        break;
      default:
        return null;
    }
  }

  RemoteAction.getHostUpAction() {
    name = "up";
    status = RemoteActionStatus.Success;
    description = "checks if host is up";
    filter = (lines) {
      return status;
    };
  }

  RemoteAction.getDiskFreeAction() {
    name = "df";
    description = "checks free disk space on /";
    commands.add("df /");
    filter = (lines) {
      status = RemoteActionStatus.Unknown;

      // sth went wrong
      if (lines.length < 2) {
        return status;
      }

      RegExp regExp = new RegExp("(\\d+)%");
      RegExpMatch match = regExp.firstMatch(lines[1]);

      if (match == null) {
        return status;
      }

      if (match.groupCount != 1) {
        return status;
      }

      int percent = int.tryParse(match[1]);

      if (percent == null) {
        return status;
      }

      filtered = "$percent% used space";

      if (percent < 50)
        status = RemoteActionStatus.Success;
      else if (percent < 80)
        status = RemoteActionStatus.Warning;
      else if (percent >= 80) status = RemoteActionStatus.Error;

      return status;
    };
  }
  RemoteAction.getUptimeAction() {
    name = "uptime";
    description = "checks uptime";
    commands.add("uptime -s");
    filter = (lines) {
      status = RemoteActionStatus.Unknown;

      // sth went wrong
      if (lines.length < 1) return status;

      DateFormat format = DateFormat("yyyy-MM-dd hh:mm:ss");
      DateTime started = format.parse(lines[0]);
      int days = DateTime.now().difference(started).inDays;
      filtered = "$days days";

      status = RemoteActionStatus.Success;
      return status;
    };
  }
  RemoteAction.getAptUpdatesAvailableAction() {
    name = "apt.updates";
    description = "checks available updates with apt";
    commands.add("apt list --upgradeable");
    filter = (lines) {
      status = RemoteActionStatus.Success;

      // no updates available -> success
      if (lines.length < 2) return status;

      // remove "Listing... Done" message
      lines.removeAt(0);

      int security = 0;
      int other = 0;

      lines.forEach((line) {
        if (line.contains("-security "))
          security++;
        else
          other++;
      });

      filtered = "$security security updates, $other other updates";

      if (other > 0) status = RemoteActionStatus.Warning;
      if (security > 0) status = RemoteActionStatus.Error;
      if (lines.length == 0) status = RemoteActionStatus.Success;

      return status;
    };
  }
  RemoteAction.getLsbDescriptionAction() {
    name = "lsb_release";
    description = "queries distribution information";
    commands.add("lsb_release -d");
    filter = (lines) {
      status = RemoteActionStatus.Unknown;

      // must be one line
      if (lines.length != 1) return status;

      String line = lines.first;
      String search = "Description:\t";

      if (line.startsWith(search)) {
        filtered = line.substring(search.length);
        status = RemoteActionStatus.Success;
      } else {
        filtered = "Invalid description";
        status = RemoteActionStatus.Warning;
      }

      return status;
    };
  }
  RemoteAction.getUnameAction() {
    name = "uname";
    description = "queries kernel version";
    commands.add("uname -r");
    filter = (lines) {
      status = RemoteActionStatus.Unknown;

      // must be one line
      if (lines.length != 1) return status;

      filtered = lines.first;
      status = RemoteActionStatus.Success;

      return status;
    };
  }
}
