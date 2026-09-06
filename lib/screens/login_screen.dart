import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_config.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shopNameController = TextEditingController();
  bool _isLogin = true;
  bool _isTestingConnection = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    
    // Check for internet before registration
    if (!_isLogin) {
      try {
        final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw const SocketException("No internet");
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration requires internet. Please connect and try again.'), backgroundColor: Colors.orange),
          );
        }
        return;
      }
    }

    String? error;
    if (_isLogin) {
      error = await auth.login(_usernameController.text, _passwordController.text);
    } else {
      error = await auth.register(
        _usernameController.text,
        _passwordController.text,
        _shopNameController.text,
      );
    }

    if (!mounted) return;

    if (error == null) {
      if (!_isLogin) {
        setState(() => _isLogin = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.'), backgroundColor: AppColors.martiamGreen),
        );
      } else if (auth.isOfflineMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in Offline Mode (Cached Credentials)'), backgroundColor: Colors.orange),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _testConnection() async {
    setState(() => _isTestingConnection = true);
    String result = "";
    
    try {
      // 1. Test general internet using a domain
      final list = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 5));
      if (list.isNotEmpty && list[0].rawAddress.isNotEmpty) {
        result += "✅ Internet: OK\n";
      }
    } catch (e) {
      result += "❌ Internet: Failed (${e.toString()})\n";
    }

    try {
      // 2. Test Backend API Health
      final health = await http.get(Uri.parse('$API_BASE_URL/health'));
      if (health.statusCode == 200) {
        result += "✅ Backend API: Handshake Success";
      } else {
        result += "❌ Backend API: Unhealthy (status ${health.statusCode})";
      }
    } catch (e) {
      result += "❌ Backend API: Failed\n${e.toString()}";
    }

    if (!mounted) return;
    setState(() => _isTestingConnection = false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Connectivity Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(result),
            const Divider(),
            const Text(
              'Still having issues?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All local data cleared. Restart the app.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 30),
              ),
              child: const Text('CLEAR ALL LOCAL DATA'),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 250, // Reduced height to fit diagnostics
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.martiamGreen,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    l10n.appName.toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _isLogin ? l10n.welcomeBack : l10n.createShop,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(labelText: l10n.username, prefixIcon: const Icon(Icons.person)),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter username';
                        if (value.length < 3) return 'Username too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: l10n.password, prefixIcon: const Icon(Icons.lock)),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter password';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _shopNameController,
                        decoration: InputDecoration(labelText: l10n.shopName, prefixIcon: const Icon(Icons.business)),
                        validator: (value) {
                          if (!_isLogin && (value == null || value.isEmpty)) return 'Please enter shop name';
                          if (!_isLogin && value!.length < 3) return 'Shop name too short';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isLogin ? l10n.login.toUpperCase() : l10n.register.toUpperCase()),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin ? "Don't have an account? Register Now" : "Already have an account? Login",
                        style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Divider(),
                    TextButton.icon(
                      onPressed: _isTestingConnection ? null : _testConnection,
                      icon: _isTestingConnection 
                        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.network_check, size: 18),
                      label: Text(_isTestingConnection ? "Testing..." : "Test Connection Diagnostics", 
                        style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
