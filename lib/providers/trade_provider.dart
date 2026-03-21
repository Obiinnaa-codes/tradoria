import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../models/trade.dart';

/// App state manager responsible for executing read/write storage ops.
/// Allows the UI to react instantly whenever an offline trade is added.
class TradeProvider with ChangeNotifier {
  // Main in-memory cache of deserialized trade data
  List<Trade> _trades = [];

  // Tracks if storage is currently being fetched
  bool _isLoading = true;

  // Track recently deleted trades for recovery
  List<Trade> _deletedTrades = [];

  List<Trade> get trades => _trades;
  List<Trade> get deletedTrades => _deletedTrades;
  bool get isLoading => _isLoading;

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

      if (tradesJson != null) {
        _trades = tradesJson
            .map((jsonStr) {
              try {
                return Trade.fromJson(jsonStr);
              } catch (e) {
                debugPrint('Failed to parse a trade entry: $e');
                return null;
              }
            })
            .whereType<Trade>()
            .toList();
        _sanitizeTrades(); // Remove any corrupt duplicates from storage
        _trades.sort((a, b) => b.date.compareTo(a.date));
      }

      if (deletedJson != null) {
        _deletedTrades = deletedJson
            .map((jsonStr) {
              try {
                return Trade.fromJson(jsonStr);
              } catch (e) {
                return null;
              }
            })
            .whereType<Trade>()
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading trades: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appends a newly created trade to memory and persists to the device.
  Future<void> addTrade(Trade trade) {
    // Safety check: Don't add if already exists in active trades
    if (_trades.any((t) => t.id == trade.id)) return Future.value();

    _trades.insert(0, trade);
    _saveTrades();
    notifyListeners();
    return Future.value();
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
      if (_deletedTrades.length > 20)
        _deletedTrades.removeLast(); // Keep only 20
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
      _sanitizeTrades(); // Final check before writing to disk
      final prefs = await SharedPreferences.getInstance();
      final List<String> tradesJson = _trades.map((t) => t.toJson()).toList();
      final List<String> deletedJson = _deletedTrades
          .map((t) => t.toJson())
          .toList();
      await prefs.setStringList('trades', tradesJson);
      await prefs.setStringList('deleted_trades', deletedJson);
    } catch (e) {
      debugPrint('Error saving trades to local storage: $e');
    }
  }

  /// Internal helper to ensure every trade in the list has a unique ID.
  /// This prevents 'Duplicate Key' crashes in the UI.
  void _sanitizeTrades() {
    final ids = <String>{};
    _trades.retainWhere((trade) => ids.add(trade.id));

    final deletedIds = <String>{};
    _deletedTrades.retainWhere((trade) => deletedIds.add(trade.id));
  }

  Future<void> clearAllData() async {
    _trades.clear();
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
    return _trades
        .where((t) => t.symbol.toLowerCase().contains(query.toLowerCase()))
        .toList();
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
          '"${t.notes.replaceAll('\n', ' ')}"',
        );
      }

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/tradoria_export.csv';
      final file = File(path);
      await file.writeAsString(csv.toString());

      await Share.shareXFiles([
        XFile(path),
      ], text: 'My Tradoria Trade Journal Export');
    } catch (e) {
      debugPrint('Export error: $e');
    }
  }

  /// Allows user to pick a CSV file and import trades into the application.
  ///
  /// Returns:
  /// - [true] if at least one trade was successfully parsed and added.
  /// - [false] if the file was selected but no valid trades could be extracted.
  /// - [null] if the selection was aborted by the user.
  Future<bool?> importTradesFromCSV() async {
    try {
      // 1. Pick file from device storage
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Ensuring we get bytes if available
      );

      if (result == null ||
          result.files.single.path == null &&
              result.files.single.bytes == null) {
        debugPrint('CSV Import: User cancelled or selection empty.');
        return null;
      }

      String content;
      if (result.files.single.bytes != null) {
        // Prefer memory-efficient bytes if already available from picker
        content = utf8.decode(result.files.single.bytes!, allowMalformed: true);
      } else {
        // Fallback to local file path
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        content = utf8.decode(bytes, allowMalformed: true);
      }

      // 2. Initial parse to detect character content
      if (content.trim().isEmpty) {
        debugPrint('CSV Import: File is empty.');
        return false;
      }

      // TRACE: See what we are actually getting from the file
      debugPrint(
        '[DEBUG] CONTENT PREVIEW: ${content.substring(0, content.length > 100 ? 100 : content.length).replaceAll('\n', '[LF]').replaceAll('\r', '[CR]')}',
      );

      // 3. Normalize Line Endings (\r\n or \r -> \n)
      // This ensures the CSV parser doesn't treat the whole file as one row.
      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      // 4. Delimiter Auto-Detection (Check for comma, semicolon, or tab)
      String delimiter = ',';
      final cleanedLines = content
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      if (cleanedLines.isEmpty) return false;

      final firstLine = cleanedLines.first;
      if (firstLine.contains(';')) {
        delimiter = ';';
      } else if (firstLine.contains('\t'))
        delimiter = '\t';

      debugPrint(
        'CSV Import: Using delimiter "$delimiter" on ${cleanedLines.length} raw lines',
      );

      final fields = CsvToListConverter(
        fieldDelimiter: delimiter,
        eol: '\n', // We normalized to \n above
        shouldParseNumbers: true,
      ).convert(content);

      debugPrint('CSV Import Parser: Found ${fields.length} rows.');

      if (fields.isEmpty) {
        debugPrint('CSV Import: Not a valid CSV structure.');
        return false;
      }

      int importedCount = 0;
      int duplicateCount = 0;
      int skipCount = 0;

      // 4. Process data rows
      for (int i = 0; i < fields.length; i++) {
        final row = fields[i];

        // Skip headers or empty rows
        final rowString = row.toString().toLowerCase();
        if (rowString.contains('symbol') ||
            rowString.contains('date') ||
            rowString.isEmpty) {
          debugPrint('CSV Import: Skipping index $i (likely header or empty).');
          continue;
        }

        // We require at least some data. We'll be flexible on count.
        if (row.length < 2) {
          debugPrint(
            'CSV Import: Row $i skipped (only ${row.length} columns found). Content: $row',
          );
          skipCount++;
          continue;
        }

        try {
          String rawDate = row[0]?.toString().trim() ?? '';
          DateTime? parsedDate = DateTime.tryParse(rawDate);

          // Fallback parsing for common human formats (MM/DD/YYYY or DD/MM/YYYY)
          if (parsedDate == null && rawDate.contains('/')) {
            final parts = rawDate
                .split(' ')[0]
                .split('/'); // Handle "DATE TIME" string
            if (parts.length == 3) {
              int? p1 = int.tryParse(parts[0]);
              int? p2 = int.tryParse(parts[1]);
              int? p3 = int.tryParse(parts[2]);
              if (p1 != null && p2 != null && p3 != null) {
                // Try YYYY/MM/DD or MM/DD/YYYY
                if (p1 > 1000)
                  parsedDate = DateTime.tryParse(
                    '$p1-${p2.toString().padLeft(2, '0')}-${p3.toString().padLeft(2, '0')}',
                  );
                else {
                  // Assume MM/DD/YYYY
                  parsedDate = DateTime.tryParse(
                    '$p3-${p1.toString().padLeft(2, '0')}-${p2.toString().padLeft(2, '0')}',
                  );
                }
              }
            }
          }

          if (parsedDate == null) {
            debugPrint(
              'CSV Import: Row $i skipped (unsupported date format: $rawDate)',
            );
            skipCount++;
            continue;
          }

          final rawSymbol = row.length > 1
              ? row[1]?.toString() ?? 'UKN'
              : 'UKN';
          final rawType = row.length > 2
              ? row[2]?.toString() ?? 'Long'
              : 'Long';
          final rawEntry = row.length > 3 ? row[3]?.toString() ?? '0' : '0';

          final trade = Trade(
            date: parsedDate,
            symbol: rawSymbol.trim().toUpperCase(),
            type: rawType.trim().toLowerCase().contains('short')
                ? 'Short'
                : 'Long',
            entryPrice: double.tryParse(rawEntry.toString()) ?? 0.0,
            exitPrice: row.length > 4
                ? (double.tryParse(row[4].toString()) ?? 0.0)
                : 0.0,
            quantity: row.length > 5
                ? (double.tryParse(row[5].toString()) ?? 0.0)
                : 0.0,
            notes: row.length > 7 ? row[7].toString().trim() : '',
          );

          // CONTENT-BASED DEDUPLICATION:
          // We check exact timestamp and symbol to be sure it's the exact same trade.
          final isDuplicate = _trades.any(
            (t) =>
                t.symbol == trade.symbol &&
                t.date.isAtSameMomentAs(trade.date) &&
                t.entryPrice == trade.entryPrice,
          );

          if (!isDuplicate) {
            _trades.add(trade);
            importedCount++;
          } else {
            duplicateCount++;
          }
        } catch (e) {
          debugPrint('CSV Import: Error on Row $i: $e');
          skipCount++;
        }
      }

      // 5. Finalize and notify
      debugPrint(
        'CSV Import Summary: $importedCount new, $duplicateCount duplicates, $skipCount skipped.',
      );

      if (importedCount > 0) {
        _sanitizeTrades();
        _trades.sort((a, b) => b.date.compareTo(a.date));
        await _saveTrades();
        notifyListeners();
      }

      // Return true if we actually found and processed at least one valid row
      // (even if it was a duplicate), so the user knows the file was readable.
      return (importedCount > 0 || duplicateCount > 0);
    } catch (e) {
      debugPrint('CSV Import Crash: $e');
      return false;
    }
  }
}
