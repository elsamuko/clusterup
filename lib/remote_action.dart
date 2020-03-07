typedef Filter = RemoteActionStatus Function(String stdout);

enum RemoteActionStatus { Success, Warning, Error, Unknown }

class RemoteAction {
  String name;
  String description;
  List<String> commands = [];
  Filter filter;
  RemoteAction(this.name);

  static Set<RemoteAction> allActions() {
    return Set.from([
      RemoteAction.getDiskFreeAction(),
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

      int percent = int.tryParse(match[1]);

      if (percent == null) return RemoteActionStatus.Unknown;

      if (percent < 50) return RemoteActionStatus.Success;

      if (percent < 80) return RemoteActionStatus.Warning;

      return RemoteActionStatus.Error;
    };
  }
}
