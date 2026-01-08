import 'dart:io';

import 'package:chat_app/view/constants/image_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/view/constants/text.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class Groupmediascreen extends StatefulWidget {
  final String groupchatId;
  final String groupName;
  final List<Map<String, dynamic>> mediaMessages;
  final List<Map<String, dynamic>> linkMessages;
  final List<Map<String, dynamic>> documentMessages;

  const Groupmediascreen({
    super.key,
    required this.groupchatId,
    required this.groupName,
    required this.mediaMessages,
    required this.linkMessages,
    required this.documentMessages,
  });

  @override
  State<Groupmediascreen> createState() => _GroupmediascreenState();
}

class _GroupmediascreenState extends State<Groupmediascreen> {
  String _extractFileName(String? url) {
    if (url == null || url.isEmpty) return 'Unknown file';
    final uri = Uri.parse(url);
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'Unknown file';
  }

  Future<void> _openFile(String fileUrl) async {
    try {
      if (fileUrl.isEmpty) return;

      // Download file to temp dir for opening
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(fileUrl));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);

      final tempDir = await getTemporaryDirectory();
      final fileName = _extractFileName(fileUrl);
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await OpenFilex.open(file.path); // ✅ Opens with system app
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open file: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
            widget.groupName,
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
                            builder:
                                (context) => FullScreenMediaViewer(
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
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
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

            // Links Tab
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
                    return Card(
                      color: const Color(0xff3e3e3e),
                      child: ListTile(
                        leading: Icon(Icons.link, color: Colors.white),
                        title: Text(
                          link['text'] ?? 'Link',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Tap to open',
                          style: TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(Icons.open_in_new, color: Colors.white),
                        onTap: () {
                          // Handle link tap
                        },
                      ),
                    );
                  },
                ),

            // Documents Tab
            // 📄 Documents Tab
            widget.documentMessages.isEmpty
                ? const Center(
                  child: Text(
                    'No documents shared yet',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: widget.documentMessages.length,
                  itemBuilder: (context, index) {
                    final doc = widget.documentMessages[index];
                    final String fileName = _extractFileName(doc['mediaUrl']);
                    final String fileUrl = doc['mediaUrl'] ?? '';
                    final String fileExt =
                        fileName.split('.').last.toLowerCase();

                    IconData icon;
                    if (['pdf'].contains(fileExt)) {
                      icon = Icons.picture_as_pdf;
                    } else if (['doc', 'docx'].contains(fileExt)) {
                      icon = Icons.description;
                    } else if (['jpg', 'jpeg', 'png'].contains(fileExt)) {
                      icon = Icons.image;
                    } else if (['mp4', 'mov', 'mkv'].contains(fileExt)) {
                      icon = Icons.video_file;
                    } else {
                      icon = Icons.insert_drive_file;
                    }

                    return Card(
                      color: const Color(0xff3e3e3e),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.blueGrey.shade700,
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: const Text(
                          'Tap to open with system app',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.open_in_new,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            await _openFile(fileUrl);
                          },
                        ),
                        onTap: () async {
                          await _openFile(fileUrl);
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
