import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileCountryPage extends StatefulWidget {
  const ProfileCountryPage({super.key});

  @override
  State<ProfileCountryPage> createState() => _ProfileCountryPageState();
}

class _ProfileCountryPageState extends State<ProfileCountryPage> {
  final _supabase = Supabase.instance.client;
  String? selectedCountry;
  String? selectedCountryCode;
  Map<String, String> countryMap = {};

  @override
  void initState() {
    super.initState();
    loadCountries();
  }

  Future<void> loadCountries() async {
    final jsonStr = await rootBundle.loadString('lib/assets/codes.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonStr);

    setState(() {
      countryMap = jsonMap.map(
        (code, name) => MapEntry(code.toLowerCase(), name as String),
      );
    });
  }

  Future<void> updateCountry() async {
    final user = _supabase.auth.currentUser;
    if (user == null || selectedCountry == null) return;

    await _supabase
        .from('usersettings')
        .update({'preferred_country': selectedCountry})
        .eq('user_id', user.id);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries =
        countryMap.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FF),
      appBar: AppBar(title: const Text("Edit Country")),
      body:
          countryMap.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade100, Colors.purple.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: "Select Country",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items:
                            sortedEntries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.value,
                                    child: Row(
                                      children: [
                                        Image.network(
                                          'https://flagcdn.com/48x36/${entry.key}.png',
                                          width: 32,
                                          height: 24,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const SizedBox(
                                                    width: 32,
                                                    height: 24,
                                                  ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(entry.value),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCountry = value;
                            selectedCountryCode =
                                sortedEntries
                                    .firstWhere((e) => e.value == value)
                                    .key;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: updateCountry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          "Save",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
