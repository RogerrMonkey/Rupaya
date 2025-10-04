class Income {
  final String? id;
  final String userId;
  final double amount;
  final String source; // e.g., "Salary", "Freelance", "Gift", etc.
  final String? fromWhom; // Person or organization
  final String? description;
  final DateTime date;
  final String type; // 'salary', 'freelance', 'business', 'gift', 'other'
  final bool isRecurring; // Whether this is a recurring income
  final String? frequency; // 'daily', 'weekly', 'monthly' - for recurring income
  final int? recurringDay; // Day for recurring income (1-31 for monthly, 1-7 for weekly)
  final DateTime createdAt;

  Income({
    this.id,
    required this.userId,
    required this.amount,
    required this.source,
    this.fromWhom,
    this.description,
    required this.date,
    required this.type,
    this.isRecurring = false,
    this.frequency,
    this.recurringDay,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'amount': amount,
      'source': source,
      if (fromWhom != null) 'fromWhom': fromWhom,
      if (description != null) 'description': description,
      'date': date.toIso8601String(),
      'type': type,
      'isRecurring': isRecurring ? 1 : 0,
      if (frequency != null) 'frequency': frequency,
      if (recurringDay != null) 'recurringDay': recurringDay,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id']?.toString(),
      userId: json['userId'].toString(),
      amount: (json['amount'] as num).toDouble(),
      source: json['source'],
      fromWhom: json['fromWhom'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      isRecurring: (json['isRecurring'] ?? 0) == 1,
      frequency: json['frequency'],
      recurringDay: json['recurringDay'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Income copyWith({
    String? id,
    String? userId,
    double? amount,
    String? source,
    String? fromWhom,
    String? description,
    DateTime? date,
    String? type,
    bool? isRecurring,
    String? frequency,
    int? recurringDay,
    DateTime? createdAt,
  }) {
    return Income(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      fromWhom: fromWhom ?? this.fromWhom,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
      recurringDay: recurringDay ?? this.recurringDay,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}