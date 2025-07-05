import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileCurrencyPage extends StatefulWidget {
  const ProfileCurrencyPage({super.key});

  @override
  State<ProfileCurrencyPage> createState() => _ProfileCurrencyPageState();
}

class _ProfileCurrencyPageState extends State<ProfileCurrencyPage> {
  final _supabase = Supabase.instance.client;

  String? selectedCurrency;
  final TextEditingController _budgetController = TextEditingController();

  List<String> currencyList = ["USD", "EUR", "MYR", "JPY", "SAR"];

  Future<void> updateCurrencyAndBudget() async {
    final user = _supabase.auth.currentUser;
    if (user == null ||
        selectedCurrency == null ||
        _budgetController.text.isEmpty)
      return;

    await _supabase
        .from('usersettings')
        .update({
          'preferred_currency': selectedCurrency,
          'travel_budget': _budgetController.text,
        })
        .eq('user_id', user.id);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FF),
      appBar: AppBar(title: const Text("Edit Budget & Currency")),
      body: Padding(
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
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Enter Budget Amount (e.g., 2500)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Select Currency",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items:
                    currencyList
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (value) {
                  setState(() => selectedCurrency = value);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: updateCurrencyAndBudget,
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
