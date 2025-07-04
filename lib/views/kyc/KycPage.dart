import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/navigation/AppRoutes.dart';
import '../../core/services/GeographyService.dart';

class KYCPage extends StatefulWidget {
  const KYCPage({super.key});

  @override
  State<KYCPage> createState() => _KYCPageState();
}

class _KYCPageState extends State<KYCPage> {
  final _supabase = Supabase.instance.client;
  final GeographyService _geoService = GeographyService();

  String? selectedCountry;
  String? selectedCountryCode;
  String? selectedBudgetRange;
  String? selectedCurrency;
  bool _isLoading = false;

  Map<String, String> countryMap = {};
  List<Map<String, String>> currencyList = [];

  final List<String> budgetRanges = [
    "\$500 – \$1,000",
    "\$1,500 – \$3,000",
    "\$3,500 – \$5,000",
    "\$5,500 – \$10,000",
    "Custom",
  ];

  @override
  void initState() {
    super.initState();
    loadCountries();
    loadCurrencies();
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

  Future<void> loadCurrencies() async {
    try {
      final result = await _geoService.fetchCurrencies();
      setState(() {
        currencyList = result;
      });
    } catch (e) {
      debugPrint("Error fetching currencies: $e");
    }
  }

  void _showBudgetPicker() {
    Picker(
      adapter: PickerDataAdapter<String>(pickerData: budgetRanges),
      hideHeader: true,
      title: const Text("Select Budget Range"),
      selectedTextStyle: const TextStyle(color: Colors.deepPurple),
      onConfirm: (Picker picker, List<int> value) async {
        if (picker.getSelectedValues()[0] == "Custom") {
          await _showCustomBudgetDialog();
        } else {
          setState(() {
            selectedBudgetRange = picker.getSelectedValues()[0];
          });
        }
      },
    ).showDialog(context);
  }

  Future<void> _showCustomBudgetDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Enter Custom Budget"),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Amount (e.g., 2500)",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    setState(() {
                      selectedBudgetRange = controller.text;
                    });
                  }
                  Navigator.of(context).pop();
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  Future<void> _saveSettings() async {
    if (selectedCountry == null ||
        selectedBudgetRange == null ||
        selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all steps')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user found')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _supabase.from('usersettings').upsert({
        'user_id': user.id,
        'preferred_country': selectedCountry,
        'travel_budget': selectedBudgetRange,
        'preferred_currency': selectedCurrency,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedKYC', true);

      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCountryCard() {
    final sortedEntries =
        countryMap.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            'Where do you want to travel?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return DropdownButtonFormField<String>(
                value: selectedCountry,
                isExpanded: true, // ✅ fix overflow
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
                                          const SizedBox(width: 32, height: 24),
                                ),
                                const SizedBox(width: 8),
                                Text(entry.value),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    selectedCountry = value;
                    selectedCountryCode =
                        sortedEntries.firstWhere((e) => e.value == value).key;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            "You can change this later in your profile.",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            'What is your travel budget?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showBudgetPicker,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              selectedBudgetRange ?? 'Select Budget Range',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Choose your preferred currency',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedCurrency,
            isExpanded: true,
            items:
                currencyList
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency["code"],
                        child: Text(
                          "${currency["symbol"]} — ${currency["code"]}",
                        ),
                      ),
                    )
                    .toList(),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onChanged: (value) {
              setState(() {
                selectedCurrency = value;
              });
            },
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FF),
      body: SafeArea(
        child:
            countryMap.isEmpty || currencyList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Swiper(
                  itemCount: 2,
                  loop: false,
                  pagination: const SwiperPagination(),
                  control: const SwiperControl(color: Colors.deepPurple),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildCountryCard();
                    } else {
                      return _buildBudgetCard();
                    }
                  },
                ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child:
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                    'Finish & Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
        ),
      ),
    );
  }
}
