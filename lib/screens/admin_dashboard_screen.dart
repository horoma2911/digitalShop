import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/shop.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminConsole),
        actions: [
          IconButton(onPressed: () => auth.logout(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchData(auth),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading admin data'));
          }

          final users = snapshot.data!['users'] as List<User>;
          final shops = snapshot.data!['shops'] as List<Shop>;
          final clientUsers = users.where((u) => u.role == UserRole.client).toList();

          return ListView.builder(
            itemCount: clientUsers.length,
            itemBuilder: (context, index) {
              final user = clientUsers[index];
              final shop = shops.firstWhere((s) => s.id == user.shopId, orElse: () => Shop(id: '', ownerId: '', name: 'N/A'));
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(user.username),
                subtitle: Text('${l10n.shopName}: ${shop.name}'),
                trailing: const Text('Client', style: TextStyle(color: Colors.blue)),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchData(AuthProvider auth) async {
    final users = await auth.getAllUsers();
    final shops = await auth.getAllShops();
    return {'users': users, 'shops': shops};
  }
}
