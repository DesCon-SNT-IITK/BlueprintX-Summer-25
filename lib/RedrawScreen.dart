import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class RedrawScreen extends StatefulWidget {
  final File originalImage;
  const RedrawScreen({required this.originalImage, super.key});

  @override
  State<RedrawScreen> createState() => _RedrawScreenState();
}

class _RedrawScreenState extends State<RedrawScreen> {
  File? redrawnImage;
  bool loading = false;
  String? errorMessage;

  img.Image _applyBinaryInverseThreshold(img.Image image, int threshold) {
    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = pixel.luminance.round();
        final newValue = luminance < threshold ? 255 : 0;
        result.setPixel(x, y, img.ColorInt8.rgb(newValue, newValue, newValue));
      }
    }
    return result;
  }

  Future<File> _processImage(File file) async {
    debugPrint('Processing image: ${file.path}');
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      final height = image.height;
      final width = image.width;
      final scaleFactor = (height > width ? height : width) / 500;
      final newWidth = (width / scaleFactor).round();
      final newHeight = (height / scaleFactor).round();
      image = img.copyResize(image, width: newWidth, height: newHeight, interpolation: img.Interpolation.average);

      image = img.grayscale(image);
      image = _applyBinaryInverseThreshold(image, 150);
      image = img.sobel(image);
      image = img.colorOffset(image, red: -50, green: -50, blue: 100);

      final dir = await getTemporaryDirectory();
      final newFile = File(p.join(dir.path, 'redrawn_${DateTime.now().millisecondsSinceEpoch}.png'));
      await newFile.writeAsBytes(img.encodePng(image));
      debugPrint('Processed image saved: ${newFile.path}');
      return newFile;
    } catch (e) {
      debugPrint('Processing error: $e');
      throw Exception('Image processing failed: $e');
    }
  }

  Future<void> _redrawImage() async {
    debugPrint('Starting _redrawImage');
    if (!mounted) return;
    setState(() {
      loading = true;
      errorMessage = null;
    });

    Timer? timer;
    try {
      if (!widget.originalImage.existsSync()) {
        throw Exception('Original image not found');
      }

      timer = Timer(const Duration(seconds: 30), () {
        if (loading && mounted) {
          debugPrint('Fallback timer triggered');
          setState(() {
            loading = false;
            errorMessage = 'Image processing timed out';
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image processing timed out')),
            );
          });
        }
      });

      final processedImage = await _processImage(widget.originalImage);
      if (mounted) {
        setState(() {
          redrawnImage = processedImage;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = 'Error: $e';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        });
      }
    } finally {
      timer?.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redrawImage();
    });
  }

  @override
  void dispose() {
    debugPrint('Disposing RedrawScreen');
    try {
      redrawnImage?.deleteSync();
    } catch (e) {
      debugPrint('Error deleting redrawn image: $e');
    }
    super.dispose();
  }

  Widget _buildImageCard(String title, File imageFile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(imageFile, fit: BoxFit.contain, width: double.infinity, cacheWidth: 800, errorBuilder: (context, error, stackTrace) => const Text('Failed to load image')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        try {
          redrawnImage?.deleteSync();
        } catch (e) {
          debugPrint('Error deleting redrawn image on back: $e');
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Blueprint Result', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.teal,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              try {
                redrawnImage?.deleteSync();
              } catch (e) {
                debugPrint('Error deleting redrawn image on back press: $e');
              }
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: loading
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text('Processing image...'),
              ],
            ),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                  ),
                _buildImageCard('Original Image', widget.originalImage),
                if (redrawnImage != null) _buildImageCard('Redrawn Output', redrawnImage!) else const Text('No result received.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                if (redrawnImage != null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Share.shareXFiles([XFile(redrawnImage!.path)], text: 'Here is the redrawn blueprint!');
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share Blueprint'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                if (errorMessage != null)
                  ElevatedButton(
                    onPressed: _redrawImage,
                    child: const Text('Retry'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}