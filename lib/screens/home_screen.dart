import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/badge_model.dart';
import '../providers/app_provider.dart';
import '../widgets/badge_toast.dart';
import '../widgets/habit_form_sheet.dart';
import 'daily_screen.dart';
import 'habits_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _sheetVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowFormSheet();
  }

  void _maybeShowFormSheet() {
    final provider = context.read<AppProvider>();
    if (provider.isFormOpen && !_sheetVisible) {
      _sheetVisible = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: const HabitFormSheet(),
          ),
        );
        _sheetVisible = false;
        if (mounted) provider.closeForm();
      });
    }
  }

  static const _tabs = [
    (icon: Icons.check_circle_outline, label: 'Today'),
    (icon: Icons.list_alt_outlined, label: 'Habits'),
    (icon: Icons.bar_chart, label: 'Stats'),
    (icon: Icons.settings_outlined, label: 'Settings'),
  ];

  static const _screens = [
    DailyScreen(),
    HabitsScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // React to isFormOpen changes after each rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowFormSheet());

    final user = provider.user;
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final BadgeModel? toast = provider.unlockedBadgeToast;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.local_fire_department,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'AuraHabit',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: -0.3),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PWA',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6366F1),
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (isDesktop)
            Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = provider.activeTabIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextButton.icon(
                    onPressed: () => provider.setActiveTab(i),
                    icon: Icon(tab.icon, size: 15),
                    label: Text(tab.label),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          isActive ? const Color(0xFF6366F1) : null,
                      foregroundColor:
                          isActive ? Colors.white : Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                );
              }),
            ),
          const SizedBox(width: 8),
          if (user != null) ...[
            if (user.photoURL != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ClipOval(
                  child: Image.network(
                    user.photoURL!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(user),
                  ),
                ),
              )
            else
              Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _avatarFallback(user)),
            IconButton(
              icon: const Icon(Icons.logout, size: 18),
              tooltip: 'Sign out',
              color: Colors.grey.shade400,
              onPressed: () => _confirmSignOut(context, provider),
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: provider.activeTabIndex,
            children: _screens,
          ),
          if (toast != null)
            Positioned(
              bottom: isDesktop ? 24 : 90,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: provider.dismissBadgeToast,
                child: BadgeToast(badge: toast),
              ),
            ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: provider.activeTabIndex,
              onTap: provider.setActiveTab,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF6366F1),
              unselectedItemColor: Colors.grey.shade400,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              items: _tabs
                  .map((t) => BottomNavigationBarItem(
                        icon: Icon(t.icon),
                        label: t.label,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _avatarFallback(user) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF6366F1),
      child: Text(
        (user.displayName ?? 'A')[0].toUpperCase(),
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
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
