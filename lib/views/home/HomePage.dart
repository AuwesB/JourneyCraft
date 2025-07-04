import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/widgets/BottomNavBar.dart';
import '../../core/navigation/AppRoutes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _pageController = PageController();
  final _supabase = Supabase.instance.client;

  String? preferredCountry;
  String? countryCode;
  Map<String, String> countryMap = {};

  @override
  void initState() {
    super.initState();
    loadCountries();
    fetchUserSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  Future<void> fetchUserSettings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final data =
        await _supabase
            .from('usersettings')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

    if (data != null && data['preferred_country'] != null) {
      setState(() {
        preferredCountry = data['preferred_country'];
        final entry = countryMap.entries.firstWhere(
          (e) => e.value == preferredCountry,
          orElse: () => MapEntry('', ''),
        );
        countryCode = entry.key;
      });
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Widget buildTopCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (countryCode != null && countryCode!.isNotEmpty)
                  Image.network(
                    'https://flagcdn.com/w640/${countryCode!}.png',
                    fit: BoxFit.fill,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color: Colors.purple.shade100,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.flag,
                            size: 60,
                            color: Colors.white70,
                          ),
                        ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                  ),
                ),
                if (preferredCountry != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            preferredCountry!,
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your gateway to unforgettable journeys!',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black45,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildTabItem('Latest', 0),
          buildTabItem('Weather', 1),
          buildTabItem('Cities', 2),
        ],
      ),
    );
  }

  Widget buildTabItem(String text, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.purple : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget buildContentList() {
    return Expanded(
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          buildContentSection('Latest News & Advisories'),
          buildContentSection('Weather & Geopolitics'),
          buildContentSection('Popular Cities & Festivals'),
        ],
      ),
    );
  }

  Widget buildContentSection(String title) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image, color: Colors.purple, size: 30),
            ),
            title: Text(
              '$title Item ${index + 1}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Tap to explore', style: GoogleFonts.poppins()),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () {},
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _logout,
          ),
        ],
      ),
      body:
          preferredCountry == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [buildTopCard(), buildTabs(), buildContentList()],
              ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          } else if (index == 1) {
            // Chat route coming soon
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, AppRoutes.map);
          } else if (index == 3) {
            // Itinerary route coming soon
          } else if (index == 4) {
            // Profile route coming soon
          }
        },
      ),
    );
  }
}
