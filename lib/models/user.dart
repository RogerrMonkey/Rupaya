class User {
  final String? id;
  final String name;
  final String phoneNumber;
  final String pinHash; // Encrypted PIN
  final String occupation;
  final String? city;
  final double? monthlyIncome;
  final int? incomeDay; // Day of month when income is received (1-31)
  final double? monthlyIncomeGoal; // Monthly income target/goal
  final double? savingsGoal; // Savings target amount
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    required this.name,
    required this.phoneNumber,
    required this.pinHash,
    required this.occupation,
    this.city,
    this.monthlyIncome,
    this.incomeDay,
    this.monthlyIncomeGoal,
    this.savingsGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'pinHash': pinHash,
      'occupation': occupation,
      if (city != null) 'city': city,
      if (monthlyIncome != null) 'monthlyIncome': monthlyIncome,
      if (incomeDay != null) 'incomeDay': incomeDay,
      if (monthlyIncomeGoal != null) 'monthlyIncomeGoal': monthlyIncomeGoal,
      if (savingsGoal != null) 'savingsGoal': savingsGoal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON response
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['_id']?.toString(), // Support both SQLite (id) and MongoDB (_id)
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      pinHash: json['pinHash'],
      occupation: json['occupation'],
      city: json['city'],
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble(),
      incomeDay: json['incomeDay'] as int?,
      monthlyIncomeGoal: (json['monthlyIncomeGoal'] as num?)?.toDouble(),
      savingsGoal: (json['savingsGoal'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Create a copy with updated fields
  User copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? pinHash,
    String? occupation,
    String? city,
    double? monthlyIncome,
    int? incomeDay,
    double? monthlyIncomeGoal,
    double? savingsGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pinHash: pinHash ?? this.pinHash,
      occupation: occupation ?? this.occupation,
      city: city ?? this.city,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      incomeDay: incomeDay ?? this.incomeDay,
      monthlyIncomeGoal: monthlyIncomeGoal ?? this.monthlyIncomeGoal,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
