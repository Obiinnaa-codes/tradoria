import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/layout.dart';
import '../models/trade.dart';
import '../providers/trade_provider.dart';
import '../widgets/trading_heatmap.dart';
import '../widgets/custom_dialog.dart';

/// The Journal Screen organizes individual trades by day.
/// Features a heatmap calendar representation of performance across the month.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  
  // State for navigating months and selecting specific days for deeper analysis
  DateTime _viewMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search symbol...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                'Trading Journal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Consumer<TradeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_isSearching && _searchQuery.isNotEmpty) {
            final results = provider.searchTrades(_searchQuery);
            return _buildSearchResults(results);
          }

          final now = DateTime.now();
          final todayTrades = provider.trades
              .where(
                (t) =>
                    t.date.day == now.day &&
                    t.date.month == now.month &&
                    t.date.year == now.year,
              )
              .toList();

          final todayProfit = todayTrades.fold(
            0.0,
            (sum, t) => sum + t.profitLoss,
          );
          final todayWins = todayTrades.where((t) => t.isProfit).length;
          final todayWinRate = todayTrades.isEmpty
              ? 0.0
              : (todayWins / todayTrades.length) * 100;

          return SingleChildScrollView(
            child: AppLayout.constrained(
              Padding(
                padding: AppLayout.screenPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Calendar & Month Navigation ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_viewMonth),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            // Previous Month
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_left,
                                color: AppColors.textPrimary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
                                  _selectedDate = null; // Clear day selection on month change
                                });
                              },
                            ),
                            // Next Month
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_right,
                                color: AppColors.textPrimary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
                                  _selectedDate = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Interactive Heatmap: Tapping a day filters the results below
                    TradingHeatmap(
                      trades: provider.trades,
                      viewMonth: _viewMonth,
                      selectedDate: _selectedDate,
                      onDaySelected: (date) {
                        setState(() {
                          // Toggle selection: if already selected, clear it (show all)
                          if (_selectedDate != null && 
                              _selectedDate!.day == date.day && 
                              _selectedDate!.month == date.month &&
                              _selectedDate!.year == date.year) {
                            _selectedDate = null;
                          } else {
                            _selectedDate = date;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // --- Summary for Selected Period ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null 
                            ? 'Today\'s Summary' 
                            : 'Summary for ${DateFormat('MMM d').format(_selectedDate!)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_selectedDate != null)
                          TextButton(
                            onPressed: () => setState(() => _selectedDate = null),
                            child: const Text('Clear Selection', style: TextStyle(color: AppColors.accent)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceHighlight),
                      ),
                      child: Column(
                        children: [
                          _buildDaySummaryRow(
                            'P&L',
                            '${(_selectedDate == null ? todayProfit : provider.trades.where((t) => t.date.day == _selectedDate!.day && t.date.month == _selectedDate!.month && t.date.year == _selectedDate!.year).fold(0.0, (sum, t) => sum + t.profitLoss)) >= 0 ? '+' : '-'}\$${(_selectedDate == null ? todayProfit : provider.trades.where((t) => t.date.day == _selectedDate!.day && t.date.month == _selectedDate!.month && t.date.year == _selectedDate!.year).fold(0.0, (sum, t) => sum + t.profitLoss)).abs().toStringAsFixed(2)}',
                            (_selectedDate == null ? todayProfit : provider.trades.where((t) => t.date.day == _selectedDate!.day && t.date.month == _selectedDate!.month && t.date.year == _selectedDate!.year).fold(0.0, (sum, t) => sum + t.profitLoss)) >= 0 ? AppColors.profit : AppColors.loss,
                          ),
                          const Divider(color: AppColors.surfaceHighlight, height: 24),
                          _buildDaySummaryRow(
                            'Win Rate',
                            '${(_selectedDate == null ? todayWinRate : (provider.trades.where((t) => t.date.day == _selectedDate!.day && t.date.month == _selectedDate!.month && t.date.year == _selectedDate!.year).isNotEmpty ? (provider.trades.where((t) => t.date.day == _selectedDate!.day && t.date.month == _selectedDate!.month && t.date.year == _selectedDate!.year && t.isProfit).length / provider.trades.where((t) => t.date.day == _selectedDate!.day && t.date.month == _selectedDate!.month && t.date.year == _selectedDate!.year).length * 100) : 0)).toStringAsFixed(0)}%',
                            AppColors.textPrimary,
                          ),
                          const Divider(color: AppColors.surfaceHighlight, height: 24),
                          _buildDaySummaryRow(
                            'Trades',
                            (_selectedDate == null 
                                ? todayTrades.length 
                                : provider.trades.where((t) => t.date.day == _selectedDate!.day && t.date.month == _selectedDate!.month && t.date.year == _selectedDate!.year).length).toString(),
                            AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- History Section ---
                    Text(
                      _selectedDate == null ? 'All History' : 'Trades on ${DateFormat('MMM d').format(_selectedDate!)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (provider.trades.isEmpty || (_selectedDate != null && provider.trades.where((t) => t.date.day == _selectedDate!.day && t.date.month == _selectedDate!.month && t.date.year == _selectedDate!.year).isEmpty))
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No trades found for this period.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...(_selectedDate == null 
                          ? provider.trades 
                          : provider.trades.where((t) => t.date.day == _selectedDate!.day && t.date.month == _selectedDate!.month && t.date.year == _selectedDate!.year))
                        .map((trade) {
                        final isProfit = trade.isProfit;
                        final amountStr =
                            '\$${trade.profitLoss.abs().toStringAsFixed(2)}';
                        final displayAmount = isProfit
                            ? '+$amountStr'
                            : '-$amountStr';
                        return _buildTradeTile(
                          context,
                          trade,
                          displayAmount,
                          '${trade.date.day}/${trade.date.month} ${trade.date.hour}:${trade.date.minute.toString().padLeft(2, '0')}',
                          isProfit,
                        );
                      }),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(List<Trade> results) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No trades found for this symbol.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final trade = results[index];
        final isProfit = trade.isProfit;
        final amountStr = '\$${trade.profitLoss.abs().toStringAsFixed(2)}';
        final displayAmount = isProfit ? '+$amountStr' : '-$amountStr';
        return _buildTradeTile(
          context,
          trade,
          displayAmount,
          '${trade.date.day}/${trade.date.month}',
          isProfit,
        );
      },
    );
  }

  /// Helper row to build key-value pairs inside the summary container
  Widget _buildDaySummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Extracted widget for a single trade row representation
  Widget _buildTradeTile(
    BuildContext context,
    Trade trade,
    String amount,
    String time,
    bool isProfit,
  ) {
    return Dismissible(
      key: Key(trade.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.loss.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.loss),
      ),
      confirmDismiss: (direction) async {
        return await CustomDialog.show(
          context: context,
          title: 'Move to Trash?',
          message: 'Move ${trade.symbol} to the recently deleted folder?',
          confirmLabel: 'Move to Trash',
          icon: Icons.delete_sweep_rounded,
        );
      },
      onDismissed: (_) {
        Provider.of<TradeProvider>(context, listen: false).deleteTrade(trade.id);
        
        // Force clear all existing snackbars immediately
        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${trade.symbol} trade'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppColors.accent,
              onPressed: () {
                // Immediately force-remove any showing snackbars
                ScaffoldMessenger.of(context).clearSnackBars();
                Provider.of<TradeProvider>(context, listen: false).restoreTrade(trade);
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showTradeDetails(context, trade),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Vertical colored strip to clearly indicate win/loss
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isProfit ? AppColors.profit : AppColors.loss,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trade.symbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${trade.type} • $time',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (trade.notes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          trade.notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accent.withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              // Amount value indicating outcome
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isProfit ? AppColors.profit : AppColors.loss,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTradeDetails(BuildContext context, Trade trade) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetailsSheet(context, trade),
    );
  }

  Widget _buildDetailsSheet(BuildContext context, Trade trade) {
    final isProfit = trade.isProfit;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trade.symbol,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isProfit
                        ? AppColors.profit.withValues(alpha: 0.1)
                        : AppColors.loss.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trade.type.toUpperCase(),
                    style: TextStyle(
                      color: isProfit ? AppColors.profit : AppColors.loss,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${trade.date.day}/${trade.date.month}/${trade.date.year} • ${trade.date.hour}:${trade.date.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            _buildDetailRow(
              'P&L',
              '\$${trade.profitLoss.abs().toStringAsFixed(2)}',
              valueColor: isProfit ? AppColors.profit : AppColors.loss,
            ),
            const Divider(color: AppColors.surfaceHighlight, height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildDetailRow('Entry', '\$${trade.entryPrice}'),
                ),
                Expanded(child: _buildDetailRow('Exit', '\$${trade.exitPrice}')),
                Expanded(
                  child: _buildDetailRow('Qty', trade.quantity.toString()),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'WHY I TOOK THIS TRADE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceHighlight),
              ),
              child: Text(
                trade.notes.isEmpty
                    ? 'No reasoning recorded.'
                    : trade.notes,
                style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'WHAT I LEARNED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceHighlight),
              ),
              child: Text(
                trade.lessons.isEmpty
                    ? 'No lessons recorded.'
                    : trade.lessons,
                style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
              ),
            ),
            if (trade.imagePath != null) ...[
              const SizedBox(height: 32),
              const Text(
                'CHART SCREENSHOT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(trade.imagePath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}


