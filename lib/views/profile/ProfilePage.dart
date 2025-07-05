import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/navigation/AppRoutes.dart';
import 'ProfileCountry.dart';
import 'ProfileCurrency.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;

  String? country;
  String? budget;
  String? currency;

  @override
  void initState() {
    super.initState();
    loadUserSettings();
  }

  Future<void> loadUserSettings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final data =
        await _supabase
            .from('usersettings')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

    if (data != null) {
      setState(() {
        country = data['preferred_country'];
        budget = data['travel_budget']?.toString();
        currency = data['preferred_currency'];
      });
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Widget buildInfoCard(String title, String? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: ListTile(
          title: Text(
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(value ?? "Not set", style: GoogleFonts.poppins()),
          trailing: const Icon(Icons.edit, color: Colors.deepPurple),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: loadUserSettings,
        child: ListView(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.purple.shade100,
              child: const Icon(
                Icons.person,
                size: 40,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),
            buildInfoCard("Preferred Country", country, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileCountryPage()),
              );
              await loadUserSettings();
            }),
            buildInfoCard("Travel Budget", budget, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileCurrencyPage()),
              );
              await loadUserSettings();
            }),
            buildInfoCard("Preferred Currency", currency, () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileCurrencyPage()),
              );
              await loadUserSettings();
            }),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
