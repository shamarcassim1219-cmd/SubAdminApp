import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class VerificationsScreen extends StatefulWidget {
  const VerificationsScreen({super.key});

  @override
  State<VerificationsScreen> createState() => _VerificationsScreenState();
}

class _VerificationsScreenState extends State<VerificationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.getVerifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _decide(int userId, bool approve) async {
    try {
      await ApiService.decideVerification(userId, approve);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _report(int userId) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Report to Main Admin', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonCtrl,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Reason for reporting this verification'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()), child: const Text('Report')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await ApiService.reportVerification(userId, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported to main admin')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  void _openMedia(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: url.toLowerCase().endsWith('.mp4') || url.toLowerCase().endsWith('.mov')
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    const Text('Video file — open in browser to view', style: TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    SelectableText(url, style: const TextStyle(color: AppColors.primary, fontSize: 11)),
                  ],
                ),
              )
            : InteractiveViewer(child: Image.network(url)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Verifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _items.isEmpty
                  ? const Center(child: Text('No pending verifications', style: TextStyle(color: AppColors.hint)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final v = _items[i];
                          final images = <Map<String, String>>[
                            {'label': 'Front', 'url': v['nic_image_url'] ?? ''},
                            if ((v['back_image_url'] ?? '').toString().isNotEmpty) {'label': 'Back', 'url': v['back_image_url']},
                            if ((v['selfie_image_url'] ?? '').toString().isNotEmpty) {'label': 'Selfie', 'url': v['selfie_image_url']},
                          ];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v['email'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${v['full_name'] ?? ''}  ·  NIC: ${v['nic_number'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                Text('${v['address'] ?? ''}, ${v['district'] ?? ''}, ${v['province'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                                Text('Document: ${v['document_type'] ?? ''}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: images.map((img) {
                                    final isVideo = img['url']!.toLowerCase().endsWith('.mp4');
                                    return InkWell(
                                      onTap: () => _openMedia(img['url']!),
                                      child: Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                                        child: isVideo
                                            ? const Icon(Icons.play_circle_outline, color: AppColors.primary, size: 28)
                                            : ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(img['url']!, fit: BoxFit.cover)),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _decide(v['user_id'], false),
                                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                                        child: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _report(v['user_id']),
                                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent)),
                                        child: const Text('Report', style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _decide(v['user_id'], true),
                                        child: const Text('Approve', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
