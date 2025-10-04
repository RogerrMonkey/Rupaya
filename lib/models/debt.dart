class Debt {
  final String? id;
  final String userId;
  final String personName;
  final double amount;
  final double paidAmount;
  final String direction; // 'owe' or 'owed'
  final String? description;
  final DateTime dueDate;
  final bool isSettled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Debt({
    this.id,
    required this.userId,
    required this.personName,
    required this.amount,
    this.paidAmount = 0.0,
    required this.direction,
    this.description,
    required this.dueDate,
    this.isSettled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingAmount => amount - paidAmount;
  double get progressPercentage => amount > 0 ? (paidAmount / amount) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'personName': personName,
      'amount': amount,
      'paidAmount': paidAmount,
      'direction': direction,
      if (description != null) 'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isSettled': isSettled ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id']?.toString(),
      userId: json['userId'].toString(),
      personName: json['personName'],
      amount: (json['amount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      direction: json['direction'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      isSettled: json['isSettled'] == 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Debt copyWith({
    String? id,
    String? userId,
    String? personName,
    double? amount,
    double? paidAmount,
    String? direction,
    String? description,
    DateTime? dueDate,
    bool? isSettled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Debt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      direction: direction ?? this.direction,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}