import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _capturingLocation = false;
  String? _error;
  Position? _position;

  Future<void> _captureLocation() async {
    setState(() => _capturingLocation = true);
    try {
      final pos = await DeviceService.getLocation();
      if (!mounted) return;
      setState(() => _position = pos);
      if (pos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location — please enable location services and grant permission')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_position == null) {
      setState(() => _error = 'Please capture your live location before submitting');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        fullName: _fullNameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        nicNumber: _nicCtrl.text.trim(),
        gpsLat: _position!.latitude,
        gpsLng: _position!.longitude,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Request Submitted', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Your sub-admin access request has been submitted. You will be able to log in once the main admin approves your account.',
            style: TextStyle(color: AppColors.hint),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Request Sub-Admin Access')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Provide your real identity details. The main admin will review and approve your request.',
                        style: TextStyle(fontSize: 12, color: AppColors.hint),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _fullNameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nicCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'NIC Number'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.hint, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),

              const SizedBox(height: 20),
              InkWell(
                onTap: _capturingLocation ? null : _captureLocation,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _position != null ? Colors.greenAccent.withOpacity(0.1) : AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _position != null ? Colors.greenAccent.withOpacity(0.5) : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _position != null ? Icons.check_circle : Icons.location_on_outlined,
                        color: _position != null ? Colors.greenAccent : AppColors.hint,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _capturingLocation
                              ? 'Getting your location...'
                              : _position != null
                                  ? 'Location captured (${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)})'
                                  : 'Tap to capture your live location',
                          style: TextStyle(color: _position != null ? Colors.greenAccent : AppColors.hint, fontSize: 12),
                        ),
                      ),
                      if (_capturingLocation)
                        const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
