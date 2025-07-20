import 'dart:async';
import 'dart:io';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'package:connectivity_plus/connectivity_plus.dart';

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
  CancelableOperation? _requestOperation;

  Future<File> _downscaleImage(File file) async {
    debugPrint('Downscaling image: ${file.path}');
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      debugPrint('Image decoding failed, returning original file');
      return file;
    }
    final resized = img.copyResize(image, width: 800);
    final dir = await getTemporaryDirectory();
    final newFile = File(p.join(dir.path, 'resized_${p.basename(file.path)}'));
    await newFile.writeAsBytes(img.encodePng(resized));
    debugPrint('Downscaled image saved: ${newFile.path}');
    return newFile;
  }

  Future<bool> _checkNetwork() async {
    debugPrint('Checking network connectivity');
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult != ConnectivityResult.none;
    debugPrint('Network connected: $isConnected');
    return isConnected;
  }

  Future<void> _sendToServer() async {
    debugPrint('Starting _sendToServer');
    setState(() {
      loading = true;
      errorMessage = null;
    });

    // Fallback timer
    final timer = Timer(const Duration(seconds: 60), () {
      if (loading && mounted) {
        debugPrint('Fallback timer triggered');
        _requestOperation?.cancel();
        setState(() {
          loading = false;
          errorMessage = 'Operation timed out';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Operation timed out')),
          );
        });
      }
    });

    try {
      // Check network
      if (!await _checkNetwork()) {
        throw SocketException('No network connection');
      }

      // Validate image
      debugPrint('Checking if image exists: ${widget.originalImage.path}');
      if (!widget.originalImage.existsSync()) {
        throw Exception('Original image not found');
      }

      // Prepare request
      final uri = Uri.parse('http://172.23.148.71:8000/redraw');
      debugPrint('Sending request to $uri');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        (await _downscaleImage(widget.originalImage)).path,
      ));

      // Send request with cancelable operation
      _requestOperation = CancelableOperation.fromFuture(
        request.send().timeout(const Duration(seconds: 30)),
      );
      final response = await _requestOperation!.value;

      debugPrint('Received response: ${response.statusCode}');
      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('image') ?? false) {
          debugPrint('Processing response bytes');
          final bytes = await response.stream.toBytes();
          final dir = await getTemporaryDirectory();
          final file = File(p.join(dir.path, 'redrawn_${DateTime.now().millisecondsSinceEpoch}.png'));
          await file.writeAsBytes(bytes);
          debugPrint('Saved redrawn image: ${file.path}');
          if (mounted) {
            setState(() {
              redrawnImage = file;
              loading = false;
            });
          }
        } else {
          throw Exception('Invalid response: not an image');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException: $e');
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = 'Network error: Failed to connect to server';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Network error: Failed to connect to server')),
          );
        });
      }
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException: $e');
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = 'Request timed out';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request timed out')),
          );
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
      timer.cancel();
      _requestOperation = null;
      if (mounted && loading) {
        debugPrint('Setting loading to false in finally');
        setState(() => loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Calling _sendToServer');
      _sendToServer();
    });
  }

  @override
  void dispose() {
    debugPrint('Disposing RedrawScreen');
    _requestOperation?.cancel();
    redrawnImage?.deleteSync();
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
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              semanticsLabel: title,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
                width: double.infinity,
                cacheWidth: 800,
                errorBuilder: (context, error, stackTrace) => const Text('Failed to load image'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blueprint Result'),
        backgroundColor: Colors.blueAccent,
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
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                    semanticsLabel: errorMessage,
                  ),
                ),
              _buildImageCard('Original Image', widget.originalImage),
              if (redrawnImage != null)
                _buildImageCard('Redrawn Output', redrawnImage!)
              else
                const Text(
                  'No result received.',
                  style: TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 20),
              if (redrawnImage != null)
                ElevatedButton.icon(
                  onPressed: () async {
                    await Share.shareXFiles(
                      [XFile(redrawnImage!.path)],
                      text: 'Here is the redrawn blueprint!',
                    );
                  },
                  icon: const Icon(Icons.share, semanticLabel: 'Share'),
                  label: const Text('Share Blueprint'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              if (errorMessage != null)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      errorMessage = null;
                      _sendToServer();
                    });
                  },
                  child: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}