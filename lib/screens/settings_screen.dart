import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/layout.dart';
import '../providers/trade_provider.dart';
import '../widgets/custom_dialog.dart';

/// Manage offline data, capital, and app resets.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'App Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<TradeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: AppLayout.constrained(
              Padding(
                padding: AppLayout.screenPadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('DATA MANAGEMENT'),
                    _buildSettingsCard([
                      _buildActionTile(
                        icon: Icons.delete_sweep_rounded,
                        title: 'Recently Deleted',
                        subtitle: 'Restore deleted trades and notes',
                        trailing: provider.deletedTrades.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${provider.deletedTrades.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textSecondary),
                        onTap: () => context.push('/settings/deleted'),
                      ),
                      _buildActionTile(
                        icon: Icons.file_download_outlined,
                        title: 'Export Trades (CSV)',
                        subtitle: 'Save a backup to your device',
                        onTap: () {
                          if (provider.trades.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No trades to export.')),
                            );
                            return;
                          }
                          provider.exportTradesToCSV();
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.file_upload_outlined,
                        title: 'Import Trades (CSV)',
                        subtitle: 'Load trades from a backup file',
                        onTap: () async {
                          final result = await provider.importTradesFromCSV();
                          
                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                          
                          if (result == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Trades imported successfully!'),
                                backgroundColor: AppColors.profit,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else if (result == false) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Import failed: Check file format.'),
                                backgroundColor: AppColors.loss,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          // Do nothing if result is null (user cancelled)
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.delete_forever_outlined,
                        title: 'Wipe All Data',
                        subtitle: 'Irreversibly clear all trades',
                        textColor: AppColors.loss,
                        onTap: () => _confirmWipe(context, provider),
                      ),
                    ]),
                    const SizedBox(height: 32),
                    _buildSectionTitle('ABOUT'),
                    _buildSettingsCard([
                      const ListTile(
                        title: Text('Version',
                            style: TextStyle(color: AppColors.textPrimary)),
                        trailing: Text('1.0.0',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ]),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.textPrimary),
      title: Text(title, style: TextStyle(color: textColor ?? AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: trailing,
      onTap: onTap,
    );
  }


  void _confirmWipe(BuildContext context, TradeProvider provider) async {
    final confirmed = await CustomDialog.show(
      context: context,
      title: 'Wipe All Data?',
      message: 'This will irreversibly delete all your trades and reset your journal. Are you absolutely sure?',
      confirmLabel: 'Wipe Everything',
      icon: Icons.warning_amber_rounded,
    );

    if (confirmed == true) {
      await provider.clearAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data smeared into the void.'),
            backgroundColor: AppColors.surfaceHighlight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
