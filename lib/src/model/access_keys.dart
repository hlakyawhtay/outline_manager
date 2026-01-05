class AccessKey {
  final String id;
  final String outlineId;
  final String name;
  final String password;
  final int port;
  final String method;
  final DataLimit? dataLimit;
  final String accessUrl;
  final DateTime? expiredDate;
  final int? bytesTransferred;
  final String? serverId;
  final String? note;

  AccessKey({
    String? id,
    required this.outlineId,
    required this.name,
    required this.password,
    required this.port,
    required this.method,
    this.dataLimit,
    required this.accessUrl,
    this.expiredDate,
    this.bytesTransferred,
    required this.serverId,
    this.note,
  }) : id = id ?? _scopedId(serverId, outlineId);

  factory AccessKey.fromJson(Map<String, dynamic> json) {
    final outlineId = json['outlineId'] as String? ?? json['id'] as String;
    return AccessKey(
      id: json['id'] as String?,
      outlineId: outlineId,
      name: json['name'] as String,
      password: json['password'] as String,
      port: json['port'] as int,
      method: json['method'] as String,
      dataLimit: json['dataLimit'] != null
          ? DataLimit.fromJson(json['dataLimit'])
          : null,
      accessUrl: json['accessUrl'] as String,
      expiredDate: json['expiredDate'] != null
          ? DateTime.tryParse(json['expiredDate'])
          : null,
      bytesTransferred: json['bytesTransferred'] as int?,
      serverId: json['serverId'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'outlineId': outlineId,
      'name': name,
      'password': password,
      'port': port,
      'method': method,
      'dataLimit': dataLimit?.toJson(),
      'accessUrl': accessUrl,
      'expiredDate': expiredDate?.toIso8601String(),
      'bytesTransferred': bytesTransferred,
      'serverId': serverId,
      'note': note,
    };
  }

  AccessKey copyWith({
    String? id,
    String? name,
    String? password,
    int? port,
    String? method,
    DataLimit? dataLimit,
    String? accessUrl,
    DateTime? expiredDate,
    int? bytesTransferred,
    String? serverId,
    bool noteProvided = false,
    String? note,
  }) {
    final nextServerId = serverId ?? this.serverId;
    final nextId =
        id ??
        (nextServerId == this.serverId
            ? this.id
            : _scopedId(nextServerId, outlineId));
    return AccessKey(
      id: nextId,
      outlineId: outlineId,
      name: name ?? this.name,
      password: password ?? this.password,
      port: port ?? this.port,
      method: method ?? this.method,
      dataLimit: dataLimit ?? this.dataLimit,
      accessUrl: accessUrl ?? this.accessUrl,
      expiredDate: expiredDate ?? this.expiredDate,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      serverId: nextServerId,
      note: noteProvided ? note : this.note,
    );
  }

  static String _scopedId(String? serverId, String outlineId) {
    if (serverId == null || serverId.isEmpty) {
      return outlineId;
    }
    return '${serverId}_$outlineId';
  }
}

class DataLimit {
  final int bytes;

  DataLimit({required this.bytes});

  factory DataLimit.fromJson(Map<String, dynamic> json) {
    return DataLimit(bytes: json['bytes'] as int);
  }

  Map<String, dynamic> toJson() {
    return {'bytes': bytes};
  }

  double get gb => bytesToGb(bytes);

  static double bytesToGb(int bytes) {
    return bytes / (1024 * 1024 * 1024);
  }
}
