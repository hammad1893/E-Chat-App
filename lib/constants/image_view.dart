// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';

// class FullScreenImageViewer extends StatelessWidget {
//   final String imageUrl;
//   final String heroTag;

//   const FullScreenImageViewer({
//     super.key,
//     required this.imageUrl,
//     required this.heroTag,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(icon: const Icon(Icons.share), onPressed: () {}),
//           IconButton(icon: const Icon(Icons.download), onPressed: () {}),
//         ],
//       ),
//       body: Center(
//         child: Hero(
//           tag: heroTag,
//           child: InteractiveViewer(
//             panEnabled: true,
//             boundaryMargin: const EdgeInsets.all(20),
//             minScale: 0.5,
//             maxScale: 4.0,
//             child: CachedNetworkImage(
//               imageUrl: imageUrl,
//               fit: BoxFit.contain,
//               placeholder:
//                   (context, url) => const Center(
//                     child: CircularProgressIndicator(color: Colors.white),
//                   ),
//               errorWidget:
//                   (context, url, error) => const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.broken_image, color: Colors.white, size: 64),
//                         SizedBox(height: 16),
//                         Text(
//                           'Failed to load image',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ],
//                     ),
//                   ),
//               memCacheWidth: 1000,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class FullScreenVideoViewer extends StatefulWidget {
//   final String videoUrl;
//   const FullScreenVideoViewer({super.key, required this.videoUrl});

//   @override
//   State<FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
// }

// class _FullScreenVideoViewerState extends State<FullScreenVideoViewer> {
//   late VideoPlayerController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.play();
//       });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: _controller.value.isInitialized
//             ? AspectRatio(
//                 aspectRatio: _controller.value.aspectRatio,
//                 child: VideoPlayer(_controller),
//               )
//             : const CircularProgressIndicator(),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() {
//             _controller.value.isPlaying
//                 ? _controller.pause()
//                 : _controller.play();
//           });
//         },
//         child: Icon(
//           _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//         ),
//       ),
//     );
//   }
// }

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final String mediaUrl;
  final String heroTag;

  const FullScreenMediaViewer({
    super.key,
    required this.mediaUrl,
    required this.heroTag,
  });

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _detectMediaTypeAndInitialize();
  }

  void _detectMediaTypeAndInitialize() async {
    final url = widget.mediaUrl.toLowerCase();
    if (url.endsWith(".mp4") ||
        url.endsWith(".mov") ||
        url.endsWith(".mkv") ||
        url.endsWith(".webm")) {
      // ✅ It's a video
      _isVideo = true;
      _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.mediaUrl),
        )
        ..initialize().then((_) {
          setState(() {
            _isLoading = false;
          });
          _videoController!.play();
        });
    } else {
      // ✅ It's an image
      _isVideo = false;
      _isLoading = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ],
      ),
      body: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : _isVideo
                ? _buildVideoPlayer()
                : _buildImageViewer(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (_videoController!.value.isPlaying) {
                _videoController!.pause();
              } else {
                _videoController!.play();
              }
            });
          },
          child: AnimatedOpacity(
            opacity: _videoController!.value.isPlaying ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 80),
          ),
        ),
      ],
    );
  }

  Widget _buildImageViewer() {
    return Hero(
      tag: widget.heroTag,
      child: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 4.0,
        child: CachedNetworkImage(
          imageUrl: widget.mediaUrl,
          fit: BoxFit.contain,
          placeholder:
              (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          errorWidget:
              (context, url, error) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
          memCacheWidth: 1000,
        ),
      ),
    );
  }
}
