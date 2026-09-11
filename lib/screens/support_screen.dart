import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
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
      final items = await ApiService.getSupportRequests();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Support')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _items.isEmpty
                  ? const Center(child: Text('No open support requests', style: TextStyle(color: AppColors.hint)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final r = _items[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              title: Text(r['subject'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(r['userEmail'] ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                                  const SizedBox(height: 2),
                                  Text(r['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                  if (r['escalated'] == true) ...[
                                    const SizedBox(height: 4),
                                    const Text('Escalated to main admin', style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => SupportDetailScreen(request: r)));
                                _load();
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class SupportDetailScreen extends StatefulWidget {
  final Map request;
  const SupportDetailScreen({super.key, required this.request});

  @override
  State<SupportDetailScreen> createState() => _SupportDetailScreenState();
}

class _SupportDetailScreenState extends State<SupportDetailScreen> {
  List<dynamic> _messages = [];
  Map<String, dynamic>? _original;
  bool _loading = true;
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getSupportMessages(widget.request['id']);
      if (!mounted) return;
      setState(() {
        _original = data['original'];
        _messages = data['messages'];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService.sendSupportReply(widget.request['id'], _replyCtrl.text.trim());
      _replyCtrl.clear();
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _escalate() async {
    try {
      await ApiService.escalateSupportRequest(widget.request['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escalated to main admin')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _close() async {
    try {
      await ApiService.closeSupportRequest(widget.request['id']);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.request['subject'] ?? ''),
        actions: [
          IconButton(icon: const Icon(Icons.priority_high), tooltip: 'Escalate to main admin', onPressed: _escalate),
          IconButton(icon: const Icon(Icons.check_circle_outline), tooltip: 'Close request', onPressed: _close),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.request['userEmail'] ?? '', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(_original?['message'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const Divider(color: AppColors.border, height: 1),
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(child: Text('No replies yet', style: TextStyle(color: AppColors.hint, fontSize: 12)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            final isAdmin = m['isAdmin'] == true;
                            return Align(
                              alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: isAdmin ? AppColors.primary : AppColors.fieldFill,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(m['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                            );
                          },
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(hintText: 'Type a reply...'),
                          ),
                        ),
                        IconButton(
                          icon: _sending
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, color: AppColors.primary),
                          onPressed: _sending ? null : _sendReply,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
