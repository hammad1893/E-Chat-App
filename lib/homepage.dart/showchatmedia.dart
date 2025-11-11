import 'dart:io';
import 'package:chat_app/constants/image_view.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/constants/text.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatDetailsPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String contactName;
  final List<Map<String, dynamic>> mediaMessages;
  final List<Map<String, dynamic>> linkMessages;
  final List<Map<String, dynamic>> documentMessages;

  const ChatDetailsPage({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.contactName,
    required this.mediaMessages,
    required this.linkMessages,
    required this.documentMessages,
  });

  @override
  State<ChatDetailsPage> createState() => _ChatDetailsPageState();
}

class _ChatDetailsPageState extends State<ChatDetailsPage> {
  // URL Launcher function
  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $urlString'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Extract URL from message text
  String? _extractUrl(String text) {
    final urlRegex = RegExp(
      r'https?://(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }

  // Extract display URL for better UI
  String _extractDisplayUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.host}${uri.path.isNotEmpty ? uri.path : ''}';
    } catch (e) {
      return url.length > 40 ? '${url.substring(0, 40)}...' : url;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xff292929),
        appBar: AppBar(
          backgroundColor: const Color(0xff292929),
          elevation: 0,
          title: Text(
            widget.contactName,
            style: Apptexts.titlestyle.copyWith(color: Colors.white),
          ),
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xff3e3e3e),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xff3e3e3e),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/images/video.png",
                height: size.height * .06,
                width: size.width * .12,
                color: Colors.white,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xff3e3e3e),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.call_outlined, color: Colors.white),
              ),
            ),
          ],
          bottom: TabBar(
            dividerColor: Colors.white,
            tabs: [
              Tab(text: 'Media (${widget.mediaMessages.length})'),
              Tab(text: 'Links (${widget.linkMessages.length})'),
              Tab(text: 'Docs (${widget.documentMessages.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Media Tab
            widget.mediaMessages.isEmpty
                ? Center(
                    child: Text(
                      'No media shared yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: widget.mediaMessages.length,
                    itemBuilder: (context, index) {
                      final media = widget.mediaMessages[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenMediaViewer(
                                mediaUrl: media['mediaUrl'],
                                heroTag: media['mediaUrl'],
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Hero(
                            tag: media['mediaUrl'] ?? '',
                            child: Image.network(
                              media['mediaUrl'] ?? '',
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: Icon(Icons.error, color: Colors.white),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),

            // Links Tab - UPDATED WITH URL LAUNCHING
            widget.linkMessages.isEmpty
                ? Center(
                    child: Text(
                      'No links shared yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: widget.linkMessages.length,
                    itemBuilder: (context, index) {
                      final link = widget.linkMessages[index];
                      final messageText = link['text'] ?? '';
                      final url = _extractUrl(messageText);
                      final displayUrl = url != null ? _extractDisplayUrl(url) : 'Invalid URL';

                      return Card(
                        color: const Color(0xff3e3e3e),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.link,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            displayUrl,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                messageText.length > 50 
                                    ? '${messageText.substring(0, 50)}...' 
                                    : messageText,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap to open in browser',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.open_in_new,
                            color: Colors.white,
                          ),
                          onTap: url != null 
                              ? () => _launchUrl(url)
                              : null,
                        ),
                      );
                    },
                  ),

            // Documents Tab
            widget.documentMessages.isEmpty
                ? const Center(
                    child: Text(
                      'No documents shared yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.documentMessages.length,
                    itemBuilder: (context, index) {
                      final doc = widget.documentMessages[index];
                      final String fileName = doc['text'] ?? 'Document';
                      final String fileUrl = doc['mediaUrl'] ?? '';

                      return Card(
                        color: const Color(0xff3e3e3e),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.insert_drive_file,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Tap to open file',
                            style: TextStyle(color: Colors.grey),
                          ),
                          trailing: const Icon(
                            Icons.open_in_new,
                            color: Colors.white,
                          ),
                          onTap: () async {
                            try {
                              // If it's a network file (Firebase or any URL)
                              if (fileUrl.startsWith('http')) {
                                // Download temporarily to open it
                                final tempDir = await getTemporaryDirectory();
                                final filePath =
                                    '${tempDir.path}/${fileName.split('/').last}';
                                final response = await http.get(
                                  Uri.parse(fileUrl),
                                );
                                final file = File(filePath);
                                await file.writeAsBytes(response.bodyBytes);

                                await OpenFilex.open(file.path);
                              } else {
                                // Local file
                                await OpenFilex.open(fileUrl);
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error opening file: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}