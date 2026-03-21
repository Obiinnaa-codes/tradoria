import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/layout.dart';
import '../widgets/stat_card.dart';
import '../models/trade.dart';
import '../providers/trade_provider.dart';
import 'trade_entry_screen.dart';
import '../widgets/custom_dialog.dart';

/// The primary landing screen of the app.
/// Provides a high-level overview of account performance and recent trades.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    // Listen to scroll events to collapse/expand the FAB
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && _isExpanded) {
        setState(() => _isExpanded = false);
      } else if (_scrollController.offset <= 50 && !_isExpanded) {
        setState(() => _isExpanded = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Displays the quick trade entry form as a Bottom Sheet.
  /// Using a Bottom Sheet keeps the user anchored to their current context.
  void _showTradeEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Allows the sheet to take up more height if needed
      backgroundColor: Colors
          .transparent, // Background handle transparency at the modal level
      builder: (context) => const TradeEntryScreen(),
    );
  }

  /// Opens a detailed view of a trade to read notes/lessons.
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
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.accent,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          TradeEntryScreen(existingTrade: trade),
                    );
                  },
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
                Expanded(
                  child: _buildDetailRow('Exit', '\$${trade.exitPrice}'),
                ),
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
                trade.notes.isEmpty ? 'No reasoning recorded.' : trade.notes,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
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
                trade.lessons.isEmpty ? 'No lessons recorded.' : trade.lessons,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<TradeProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final netProfit = provider.totalNetProfit;
            final winRate = provider.winRate;
            final totalTrades = provider.totalTrades;
            final hasTrades = totalTrades > 0;

            return SingleChildScrollView(
              controller: _scrollController,
              child: AppLayout.constrained(
                Padding(
                  padding: AppLayout.screenPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header Section ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.surfaceHighlight.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Overview',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Welcome back, trader',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // --- Performance Summary Section ---
                      const Text(
                        'Performance Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Grid layout for high-level statistics
                      GridView.count(
                        crossAxisCount: AppLayout.getResponsiveColumnCount(
                          context,
                        ),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: AppLayout.isTablet(context)
                            ? 1.8
                            : 1.3,
                        children: [
                          StatCard(
                            title: 'Net Profit',
                            value: hasTrades
                                ? '\$${netProfit.toStringAsFixed(2)}'
                                : '\$0.00',
                            valueColor: netProfit >= 0
                                ? AppColors.profit
                                : AppColors.loss,
                            icon: Icons.attach_money_rounded,
                          ),
                          StatCard(
                            title: 'Win Rate',
                            value: hasTrades
                                ? '${winRate.toStringAsFixed(1)}%'
                                : '0.0%',
                            icon: Icons.pie_chart_outline_rounded,
                          ),
                          StatCard(
                            title: 'Avg. P&L',
                            value: hasTrades
                                ? '\$${(provider.totalNetProfit / totalTrades).toStringAsFixed(2)}'
                                : '\$0.00',
                            icon: Icons.analytics_rounded,
                          ),
                          StatCard(
                            title: 'Total Trades',
                            value: totalTrades.toString(),
                            icon: Icons.sync_alt_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // --- Recent Trades Section ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Trades',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (hasTrades)
                            TextButton(
                              onPressed: () => context.go('/journal'),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Render dynamically loaded recent trades list (top 5)
                      if (!hasTrades)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'No trades yet. Tap + to begin!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...provider.trades
                            .take(4)
                            .map(
                              (trade) => _buildRecentTradeItem(context, trade),
                            ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTradeEntry(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        isExtended: _isExpanded,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Log Trade',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Helper method to create a list item for a single trade.
  /// Dynamically styles text and icons based on whether the trade was profitable.
  Widget _buildRecentTradeItem(BuildContext context, Trade trade) {
    final isProfit = trade.isProfit;
    final amountStr = '\$${trade.profitLoss.abs().toStringAsFixed(2)}';
    final displayAmount = isProfit ? '+$amountStr' : '-$amountStr';
    final dateStr =
        '${trade.date.month}/${trade.date.day} • ${trade.date.hour}:${trade.date.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(trade.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.loss.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: AppColors.loss),
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
        Provider.of<TradeProvider>(
          context,
          listen: false,
        ).deleteTrade(trade.id);

        // Force clear all existing snackbars immediately to prevent stacking or sticking
        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${trade.symbol} moved to Recently Deleted'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(
              seconds: 2,
            ), // Standard "short" duration for stability
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppColors.accent,
              onPressed: () {
                // Immediately force-remove any showing snackbars
                ScaffoldMessenger.of(context).clearSnackBars();
                Provider.of<TradeProvider>(
                  context,
                  listen: false,
                ).restoreTrade(trade);
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.surfaceHighlight.withValues(alpha: 0.3),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withValues(alpha: 0.5),
                AppColors.surface.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Row(
            children: [
              // Circular icon indicating profit or loss direction
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isProfit
                      ? AppColors.profit.withValues(alpha: 0.15)
                      : AppColors.loss.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isProfit
                      ? Icons.north_east_rounded
                      : Icons.south_west_rounded,
                  color: isProfit ? AppColors.profit : AppColors.loss,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              // Main text details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          trade.symbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (trade.notes.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.note_alt_rounded,
                            size: 12,
                            color: AppColors.accent.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trade.type} • $dateStr',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Dollar amount formatted on the far right
              Text(
                displayAmount,
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
}
