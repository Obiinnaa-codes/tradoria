import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Represents a single trading transaction holding all relevant financial
/// data and user notes, supporting JSON serialization for local storage.
class Trade {
  final String id;
  final String symbol;
  final String type; // 'Long' or 'Short'
  final double entryPrice;
  final double exitPrice;
  final double quantity;
  final DateTime date;
  final String notes; // User-defined context/tags
  final String? imagePath; // Path to attached chart screenshot

  Trade({
    String? id,
    required this.symbol,
    required this.type,
    required this.entryPrice,
    required this.exitPrice,
    required this.quantity,
    required this.date,
    this.notes = '',
    this.imagePath,
  }) : id = id ?? const Uuid().v4();

  /// Calculates the exact dollar amount gained or lost on the trade
  double get profitLoss {
    if (type == 'Long') {
      return (exitPrice - entryPrice) * quantity;
    } else {
      return (entryPrice - exitPrice) * quantity;
    }
  }

  /// Helper boolean to quickly verify if the trade was successful
  bool get isProfit => profitLoss >= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symbol': symbol,
      'type': type,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'notes': notes,
      'imagePath': imagePath,
    };
  }

  factory Trade.fromMap(Map<String, dynamic> map) {
    return Trade(
      id: map['id'],
      symbol: map['symbol'],
      type: map['type'],
      entryPrice: (map['entryPrice'] as num).toDouble(),
      exitPrice: (map['exitPrice'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      notes: map['notes'] ?? '',
      imagePath: map['imagePath'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Trade.fromJson(String source) => Trade.fromMap(json.decode(source));
}
