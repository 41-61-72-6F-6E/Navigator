class Remark {
  final String? text;
  final String? type;
  final String? code;
  final String? summary;
  final int? priority;
  final String? modified;

  Remark({
    this.text,
    this.type,
    this.code,
    this.summary,
    this.priority,
    this.modified,
  });

  factory Remark.fromJson(Map<String, dynamic> json) {
    return Remark(
      text: json['text'] as String?,
      type: json['type'] as String?,
      code: json['code'] as String?,
      summary: json['summary'] as String?,
      priority: json['priority'] as int?,
      modified: json['modified'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type,
      'code': code,
      'summary': summary,
      'priority': priority,
      'modified': modified,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Remark &&
        other.text == text &&
        other.type == type &&
        other.code == code &&
        other.summary == summary &&
        other.priority == priority &&
        other.modified == modified;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        type.hashCode ^
        code.hashCode ^
        summary.hashCode ^
        priority.hashCode ^
        modified.hashCode;
  }

  @override
  String toString() {
    return 'Remark{text: $text, type: $type, code: $code, summary: $summary, priority: $priority, modified: $modified}';
  }

  // Helper methods for common remark types
  bool get isHint => type == 'hint';
  bool get isWarning => type == 'warning';
  bool get isStatus => type == 'status';

  // Get display text - prefers summary over text if available
  String get displayText => summary?.isNotEmpty == true ? summary! : (text ?? '');

  // Check if this is a high priority remark (you can adjust threshold as needed)
  bool get isHighPriority => priority != null && priority! >= 500;

  // Common remark codes as getters for easy checking
  bool get isDelayRemark => code == 'text.realtime.delay';
  bool get isCancellationRemark => code == 'text.realtime.journey.cancelled';
  bool get isWifiAvailable => code == 'wifi';
  bool get hasPowerSockets => code == 'power-sockets';
  bool get requiresReservation => code == 'compulsory-reservation';
  bool get isWheelchairAccessible => code == 'RZ';
}