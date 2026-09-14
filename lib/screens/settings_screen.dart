import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getMe();
      if (mounted) setState(() => _profile = data);
    } catch (_) {}
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _changePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    String? error;
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Change Password', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: currentCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Current password')),
              const SizedBox(height: 10),
              TextField(controller: newCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'New password')),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: submitting ? null : () async {
                setDialogState(() => submitting = true);
                try {
                  await ApiService.changePassword(currentCtrl.text, newCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
                } catch (e) {
                  setDialogState(() {
                    error = e.toString().replaceFirst('Exception: ', '');
                    submitting = false;
                  });
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _requestEmailChangeDialog() {
    final emailCtrl = TextEditingController();
    String? error;
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Request Email Change', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This requires main admin approval.', style: TextStyle(color: AppColors.hint, fontSize: 12)),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'New email address')),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: submitting ? null : () async {
                setDialogState(() => submitting = true);
                try {
                  await ApiService.requestEmailChange(emailCtrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted — pending main admin approval')));
                } catch (e) {
                  setDialogState(() {
                    error = e.toString().replaceFirst('Exception: ', '');
                    submitting = false;
                  });
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkForUpdate() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: AppColors.surface,
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 20),
            Text('Checking for updates...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
    try {
      final result = await ApiService.checkForUpdate('1.0.5');
      if (!mounted) return;
      Navigator.pop(context);
      if (result['updateAvailable'] == true) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Update Available', style: TextStyle(color: Colors.white)),
            content: Text('Version ${result['latestVersion']} is available.', style: const TextStyle(color: AppColors.hint, fontSize: 13)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Later')),
              if (result['downloadUrl'] != null)
                ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.tryParse(result['downloadUrl']);
                    if (uri != null) {
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not open download link: ${e.toString()}')),
                          );
                        }
                      }
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Download'),
                ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You're on the latest version")));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  void _reportProblemDialog() {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Report a Problem', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: msgCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Describe the issue...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report sent to main admin')));
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Profile', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 10),
                Text(_profile?['fullName'] ?? '—', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_profile?['email'] ?? '', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                const SizedBox(height: 8),
                Text('Address: ${_profile?['address'] ?? '—'}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                Text('NIC: ${_profile?['nicNumber'] ?? '—'}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text('Security', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          _tile(Icons.lock_reset, 'Change Password', null, _changePasswordDialog),
          _tile(Icons.email_outlined, 'Change Email', 'Requires main admin approval', _requestEmailChangeDialog),
          _tile(Icons.history, 'Activity Log', 'View your login history', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityLogScreen()));
          }),

          const SizedBox(height: 20),
          const Text('Preferences', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          _tile(Icons.system_update_outlined, 'Check for Update', null, _checkForUpdate),

          const SizedBox(height: 20),
          const Text('Support', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          _tile(Icons.report_gmailerrorred_outlined, 'Report a Problem', null, _reportProblemDialog),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Logout')),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String? subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.hint),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: AppColors.hint, fontSize: 11)) : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
      onTap: onTap,
    );
  }
}

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<dynamic> _logins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getActivityLog();
      if (mounted) setState(() { _logins = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Activity Log')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _logins.isEmpty
              ? const Center(child: Text('No login history', style: TextStyle(color: AppColors.hint)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _logins.length,
                  itemBuilder: (context, i) {
                    final l = _logins[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          const Icon(Icons.login, color: AppColors.hint, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l['device_model'] ?? 'Unknown device', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                Text('${l['ip_address'] ?? ''} · ${(l['created_at'] ?? '').toString().substring(0, 16)}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
