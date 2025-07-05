import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/navigation/AppRoutes.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> threads = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    loadThreads();
  }

  Future<void> loadThreads() async {
    setState(() {
      _loading = true;
    });

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Fetch distinct thread IDs
    final data = await _supabase
        .from('chat_messages')
        .select('thread_id, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    // Group by thread_id (filter duplicates)
    final threadSet = <String, String>{};
    for (var row in data) {
      threadSet[row['thread_id']] = row['created_at'];
    }

    setState(() {
      threads =
          threadSet.entries
              .map(
                (entry) => {'thread_id': entry.key, 'created_at': entry.value},
              )
              .toList();
      _loading = false;
    });
  }

  Future<void> deleteThread(String threadId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('chat_messages')
        .delete()
        .eq('user_id', user.id)
        .eq('thread_id', threadId);

    // Refresh UI
    loadThreads();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Chat deleted successfully.")));
  }

  Future<void> reloadThread(String threadId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Fetch all messages for this thread
    final messages = await _supabase
        .from('chat_messages')
        .select()
        .eq('user_id', user.id)
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);

    if (messages.isNotEmpty) {
      // Store messages locally or pass as argument to ChatPage
      // You can pass via Navigator, or save to a provider or local storage

      Navigator.pushNamed(
        context,
        AppRoutes.chat,
        arguments: {'thread_id': threadId, 'messages': messages},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No messages found in this thread.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat History", style: GoogleFonts.poppins()),
        backgroundColor: Colors.purple,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : threads.isEmpty
              ? Center(
                child: Text(
                  "No chat history found.",
                  style: GoogleFonts.poppins(),
                ),
              )
              : ListView.builder(
                itemCount: threads.length,
                itemBuilder: (context, index) {
                  final thread = threads[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(
                        "Thread ID: ${thread['thread_id']}",
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      subtitle: Text(
                        "Started at: ${thread['created_at']}",
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            deleteThread(thread['thread_id']);
                          } else if (value == 'reload') {
                            reloadThread(thread['thread_id']);
                          }
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'reload',
                                child: Text("Reload"),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text("Delete"),
                              ),
                            ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
