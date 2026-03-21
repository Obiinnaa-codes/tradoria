import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trade_provider.dart';
import '../theme/colors.dart';
import '../theme/layout.dart';
import '../models/trade.dart';
import '../widgets/custom_dialog.dart';

class RecentlyDeletedScreen extends StatelessWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recently Deleted',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Consumer<TradeProvider>(
          builder: (context, provider, child) {
            final deletedTrades = provider.deletedTrades;

            return SingleChildScrollView(
              child: AppLayout.constrained(
                Padding(
                  padding: AppLayout.screenPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items here will be permanently removed after 30 days (coming soon) or when you clear app data.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (deletedTrades.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 64,
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No recently deleted items',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: deletedTrades.length,
                          itemBuilder: (context, index) {
                            final trade = deletedTrades[index];
                            return _buildDeletedItem(context, trade, provider);
                          },
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeletedItem(
    BuildContext context,
    Trade trade,
    TradeProvider provider,
  ) {
    final isProfit = trade.isProfit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            ListTile(
              onTap: () => _showTradeDetails(context, trade),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Row(
                children: [
                  Text(
                    trade.symbol,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (isProfit ? AppColors.profit : AppColors.loss)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isProfit ? 'PROFIT' : 'LOSS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isProfit ? AppColors.profit : AppColors.loss,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '${trade.type} • \$${trade.profitLoss.abs().toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (trade.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        trade.notes,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.restore_rounded,
                      color: AppColors.profit,
                    ),
                    tooltip: 'Restore',
                    onPressed: () => provider.restoreTrade(trade),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.loss,
                    ),
                    tooltip: 'Delete Permanently',
                    onPressed: () =>
                        _confirmPermanentDelete(context, trade, provider),
                  ),
                ],
              ),
            ),
          ],
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

  void _confirmPermanentDelete(
    BuildContext context,
    Trade trade,
    TradeProvider provider,
  ) async {
    final confirmed = await CustomDialog.show(
      context: context,
      title: 'Delete Permanently?',
      message: 'Are you sure you want to permanently delete the ${trade.symbol} trade? This action cannot be undone.',
      confirmLabel: 'Delete Forever',
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true) {
      provider.permanentlyRemoveDeleted(trade.id);
    }
  }
}
