import 'package:clusterup/ssh_connection.dart';
import 'package:intl/intl.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/stdlib/core.dart';

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
  SSHCredentials? from;

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
  String filtercode = "";

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
      RemoteAction.getCPULoadAction(),
    ]);
  }

  static Set<RemoteAction> getActionsFor(List<String> names) {
    Set<RemoteAction> actions = Set<RemoteAction>();
    names.forEach((String name) {
      RemoteAction? action = RemoteAction.getActionFor(name);
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

  static RemoteAction? getActionFor(String name) {
    switch (name) {
      case "df":
        return RemoteAction.getDiskFreeAction();
      case "uptime":
        return RemoteAction.getUptimeAction();
      case "apt.updates":
        return RemoteAction.getAptUpdatesAvailableAction();
      case "lsb_release":
        return RemoteAction.getLsbDescriptionAction();
      case "uname":
        return RemoteAction.getUnameAction();
      case "CPU.load":
        return RemoteAction.getCPULoadAction();
      default:
        return null;
    }
  }

  RemoteAction.none()
      : name = "",
        description = "",
        filter = ((lines) {
          return RemoteActionResult.success();
        });

  RemoteAction.getHostUpAction()
      : name = "up",
        description = "checks if host is up",
        filter = ((lines) {
          String filtercode = r'''
          enum RemoteActionStatus { Unknown, Success, Warning, Error }

          List filter(List<String> lines) {
            return [RemoteActionStatus.Success.index, ""];
          }
          ''';
          List<$String> arg = lines.map($String.new).toList();
          List rv = eval(filtercode, function: 'filter', args: [arg]);
          int status = rv[0].$reified;
          String filtered = rv[1].$reified;

          return RemoteActionResult(RemoteActionStatus.values[status], filtered: filtered);
        });

  RemoteAction.getDiskFreeAction()
      : name = "df",
        description = "checks free disk space on /",
        commands = ["df /"],
        filter = ((lines) {
          // sth went wrong
          if (lines.length < 2) {
            return RemoteActionResult.unknown();
          }

          RegExp regExp = RegExp("(\\d+)%");
          RegExpMatch? match = regExp.firstMatch(lines[1]);

          if (match == null) {
            return RemoteActionResult.unknown();
          }

          if (match.groupCount != 1) {
            return RemoteActionResult.unknown();
          }

          int? percent = int.tryParse(match[1] ?? "");

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
        });

  RemoteAction.getUptimeAction()
      : name = "uptime",
        description = "checks uptime",
        commands = ["uptime -s"],
        filter = ((lines) {
          String filtercode = r'''
          enum RemoteActionStatus { Unknown, Success, Warning, Error }

          List filter(List<String> lines) {
            // sth went wrong
            if (lines.length < 1) return [RemoteActionStatus.Unknown.index, ""];

            DateTime started = DateTime.parse(lines[0]);
            DateTime now = DateTime.now();

            int days = now.difference(started).inDays;
            String filtered = "$days day${(days == 1) ? "" : "s"}";

            return [RemoteActionStatus.Success.index, filtered];
          }
          ''';
          List<$String> arg = lines.map($String.new).toList();
          List rv = eval(filtercode, function: 'filter', args: [arg]);
          int status = rv[0].$reified;
          String filtered = rv[1].$reified;

          return RemoteActionResult(RemoteActionStatus.values[status], filtered: filtered);
        });

  RemoteAction.getAptUpdatesAvailableAction()
      : name = "apt.updates",
        description = "checks available updates with apt",
        commands = ["apt list --upgradeable"],
        filter = ((lines) {
          String filtercode = r'''
          enum RemoteActionStatus { Unknown, Success, Warning, Error }

          List filter(List<String> lines) {
            // sth went wrong
            if (lines.length < 2) return [RemoteActionStatus.Success.index, "No updates available"];

            // remove "Listing... Done" message
            lines.removeAt(0);

            int security = 0;
            int other = 0;

            for (var i = 0; i < lines.length; i++) {
              if (lines[i].contains("-security "))
                security++;
              else
                other++;
            }

            String filtered =
                "$security security update${(security == 1) ? "" : "s"}, $other other update${(other == 1) ? "" : "s"}";

            if (security > 0) return [RemoteActionStatus.Error.index, filtered];
            if (other > 0) return [RemoteActionStatus.Warning.index, filtered];
            if (lines.isEmpty) return [RemoteActionStatus.Success.index, filtered];

            return [RemoteActionStatus.Unknown.index, ""];
          }
          ''';
          List<$String> arg = lines.map($String.new).toList();
          List rv = eval(filtercode, function: 'filter', args: [arg]);
          int status = rv[0].$reified;
          String filtered = rv[1].$reified;

          return RemoteActionResult(RemoteActionStatus.values[status], filtered: filtered);
        });

  RemoteAction.getLsbDescriptionAction()
      : name = "lsb_release",
        description = "queries distribution information",
        commands = ["lsb_release -d"],
        filter = ((lines) {
          String filtercode = r'''
          enum RemoteActionStatus { Unknown, Success, Warning, Error }

          List filter(List<String> lines) {
            // sth went wrong
            if (lines.length < 1) return [RemoteActionStatus.Unknown.index, ""];

            String line = lines.first;
            String search = "Description:\t";

            if (line.startsWith(search)) {
              return [RemoteActionStatus.Success.index, line.substring(search.length)];
            } else {
              return [RemoteActionStatus.Warning.index, "Invalid description"];
            }
          }
          ''';
          List<$String> arg = lines.map($String.new).toList();
          List rv = eval(filtercode, function: 'filter', args: [arg]);
          int status = rv[0].$reified;
          String filtered = rv[1].$reified;

          return RemoteActionResult(RemoteActionStatus.values[status], filtered: filtered);
        });

  RemoteAction.getUnameAction()
      : name = "uname",
        description = "queries kernel version",
        commands = ["uname -r"],
        filter = ((lines) {
          String filtercode = r'''
          enum RemoteActionStatus { Unknown, Success, Warning, Error }

          List filter(List<String> lines) {
            // must be one line
            if (lines.length != 1) return [RemoteActionStatus.Unknown.index, ""];
            return [RemoteActionStatus.Success.index, lines.first];
          }
          ''';
          List<$String> arg = lines.map($String.new).toList();
          List rv = eval(filtercode, function: 'filter', args: [arg]);
          int status = rv[0].$reified;
          String filtered = rv[1].$reified;

          return RemoteActionResult(RemoteActionStatus.values[status], filtered: filtered);
        });

  RemoteAction.getCPULoadAction()
      : name = "CPU.load",
        description = "query CPU load",
        // parse and calculate the difference between two cpu lines in /proc/stat
        // https://rosettacode.org/wiki/Linux_CPU_utilization#Dart
        commands = ["cat /proc/stat && sleep 1 && cat /proc/stat"],
        filter = ((lines) {
          List<String> cpu = lines.where((String line) => line.startsWith("cpu  ")).toList();
          List<List<int>> loads = cpu
              .map((String line) =>
                  line.substring("cpu  ".length).split(" ").map((String token) => int.tryParse(token) ?? 0).toList())
              .toList();

          // must be two lines with at least 4 tokens
          if (loads.length != 2) return RemoteActionResult.unknown();
          for (List<int> load in loads) {
            if (load.length < 4) return RemoteActionResult.unknown();
          }

          List<List<int>> idleTotals = //    [idle,     sum]
              loads.map((List<int> times) => [times[3], times.reduce((int a, int b) => a + b)]).toList();

          // must be two idles and two sums
          if (idleTotals.length != 2) return RemoteActionResult.unknown();
          for (List<int> idleTotal in idleTotals) {
            if (idleTotal.length != 2) return RemoteActionResult.unknown();
          }

          int dTotal = idleTotals[0][0] - idleTotals[1][0];
          int dLoad = idleTotals[0][1] - idleTotals[1][1];

          double percent = 100.0 * (1.0 - dTotal / dLoad);

          String filtered = "${percent.toStringAsFixed(2)}%";

          if (percent < 50.0)
            return RemoteActionResult.success(filtered);
          else if (percent < 80.0)
            return RemoteActionResult.warning(filtered);
          else if (percent >= 80.0) return RemoteActionResult.error(filtered);

          return RemoteActionResult.unknown();
        });
}
