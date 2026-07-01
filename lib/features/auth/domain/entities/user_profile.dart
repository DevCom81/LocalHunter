class UserProfile {
  const UserProfile({
    required this.id,
    this.email,
    this.fullName,
    this.createdAt,
  });

  final String id;
  final String? email;
  final String? fullName;
  final DateTime? createdAt;
}
