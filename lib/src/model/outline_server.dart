
class OutlineServer {
  final String name;
  final String serverId;
  final bool metricsEnabled;
  final int createdTimestampMs;
  final String version;
  final int portForNewAccessKeys;
  final String hostnameForAccessKeys;
  String? outlineManagementApiUrl;

  OutlineServer({
    required this.name,
    required this.serverId,
    required this.metricsEnabled,
    required this.createdTimestampMs,
    required this.version,
    required this.portForNewAccessKeys,
    required this.hostnameForAccessKeys,
    required this.outlineManagementApiUrl,
  });

  factory OutlineServer.fromJson(Map<String, dynamic> json) {

    return OutlineServer(
      name: json['name'] as String,
      serverId: json['serverId'] as String,
      metricsEnabled: json['metricsEnabled'] is bool
          ? json['metricsEnabled'] as bool
          : (json['metricsEnabled'] == 1),
      createdTimestampMs: json['createdTimestampMs'] as int,
      version: json['version'] as String,
      portForNewAccessKeys: json['portForNewAccessKeys'] as int,
      hostnameForAccessKeys: json['hostnameForAccessKeys'] as String,
      outlineManagementApiUrl: json['outlineManagementApiUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'serverId': serverId,
      'metricsEnabled': metricsEnabled,
      'createdTimestampMs': createdTimestampMs,
      'version': version,
      'portForNewAccessKeys': portForNewAccessKeys,
      'hostnameForAccessKeys': hostnameForAccessKeys,
      'outlineManagementApiUrl': outlineManagementApiUrl,
    };
  }
}
