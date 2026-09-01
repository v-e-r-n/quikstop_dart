class QuikstopEvent {
  final String id;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final Map<String, dynamic>? meta;

  const QuikstopEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.payload,
    this.meta,
  });

  factory QuikstopEvent.fromJson(Map<String, dynamic> json) {
    final payloadMap = json['payload'] as Map<String, dynamic>? ?? {};
    final metaMap = json['meta'] as Map<String, dynamic>?;
    return QuikstopEvent(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      payload: payloadMap,
      meta: metaMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'payload': payload,
      'meta': meta,
    };
  }
}
