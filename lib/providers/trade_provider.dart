import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trade.dart';

/// App state manager responsible for executing read/write storage ops.
/// Allows the UI to react instantly whenever an offline trade is added.
class TradeProvider with ChangeNotifier {
  // Main in-memory cache of deserialized trade data
  List<Trade> _trades = [];

  // Tracks if storage is currently being fetched
  bool _isLoading = true;

  // Manual capital input for ROI calculation
  double _initialCapital = 0.0;

  // Track recently deleted trades for recovery
  List<Trade> _deletedTrades = [];


  List<Trade> get trades => _trades;
  List<Trade> get deletedTrades => _deletedTrades;
  bool get isLoading => _isLoading;
  double get initialCapital => _initialCapital;

  TradeProvider() {
    loadTrades(); // Trigger initialization of local storage
  }

  /// Pulls the saved list of stringified JSON trades from local device storage
  /// and updates the app state.
  Future<void> loadTrades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? tradesJson = prefs.getStringList('trades');
      final List<String>? deletedJson = prefs.getStringList('deleted_trades');
      _initialCapital = prefs.getDouble('capital') ?? 0.0;

      if (tradesJson != null) {
        _trades = tradesJson.map((jsonStr) {
          try {
            return Trade.fromJson(jsonStr);
          } catch (e) {
            debugPrint('Failed to parse a trade entry: $e');
            return null;
          }
        }).whereType<Trade>().toList();
        _trades.sort((a, b) => b.date.compareTo(a.date));
      }

      if (deletedJson != null) {
        _deletedTrades = deletedJson.map((jsonStr) {
          try {
            return Trade.fromJson(jsonStr);
          } catch (e) {
            return null;
          }
        }).whereType<Trade>().toList();
      }
    } catch (e) {
      debugPrint('Error loading trades: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appends a newly created trade to memory and persists to the device.
  Future<void> addTrade(Trade trade) async {
    _trades.add(trade);
    _trades.sort((a, b) => b.date.compareTo(a.date));
    await _saveTrades();
    notifyListeners();
  }

  /// Updates an existing trade in memory and storage.
  Future<void> updateTrade(Trade updatedTrade) async {
    final index = _trades.indexWhere((t) => t.id == updatedTrade.id);
    if (index != -1) {
      _trades[index] = updatedTrade;
      _trades.sort((a, b) => b.date.compareTo(a.date));
      await _saveTrades();
      notifyListeners();
    }
  }

  /// Removes a specific trade from memory and storage, moves it to deleted list.
  Future<void> deleteTrade(String id) async {
    final tradeIndex = _trades.indexWhere((t) => t.id == id);
    if (tradeIndex != -1) {
      final trade = _trades[tradeIndex];
      _deletedTrades.insert(0, trade);
      if (_deletedTrades.length > 20) _deletedTrades.removeLast(); // Keep only 20
      _trades.removeAt(tradeIndex);
      await _saveTrades();
      notifyListeners();
    }
  }

  /// Restores a trade from the deleted list back to active trades.
  Future<void> restoreTrade(Trade trade) async {
    _deletedTrades.removeWhere((t) => t.id == trade.id);
    _trades.add(trade);
    _trades.sort((a, b) => b.date.compareTo(a.date));
    await _saveTrades();
    notifyListeners();
  }

  /// Permanently removes a trade from the deleted list.
  Future<void> permanentlyRemoveDeleted(String id) async {
    _deletedTrades.removeWhere((t) => t.id == id);
    await _saveTrades();
    notifyListeners();
  }

  /// Internal sync helper for overriding offline lists.
  /// Added a guard to prevent overwriting disk data with empty memory state
  /// if called before the initial load completes.
  Future<void> _saveTrades() async {
    if (_isLoading) return; // Guard against overwriting during boot-up load

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> tradesJson = _trades.map((t) => t.toJson()).toList();
      final List<String> deletedJson = _deletedTrades.map((t) => t.toJson()).toList();
      await prefs.setStringList('trades', tradesJson);
      await prefs.setStringList('deleted_trades', deletedJson);
      await prefs.setDouble('capital', _initialCapital);
    } catch (e) {
      debugPrint('Error saving trades to local storage: $e');
    }
  }

  /// Updates starting capital and persists
  Future<void> setCapital(double value) async {
    _initialCapital = value;
    await _saveTrades();
    notifyListeners();
  }

  /// Wipes all logged data - irreversible
  Future<void> clearAllData() async {
    _trades.clear();
    _initialCapital = 0.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  // --- Analytical Helpers for App Wide Scopes ---

  /// Calculates the cumulative portfolio profitability
  double get totalNetProfit {
    return _trades.fold(0.0, (sum, trade) => sum + trade.profitLoss);
  }

  int get totalTrades => _trades.length;

  int get totalWins {
    return _trades.where((t) => t.isProfit).length;
  }

  /// Provides the win rate percentage (0.0 to 100.0)
  double get winRate {
    if (_trades.isEmpty) return 0.0;
    return (totalWins / totalTrades) * 100;
  }

  /// Portfolio Growth % based on initial capital
  double get roi {
    if (_initialCapital <= 0) return 0.0;
    return (totalNetProfit / _initialCapital) * 100;
  }

  /// Advanced Analytics Data Map
  Map<String, dynamic> getAdvancedStats() {
    if (_trades.isEmpty) return {};

    double bestTrade = 0;
    double worstTrade = 0;
    double totalWinsAmt = 0;
    double totalLossAmt = 0;
    int winCount = 0;
    int lossCount = 0;

    for (var trade in _trades) {
      final pl = trade.profitLoss;
      if (pl > bestTrade) bestTrade = pl;
      if (pl < worstTrade) worstTrade = pl;

      if (pl >= 0) {
        totalWinsAmt += pl;
        winCount++;
      } else {
        totalLossAmt += pl.abs();
        lossCount++;
      }
    }

    final avgWin = winCount > 0 ? (totalWinsAmt / winCount) : 0.0;
    final avgLoss = lossCount > 0 ? (totalLossAmt / lossCount) : 0.0;
    final profitFactor = totalLossAmt > 0
        ? (totalWinsAmt / totalLossAmt)
        : (totalWinsAmt > 0 ? 999.9 : 0.0);

    return {
      'bestTrade': bestTrade,
      'worstTrade': worstTrade,
      'avgWin': avgWin,
      'avgLoss': avgLoss,
      'profitFactor': profitFactor,
      'winCount': winCount,
      'lossCount': lossCount,
    };
  }

  /// Filters trades by symbol for search functionality
  List<Trade> searchTrades(String query) {
    if (query.isEmpty) return _trades;
    return _trades.where((t) => 
      t.symbol.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  /// Generates a CSV file from current trades and triggers system share sheet.
  Future<void> exportTradesToCSV() async {
    if (_trades.isEmpty) return;

    try {
      final StringBuffer csv = StringBuffer();
      // Header
      csv.writeln('Date,Symbol,Type,Entry,Exit,Quantity,P&L,Notes');

      for (var t in _trades) {
        csv.writeln(
          '${t.date.toIso8601String()},'
          '${t.symbol},'
          '${t.type},'
          '${t.entryPrice},'
          '${t.exitPrice},'
          '${t.quantity},'
          '${t.profitLoss.toStringAsFixed(2)},'
          '"${t.notes.replaceAll('\n', ' ')}"'
        );
      }

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/tradoria_export.csv';
      final file = File(path);
      await file.writeAsString(csv.toString());

      await Share.shareXFiles([XFile(path)], text: 'My Tradoria Trade Journal Export');
    } catch (e) {
      debugPrint('Export error: $e');
    }
  }
}
