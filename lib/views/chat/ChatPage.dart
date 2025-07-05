import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/navigation/AppRoutes.dart';
import '../../core/widgets/BottomNavBar.dart';
import '../../core/widgets/TypingDots.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();

  String? preferredCountry;
  String? travelBudget;
  String? preferredCurrency;
  String? currentThreadId;

  List<Map<String, dynamic>> messages = [];
  bool _isLoading = false;

  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    fetchUserSettings();
    loadChatHistory();
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

    if (data != null && mounted) {
      setState(() {
        preferredCountry = data['preferred_country']?.toString();
        travelBudget = data['travel_budget']?.toString();
        preferredCurrency = data['preferred_currency']?.toString();
      });
    }
  }

  Future<void> loadChatHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final threads = await _supabase
        .from('chat_messages')
        .select('thread_id')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1);

    if (threads.isNotEmpty && threads.first['thread_id'] != null) {
      currentThreadId = threads.first['thread_id'] as String;

      final data = await _supabase
          .from('chat_messages')
          .select()
          .eq('user_id', user.id)
          .eq('thread_id', currentThreadId!)
          .order('created_at', ascending: true);

      setState(() {
        messages = List<Map<String, dynamic>>.from(data);
      });
    } else {
      final newThreadResp = await _supabase.rpc('gen_random_uuid').single();
      setState(() {
        currentThreadId = newThreadResp['gen_random_uuid'].toString();
      });
    }
  }

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final userMessage = _controller.text.trim();

    setState(() {
      messages.add({'role': 'user', 'content': userMessage});
      _controller.clear();
      _isLoading = true;
    });

    await saveMessageToDB(user.id, 'user', userMessage);

    final contextMessages =
        messages
            .map(
              (msg) => {
                "role": msg['role'].toString(),
                "content": msg['content'].toString(),
              },
            )
            .toList();

    String newsResults = "";
    String webResults = "";

    if (userMessage.toLowerCase().contains("search web") ||
        userMessage.toLowerCase().contains("latest") ||
        userMessage.toLowerCase().contains("advisories") ||
        userMessage.toLowerCase().contains("news") ||
        userMessage.toLowerCase().contains("2025")) {
      newsResults = await performBraveNewsSearch(userMessage);
      webResults = await performBraveWebSearch(userMessage);

      contextMessages.add({
        "role": "user",
        "content":
            "Here are recent news results:\n$newsResults\n\nAnd here are web results:\n$webResults\n\nPlease summarize both clearly and friendly for the user.",
      });
    }

    final response = await callJourneyCraftBuddy(contextMessages);

    if (!mounted) return;
    setState(() {
      messages.add({'role': 'assistant', 'content': response});
      _isLoading = false;
    });

    await saveMessageToDB(user.id, 'assistant', response);
  }

  Future<void> saveMessageToDB(
    String userId,
    String role,
    String content,
  ) async {
    await _supabase.from('chat_messages').insert({
      'user_id': userId,
      'role': role,
      'content': content,
      'thread_id': currentThreadId,
    });
  }

  Future<String> performBraveNewsSearch(String query) async {
    final apiKey = dotenv.env['BRAVE_API_KEY'];
    if (apiKey == null) {
      debugPrint("Brave API key not found in .env");
      return "No Brave API key configured for news.";
    }

    final url =
        "https://api.search.brave.com/res/v1/news/search?q=${Uri.encodeComponent(query)}&count=5&search_lang=en";

    final res = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'X-Subscription-Token': apiKey},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['news'] == null || data['news']['results'] == null) {
        return "No news results found.";
      }
      final results = data['news']['results'] as List?;
      if (results != null && results.isNotEmpty) {
        final summaries = results
            .take(3)
            .map(
              (item) =>
                  "- ${item['title']} (${item['url']}): ${item['description']}",
            )
            .join("\n");
        return summaries;
      } else {
        return "No news results found.";
      }
    } else {
      debugPrint("Brave News error: ${res.body}");
      return "Failed to retrieve news results.";
    }
  }

  Future<String> performBraveWebSearch(String query) async {
    final apiKey = dotenv.env['BRAVE_API_KEY'];
    if (apiKey == null) {
      debugPrint("Brave API key not found in .env");
      return "No Brave API key configured for web.";
    }

    final url =
        "https://api.search.brave.com/res/v1/web/search?q=${Uri.encodeComponent(query)}&count=5";

    final res = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'X-Subscription-Token': apiKey},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['web'] == null || data['web']['results'] == null) {
        return "No web results found.";
      }
      final results = data['web']['results'] as List?;
      if (results != null && results.isNotEmpty) {
        final summaries = results
            .take(3)
            .map(
              (item) =>
                  "- ${item['title']} (${item['url']}): ${item['description']}",
            )
            .join("\n");
        return summaries;
      } else {
        return "No web results found.";
      }
    } else {
      debugPrint("Brave Web error: ${res.body}");
      return "Failed to retrieve web results.";
    }
  }

  Future<String> callJourneyCraftBuddy(
    List<Map<String, String>> history,
  ) async {
    const apiUrl = "https://api.openai.com/v1/chat/completions";
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey == null) {
      debugPrint("OpenAI API key not found in .env");
      return "OpenAI API key not configured.";
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      "model": "gpt-4o",
      "messages": [
        {
          "role": "system",
          "content":
              "You are JourneyCraft Buddy, a friendly and supportive travel assistant. User prefers country: $preferredCountry, budget: $travelBudget, currency: $preferredCurrency. Answer travel-related questions only.",
        },
        ...history,
      ],
    });

    final res = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: body,
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final assistantReply = decoded['choices'][0]['message']['content'];
      return assistantReply;
    } else {
      debugPrint("Error from OpenAI: ${res.body}");
      return "Sorry, I couldn't process your request.";
    }
  }

  Future<void> startNewChat() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('chat_messages').delete().eq('user_id', user.id);

    final newThreadResp = await _supabase.rpc('gen_random_uuid').single();
    setState(() {
      currentThreadId = newThreadResp['gen_random_uuid'].toString();
      messages.clear();
    });
  }

  Future<void> onOpenLink(LinkableElement link) async {
    if (await canLaunchUrl(Uri.parse(link.url))) {
      await launchUrl(Uri.parse(link.url));
    } else {
      throw 'Could not launch ${link.url}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Travel Chat", style: GoogleFonts.poppins()),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Chat History',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.chatHistory);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Start New Chat',
            onPressed: () async {
              await startNewChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New chat started!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isUser
                              ? Colors.purple.shade100
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Linkify(
                      text: msg['content'],
                      style: GoogleFonts.poppins(fontSize: 15),
                      onOpen: onOpenLink,
                      options: const LinkifyOptions(humanize: false),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(8), child: TypingDots()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.poppins(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Ask me about your trip...",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurple),
                  onPressed: _isLoading ? null : sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          } else if (index == 1) {
            // Already on chat
          } else if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Map page coming soon!')),
            );
          } else if (index == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Itinerary page coming soon!')),
            );
          } else if (index == 4) {
            Navigator.pushNamed(context, AppRoutes.profile);
          }
        },
      ),
    );
  }
}
