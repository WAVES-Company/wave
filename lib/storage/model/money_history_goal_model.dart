class MoneyHistoryEntry {
  final double amount;
  final bool isAdding;
  final DateTime date;
  final String currency;

  MoneyHistoryEntry({
    required this.amount,
    required this.isAdding,
    required this.date,
    required this.currency,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'isAdding': isAdding,
        'date': date.toIso8601String(),
        'currency': currency,
      };

  factory MoneyHistoryEntry.fromJson(Map<String, dynamic> json) =>
      MoneyHistoryEntry(
        amount: (json['amount'] as num).toDouble(),
        isAdding: json['isAdding'] as bool,
        date: DateTime.parse(json['date'] as String),
        currency: json['currency'] as String,
      );
}

// this code was written by maksy