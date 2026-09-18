import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'verifications_screen.dart';
import 'orders_screen.dart';
import 'disputes_screen.dart';
import 'support_screen.dart';
import 'content_reports_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  String? _earning;
  bool _loadingPerms = true;
  List<String>? _permissions;

  final List<Map<String, dynamic>> _allSections = [
    {'key': 'verification', 'label': 'Verifications', 'icon': Icons.verified_outlined, 'selectedIcon': Icons.verified, 'page': const VerificationsScreen()},
    {'key': 'orders', 'label': 'Orders', 'icon': Icons.receipt_long_outlined, 'selectedIcon': Icons.receipt_long, 'page': const OrdersScreen()},
    {'key': 'disputes', 'label': 'Disputes', 'icon': Icons.gavel_outlined, 'selectedIcon': Icons.gavel, 'page': const DisputesScreen()},
    {'key': 'support', 'label': 'Support', 'icon': Icons.support_agent_outlined, 'selectedIcon': Icons.support_agent, 'page': const SupportScreen()},
  ];

  List<Map<String, dynamic>> _visibleSections = [];

  final Map<String, dynamic> _reportsSection = {
    'key': 'reports', 'label': 'Reports', 'icon': Icons.flag_outlined, 'selectedIcon': Icons.flag, 'page': const ContentReportsScreen()
  };

  @override
  void initState() {
    super.initState();
    _loadEarnings();
    _loadPermissions();
  }

  Future<void> _loadEarnings() async {
    try {
      final earning = await ApiService.getEarnings();
      if (mounted) setState(() => _earning = earning);
    } catch (_) {}
  }

  Future<void> _loadPermissions() async {
    try {
      final me = await ApiService.getMe();
      final perms = me['permissions'];
      setState(() {
        _permissions = perms == null ? null : List<String>.from(perms);
        _visibleSections = [
          ...(_permissions == null ? _allSections : _allSections.where((s) => _permissions!.contains(s['key']))),
          _reportsSection,
        ];
        _loadingPerms = false;
      });
    } catch (_) {
      setState(() {
        _visibleSections = [..._allSections, _reportsSection];
        _loadingPerms = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPerms) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_visibleSections.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.hint, size: 48),
                  const SizedBox(height: 16),
                  const Text('No sections assigned yet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Contact the main admin to get access.', style: TextStyle(color: AppColors.hint, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    child: const Text('Settings'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final tab = _tab < _visibleSections.length ? _tab : 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          if (tab == 0 && _visibleSections[0]['key'] == 'verification')
            SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings_outlined, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Earning', style: TextStyle(color: AppColors.hint, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            _earning != null ? 'LKR $_earning' : '—',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: _visibleSections[tab]['page']),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          if (i == _visibleSections.length) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          } else {
            setState(() => _tab = i);
          }
        },
        destinations: [
          ..._visibleSections.map((s) => NavigationDestination(
                icon: Icon(s['icon']),
                selectedIcon: Icon(s['selectedIcon']),
                label: s['label'],
              )),
          const NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
