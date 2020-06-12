import 'package:intl/intl.dart';

typedef Filter = RemoteActionResult Function(List<String> lines);

enum RemoteActionStatus { Unknown, Success, Warning, Error }

class RemoteActionPair {
  RemoteAction action;
  List<RemoteActionResult> results = [];
  RemoteActionPair(this.action);
}

class RemoteActionResult {
  RemoteActionStatus status = RemoteActionStatus.Unknown;
  String filtered = "";
  String from = "";
  RemoteActionResult(this.status, {this.filtered = ""});

  bool unknown() {
    return status == RemoteActionStatus.Unknown;
  }

  bool success() {
    return status == RemoteActionStatus.Success;
  }

  bool warning() {
    return status == RemoteActionStatus.Warning;
  }

  bool error() {
    return status == RemoteActionStatus.Error;
  }

  RemoteActionResult.success([String filtered = ""]) {
    status = RemoteActionStatus.Success;
    this.filtered = filtered;
  }
  RemoteActionResult.warning([String filtered = ""]) {
    status = RemoteActionStatus.Warning;
    this.filtered = filtered;
  }
  RemoteActionResult.error([String filtered = ""]) {
    status = RemoteActionStatus.Error;
    this.filtered = filtered;
  }
  RemoteActionResult.unknown() {
    status = RemoteActionStatus.Unknown;
  }
}

class RemoteAction {
  String name;
  String description;
  List<String> commands = [];
  Filter filter;

  static String pluralS(int count) {
    return (count == 1) ? "" : "s";
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
    description = "checks if host is up";
    filter = (lines) {
      return RemoteActionResult.success();
    };
  }

  RemoteAction.getDiskFreeAction() {
    name = "df";
    description = "checks free disk space on /";
    commands.add("df /");
    filter = (lines) {
      // sth went wrong
      if (lines.length < 2) {
        return RemoteActionResult.unknown();
      }

      RegExp regExp = new RegExp("(\\d+)%");
      RegExpMatch match = regExp.firstMatch(lines[1]);

      if (match == null) {
        return RemoteActionResult.unknown();
      }

      if (match.groupCount != 1) {
        return RemoteActionResult.unknown();
      }

      int percent = int.tryParse(match[1]);

      if (percent == null) {
        return RemoteActionResult.unknown();
      }

      String filtered = "$percent% used space";

      if (percent < 50)
        return RemoteActionResult.success(filtered);
      else if (percent < 80)
        return RemoteActionResult.warning(filtered);
      else if (percent >= 80) return RemoteActionResult.error(filtered);

      return RemoteActionResult.unknown();
    };
  }
  RemoteAction.getUptimeAction() {
    name = "uptime";
    description = "checks uptime";
    commands.add("uptime -s");
    filter = (lines) {
      // sth went wrong
      if (lines.length < 1) return RemoteActionResult.unknown();

      DateFormat format = DateFormat("yyyy-MM-dd hh:mm:ss");
      DateTime started = format.parse(lines[0]);
      int days = DateTime.now().difference(started).inDays;
      String filtered = "$days day${pluralS(days)}";

      return RemoteActionResult.success(filtered);
    };
  }
  RemoteAction.getAptUpdatesAvailableAction() {
    name = "apt.updates";
    description = "checks available updates with apt";
    commands.add("apt list --upgradeable");
    filter = (lines) {
      // no updates available -> success
      if (lines.length < 2) {
        return RemoteActionResult.success("No updates available");
      }

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

      String filtered = "$security security update${pluralS(security)}, $other other update${pluralS(other)}";

      if (other > 0) return RemoteActionResult.warning(filtered);
      if (security > 0) return RemoteActionResult.error(filtered);
      if (lines.length == 0) return RemoteActionResult.success(filtered);

      return RemoteActionResult.unknown();
    };
  }
  RemoteAction.getLsbDescriptionAction() {
    name = "lsb_release";
    description = "queries distribution information";
    commands.add("lsb_release -d");
    filter = (lines) {
      // must be one line
      if (lines.length != 1) return RemoteActionResult.unknown();

      String line = lines.first;
      String search = "Description:\t";

      if (line.startsWith(search)) {
        return RemoteActionResult.success(line.substring(search.length));
      } else {
        return RemoteActionResult.warning("Invalid description");
      }
    };
  }
  RemoteAction.getUnameAction() {
    name = "uname";
    description = "queries kernel version";
    commands.add("uname -r");
    filter = (lines) {
      // must be one line
      if (lines.length != 1) return RemoteActionResult.unknown();
      return RemoteActionResult.success(lines.first);
    };
  }
}
