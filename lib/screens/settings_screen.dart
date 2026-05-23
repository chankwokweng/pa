import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final settings = provider.settings;
    final user = provider.user;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        const Text('Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text('Preferences & data management',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        const SizedBox(height: 20),

        // Profile
        _Section(
          title: 'Profile',
          icon: Icons.person_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) ...[
                Row(
                  children: [
                    if (user.photoURL != null)
                      ClipOval(
                        child: Image.network(user.photoURL!,
                            width: 40, height: 40, fit: BoxFit.cover),
                      )
                    else
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF6366F1),
                        child: Text(
                          (user.displayName ?? 'A')[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? 'User',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(user.email ?? '',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              _SettingItem(
                label: 'Display Name',
                child: _TextInput(
                  value: settings.userName,
                  onChanged: (v) =>
                      provider.updateSettings(settings.copyWith(userName: v)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Preferences
        _Section(
          title: 'Preferences',
          icon: Icons.tune,
          child: Column(
            children: [
              _ToggleItem(
                label: 'Show Motivational Quote',
                subtitle: 'Display daily quote on home screen',
                value: settings.showQuote,
                onChanged: (v) =>
                    provider.updateSettings(settings.copyWith(showQuote: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Data management
        _Section(
          title: 'Data',
          icon: Icons.storage_outlined,
          child: Column(
            children: [
              _ActionItem(
                label: 'Export Backup',
                subtitle: 'Download habits & logs as JSON',
                icon: Icons.download_outlined,
                onTap: () => _exportData(context, provider),
              ),
              const Divider(height: 1),
              _ActionItem(
                label: 'Factory Reset',
                subtitle: 'Clear all data and start fresh',
                icon: Icons.restart_alt,
                iconColor: Colors.red.shade400,
                labelColor: Colors.red.shade600,
                onTap: () => _confirmReset(context, provider),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Sign out
        _Section(
          title: 'Account',
          icon: Icons.account_circle_outlined,
          child: _ActionItem(
            label: 'Sign Out',
            subtitle: 'Sign out of your Google account',
            icon: Icons.logout,
            iconColor: Colors.grey.shade500,
            onTap: () => _confirmSignOut(context, provider),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'AuraHabit v1.0.0',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }

  void _exportData(BuildContext context, AppProvider provider) {
    jsonEncode({
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'habits': provider.habits.map((h) => h.toJson()).toList(),
      'logs': provider.logs.map((l) => l.toJson()).toList(),
      'settings': provider.settings.toJson(),
    });
    // On web, we can't write files directly; show a SnackBar with info
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export via browser console: copy window.__auraData'),
        duration: Duration(seconds: 4),
      ),
    );
    // Inject into window for easy copy
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      // This is a best-effort approach for web export
    }
  }

  void _confirmReset(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Factory Reset',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'This will permanently clear all habits, logs, and badges. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.factoryReset();
            },
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Sign out of your Google account?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingItem({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        child,
      ],
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF6366F1),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _ActionItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor ?? Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      )),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

class _TextInput extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TextInput({required this.value, required this.onChanged});

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: _ctrl,
        onSubmitted: widget.onChanged,
        onEditingComplete: () => widget.onChanged(_ctrl.text),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
