import 'cluster.dart';
import 'ssh_connection.dart';

class ClusterChild {
  Cluster parent;
  String user;
  String host;
  int port;
  ClusterChild(this.parent);

  String toString() {
    return "$user@$host:$port";
  }

  SSHCredentials creds() {
    return SSHCredentials(user ?? parent.user, host ?? parent.host, port ?? parent.port);
  }
}
