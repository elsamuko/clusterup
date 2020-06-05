import 'cluster.dart';
import 'ssh_connection.dart';

class ClusterChild {
  Cluster parent;
  int id;
  String user;
  String host;
  int port;
  ClusterChild(this.parent, {this.user, this.host, this.port}) {
    id = parent.children.length;
  }

  String toString() {
    return "$user@$host:$port";
  }

  @override
  bool operator ==(dynamic other) {
    if (this.id != other.id) return false;
    if (this.user != other.user) return false;
    if (this.host != other.host) return false;
    if (this.port != other.port) return false;
    return true;
  }

  @override
  int get hashCode => id.hashCode ^ user.hashCode ^ host.hashCode ^ port.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'parent': parent.id,
      'id': id,
      'user': user,
      'host': host,
      'port': port,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  static ClusterChild fromMap(Cluster parent, Map<String, dynamic> data) {
    return ClusterChild(
      parent,
      user: data['user'],
      host: data['host'],
      port: data['port'],
    );
  }

  SSHCredentials creds() {
    return SSHCredentials(user ?? parent.user, host ?? parent.host, port ?? parent.port);
  }
}
