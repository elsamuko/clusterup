import 'cluster.dart';
import 'ssh_connection.dart';

class ClusterChild {
  // persisted
  Cluster parent;
  int? id;
  String? user;
  String? host;
  String? password;
  int? port;
  bool enabled;

  // runtime only
  bool up = false; // true, if valid and reachable

  ClusterChild(this.parent,
      {this.user, this.host, this.password, this.port, this.enabled = true}) {
    id = parent.children.length;
  }

  String toString() {
    return "${id} ${user ?? parent.user}@${host ?? parent.host}:${port ?? parent.port}";
  }

  @override
  bool operator ==(dynamic other) {
    if (this.id != other.id) return false;
    if (this.user != other.user) return false;
    if (this.host != other.host) return false;
    if (this.password != other.password) return false;
    if (this.port != other.port) return false;
    return true;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      user.hashCode ^
      host.hashCode ^
      password.hashCode ^
      port.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'parent': parent.id,
      'id': id,
      'user': user,
      'host': host,
      'password': password,
      'port': port,
      'enabled': enabled ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  static ClusterChild fromMap(Cluster parent, Map<String, dynamic> data) {
    return ClusterChild(
      parent,
      user: data['user'],
      host: data['host'],
      password: data['password'],
      port: data['port'],
      enabled: (data['enabled'] ?? 1) == 1,
    );
  }

  SSHCredentials creds() {
    return SSHCredentials(user ?? parent.user, host ?? parent.host,
        password ?? parent.password, port ?? parent.port);
  }
}
