class Expense {
  final String? id;
  final String userId;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'amount': amount,
      'category': category,
      if (description != null) 'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString(),
      userId: json['userId'].toString(),
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Expense copyWith({
    String? id,
    String? userId,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}