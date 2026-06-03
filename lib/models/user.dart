class User {
  String name;
  bool hasCompletedOnboarding;

  User({
    required this.name,
    this.hasCompletedOnboarding = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'hasCompletedOnboarding': hasCompletedOnboarding,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json['name'],
    hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
  );
}