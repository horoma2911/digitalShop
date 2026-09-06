import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/stock_provider.dart';
import '../utils/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.martiamGreen),
            title: Text(l10n.language),
            subtitle: Text(localeProvider.locale?.languageCode == 'sw' ? l10n.swahili : l10n.english),
            trailing: DropdownButton<Locale>(
              value: localeProvider.locale ?? const Locale('en'),
              items: [
                DropdownMenuItem(value: const Locale('en'), child: Text(l10n.english)),
                DropdownMenuItem(value: const Locale('sw'), child: Text(l10n.swahili)),
              ],
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  localeProvider.setLocale(newLocale);
                }
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Troubleshooting',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _handleClearCache(context),
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear Local Sync Cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                  ),
                ),
                const Text(
                  'Use this if data seems stuck or not syncing correctly. App will need to be restarted.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleClearCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will wipe local temporary data and force a fresh download from the cloud. The app will close and you will need to open it again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear & Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
        try {
          await context.read<StockProvider>().clearLocalCache();
          exit(0);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing cache: $e')),
          );
        }
      }
    }
  }
}
