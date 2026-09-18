import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      _load(search: _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.getDisputes(search: search);
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

  Future<bool> _confirmTwice(String title, String message) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: AppColors.hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    if (first != true) return false;
    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Are you sure?', style: TextStyle(color: Colors.white)),
        content: const Text('This action is final and cannot be undone.', style: TextStyle(color: Colors.orangeAccent)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    return second == true;
  }

  Future<void> _resolve(Map d, String resolution) async {
    final ok = await _confirmTwice(
      resolution == 'refund_buyer' ? 'Refund the buyer?' : 'Release payment to seller?',
      resolution == 'refund_buyer'
          ? 'LKR ${d['price']} will be refunded and the listing relisted.'
          : 'LKR ${d['price']} will be released to the seller and the order completed.',
    );
    if (!ok) return;
    try {
      final id = d['id'] is int ? d['id'] : int.parse(d['id'].toString());
      await ApiService.resolveDispute(id, resolution);
      _load(search: _searchCtrl.text.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Disputes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search by mobile or email',
                prefixIcon: Icon(Icons.search, color: AppColors.hint),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                    : _items.isEmpty
                        ? const Center(child: Text('No open disputes', style: TextStyle(color: AppColors.hint)))
                        : RefreshIndicator(
                            onRefresh: () => _load(search: _searchCtrl.text.trim()),
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _items.length,
                              itemBuilder: (context, i) {
                                final d = _items[i];
                                final screenshots = (d['screenshots'] as List?) ?? [];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d['listingTitle']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text('Order #${d['orderId']} · LKR ${d['price']}', style: const TextStyle(color: AppColors.hint, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text('Buyer: ${d['buyerEmail']}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                                      Text('Seller: ${d['sellerEmail']}', style: const TextStyle(color: AppColors.hint, fontSize: 11)),
                                      const SizedBox(height: 8),
                                      Text(d['reason']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      if (screenshots.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 70,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: screenshots.length,
                                            itemBuilder: (c, si) => Padding(
                                              padding: const EdgeInsets.only(right: 6),
                                              child: GestureDetector(
                                                onTap: () => showDialog(
                                                  context: context,
                                                  builder: (_) => Dialog(backgroundColor: Colors.black, child: InteractiveViewer(child: Image.network(screenshots[si].toString()))),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(screenshots[si].toString(), width: 70, height: 70, fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: AppColors.fieldFill, child: const Icon(Icons.broken_image_outlined, color: AppColors.hint))),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _resolve(d, 'refund_buyer'),
                                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
                                              child: const Text('Refund Buyer', style: TextStyle(fontSize: 11)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => _resolve(d, 'release_seller'),
                                              child: const Text('Release Seller', style: TextStyle(fontSize: 11)),
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
          ),
        ],
      ),
    );
  }
}
