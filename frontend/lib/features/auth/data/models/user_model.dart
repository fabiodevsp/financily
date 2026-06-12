/// Espelha `backend/app/schemas/user.py::UserRead`.
///
/// Modelo escrito manualmente (sem freezed/json_serializable) — ver
/// "Decisões arquiteturais" da Fase 4 em docs/project_status.md:
/// build_runner não está disponível neste ambiente de desenvolvimento.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.subscriptionTier = 'free',
    this.isActive = true,
  });

  final String id;
  final String email;
  final String? name;
  final String subscriptionTier;
  final bool isActive;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        subscriptionTier: json['subscription_tier'] as String? ?? 'free',
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'subscription_tier': subscriptionTier,
        'is_active': isActive,
      };

  /// Nome de exibição: usa `name` se preenchido, senão a parte local do e-mail.
  String get displayName => (name != null && name!.trim().isNotEmpty) ? name! : email.split('@').first;
}
