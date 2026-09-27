/// Mô hình đại diện cho một phiên đăng nhập của thiết bị
class SessionModel {
  final String id;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final String location;
  final DateTime lastActive;
  final bool isCurrent;

  const SessionModel({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.ipAddress,
    required this.location,
    required this.lastActive,
    this.isCurrent = false,
  });

  SessionModel copyWith({
    String? id,
    String? deviceName,
    String? platform,
    String? ipAddress,
    String? location,
    DateTime? lastActive,
    bool? isCurrent,
  }) {
    return SessionModel(
      id: id ?? this.id,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      location: location ?? this.location,
      lastActive: lastActive ?? this.lastActive,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) {
        return val;
      }
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return SessionModel(
      id: (json['id'] ?? json['session_id'] ?? '') as String,
      deviceName:
          (json['device_name'] ??
                  json['deviceName'] ??
                  'Thiết bị chưa xác định')
              as String,
      platform: (json['platform'] ?? 'Ứng dụng FinCredit') as String,
      ipAddress:
          (json['ip_address'] ?? json['ipAddress'] ?? '127.0.0.1') as String,
      location: (json['location'] ?? 'Việt Nam') as String,
      lastActive: parseDate(json['last_active'] ?? json['lastActive']),
      isCurrent: (json['is_current'] ?? json['isCurrent'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_name': deviceName,
    'platform': platform,
    'ip_address': ipAddress,
    'location': location,
    'last_active': lastActive.toIso8601String(),
    'is_current': isCurrent,
  };
}
