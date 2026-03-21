import 'package:flutter_test/flutter_test.dart';
import 'package:tradoria/models/trade.dart';

void main() {
  test('Trade model should serialize and deserialize imagePath correctly', () {
    final trade = Trade(
      symbol: 'TSLA',
      type: 'Long',
      entryPrice: 100.0,
      exitPrice: 110.0,
      quantity: 10.0,
      date: DateTime.now(),
      notes: 'Testing images',
      imagePath: '/path/to/image.png',
    );

    final json = trade.toJson();
    final decodedTrade = Trade.fromJson(json);

    expect(decodedTrade.symbol, equals('TSLA'));
    expect(decodedTrade.imagePath, equals('/path/to/image.png'));
    expect(decodedTrade.notes, equals('Testing images'));
    expect(decodedTrade.profitLoss, equals(100.0));
  });

  test('Trade model should handle null imagePath', () {
    final trade = Trade(
      symbol: 'AAPL',
      type: 'Short',
      entryPrice: 150.0,
      exitPrice: 140.0,
      quantity: 5.0,
      date: DateTime.now(),
    );

    final json = trade.toJson();
    final decodedTrade = Trade.fromJson(json);

    expect(decodedTrade.symbol, equals('AAPL'));
    expect(decodedTrade.imagePath, isNull);
  });
}
