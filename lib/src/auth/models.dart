class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    DateTime? parsedExpiry;
    if (json['expires_at'] != null) {
      parsedExpiry = DateTime.tryParse(json['expires_at'].toString());
    }

    return AuthTokens(
      accessToken: (json['token'] ?? json['access_token'] ?? '') as String,
      refreshToken: (json['refresh_token'] ?? '') as String,
      expiresAt: parsedExpiry,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': accessToken,
        'refresh_token': refreshToken,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };
}
