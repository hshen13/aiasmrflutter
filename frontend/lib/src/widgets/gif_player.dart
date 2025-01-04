import 'package:flutter/material.dart';
import '../config/env_config.dart';

class GifPlayer extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Widget Function(BuildContext, dynamic, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const GifPlayer({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.loadingBuilder,
  });

  String _getFullUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    
    // Add base URL if it's a relative path
    final baseUrl = EnvConfig.staticBaseUrl;
    debugPrint('GifPlayer - Base URL: $baseUrl');
    debugPrint('GifPlayer - Input URL: $url');
    
    // Always treat GIF URLs as relative paths under /static/gif/
    final fullUrl = url.startsWith('/static/gif/') 
        ? '$baseUrl$url'
        : '$baseUrl/static/gif/${url.split('/').last}';
    
    debugPrint('GifPlayer - Full URL: $fullUrl');
    return fullUrl;
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        color: Colors.grey[800],
        child: const Icon(
          Icons.music_note,
          color: Colors.white54,
          size: 64,
        ),
      );
    }

    final fullUrl = _getFullUrl(url);
    debugPrint('GifPlayer - Using URL: $fullUrl');

    return Image.network(
      fullUrl,
      fit: fit,
      headers: const {
        'Accept': 'image/gif',
        'Cache-Control': 'no-store',
        'Pragma': 'no-cache',
      },
      loadingBuilder: loadingBuilder ??
          (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[800],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('GifPlayer - Error loading GIF: $error');
        debugPrint('GifPlayer - URL: $fullUrl');
        debugPrint('GifPlayer - Stack trace: $stackTrace');
        if (errorBuilder != null) {
          return errorBuilder!(context, error, stackTrace);
        }
        return Container(
          color: Colors.grey[800],
          child: const Icon(
            Icons.music_note,
            color: Colors.white54,
            size: 64,
          ),
        );
      },
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      cacheWidth: 300,
      cacheHeight: 300,
    );
  }
}
